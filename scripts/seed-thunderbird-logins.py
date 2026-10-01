#!/usr/bin/env python3
"""Seed a Thunderbird profile's logins.json with NSS-encrypted mail credentials.

Thunderbird keeps mail passwords in ``logins.json``, encrypted with the NSS
"SDR" key that lives in the profile's ``key4.db``. There is no supported way to
declare those from Nix, so this script does what Thunderbird itself would do:
it opens (creating if absent) the profile's NSS databases, encrypts the
credentials with ``PK11SDR_Encrypt``, and writes the resulting entries.

Lookup keys match ``MsgIncomingServer._getServerURI()`` and
``SmtpServer._getServerURISpec()`` in Thunderbird, both of which search the
login manager with ``{origin: <uri>, httpRealm: <uri>}`` where ``<uri>`` is
``<protocol>://<hostname>`` with no username and no port.

Entries for origins we are not managing are left untouched, so passwords added
through the Thunderbird UI survive. The profile is only rewritten when a
credential actually changed, which keeps Home Manager activation quiet.
"""

import argparse
import base64
import ctypes
import json
import os
import stat
import sys
import time
import uuid

SI_BUFFER = 0
SECSuccess = 0


class SECItem(ctypes.Structure):
    """NSS's length-prefixed byte buffer."""

    _fields_ = [
        ("type", ctypes.c_uint),
        ("data", ctypes.POINTER(ctypes.c_ubyte)),
        ("len", ctypes.c_uint),
    ]

    def raw(self):
        if not self.data or not self.len:
            return b""
        return bytes(
            memoryview(
                ctypes.cast(self.data, ctypes.POINTER(ctypes.c_ubyte * self.len)).contents
            )
        )


def load_nss(libdir):
    """Load libnss3 and declare the handful of entry points we need."""
    path = os.path.join(libdir, "libnss3.so") if libdir else "libnss3.so"
    nss = ctypes.CDLL(path)
    nss.NSS_InitReadWrite.argtypes = [ctypes.c_char_p]
    nss.NSS_InitReadWrite.restype = ctypes.c_int
    nss.NSS_Shutdown.restype = ctypes.c_int
    nss.PK11_GetInternalKeySlot.restype = ctypes.c_void_p
    nss.PK11_FreeSlot.argtypes = [ctypes.c_void_p]
    nss.PK11_NeedUserInit.argtypes = [ctypes.c_void_p]
    nss.PK11_NeedUserInit.restype = ctypes.c_int
    nss.PK11_InitPin.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
    nss.PK11_InitPin.restype = ctypes.c_int
    nss.PK11_Authenticate.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
    nss.PK11_Authenticate.restype = ctypes.c_int
    nss.PK11SDR_Encrypt.argtypes = [
        ctypes.POINTER(SECItem),
        ctypes.POINTER(SECItem),
        ctypes.POINTER(SECItem),
        ctypes.c_void_p,
    ]
    nss.PK11SDR_Encrypt.restype = ctypes.c_int
    nss.PK11SDR_Decrypt.argtypes = [
        ctypes.POINTER(SECItem),
        ctypes.POINTER(SECItem),
        ctypes.c_void_p,
    ]
    nss.PK11SDR_Decrypt.restype = ctypes.c_int
    nss.SECITEM_ZfreeItem.argtypes = [ctypes.POINTER(SECItem), ctypes.c_int]
    nss.PR_GetError.restype = ctypes.c_int
    nss.PR_ErrorToName.argtypes = [ctypes.c_int]
    nss.PR_ErrorToName.restype = ctypes.c_char_p
    return nss


def nss_err(nss):
    code = nss.PR_GetError()
    name = nss.PR_ErrorToName(code)
    return "%s (%d)" % (name.decode() if name else "unknown", code)


def mkitem(data):
    """Wrap bytes in a SECItem. The returned buffer must stay referenced."""
    buf = (ctypes.c_ubyte * len(data)).from_buffer_copy(data)
    item = SECItem(SI_BUFFER, ctypes.cast(buf, ctypes.POINTER(ctypes.c_ubyte)), len(data))
    return item, buf


def die(message):
    sys.exit("seed-thunderbird-logins: " + message)


class Sdr:
    """PK11SDR encrypt/decrypt bound to one open NSS profile."""

    def __init__(self, nss):
        self._nss = nss

    def encrypt(self, text):
        nss = self._nss
        keyid = SECItem(SI_BUFFER, None, 0)
        data, _keep = mkitem(text.encode("utf-8"))
        out = SECItem(SI_BUFFER, None, 0)
        rv = nss.PK11SDR_Encrypt(
            ctypes.byref(keyid), ctypes.byref(data), ctypes.byref(out), None
        )
        if rv != SECSuccess:
            die("PK11SDR_Encrypt failed: " + nss_err(nss))
        blob = out.raw()
        nss.SECITEM_ZfreeItem(ctypes.byref(out), 0)
        return base64.b64encode(blob).decode("ascii")

    def decrypt(self, b64):
        """Return the plaintext, or None if the blob cannot be read."""
        nss = self._nss
        try:
            raw = base64.b64decode(b64)
        except Exception:
            return None
        data, _keep = mkitem(raw)
        out = SECItem(SI_BUFFER, None, 0)
        rv = nss.PK11SDR_Decrypt(ctypes.byref(data), ctypes.byref(out), None)
        if rv != SECSuccess:
            return None
        value = out.raw()
        nss.SECITEM_ZfreeItem(ctypes.byref(out), 0)
        try:
            return value.decode("utf-8")
        except UnicodeDecodeError:
            return None


def read_store(path):
    """Load logins.json, tolerating absence but not corruption."""
    if not os.path.exists(path):
        return {
            "nextId": 1,
            "logins": [],
            "potentiallyVulnerablePasswords": [],
            "dismissedBreachAlertsByLoginGUID": {},
            "version": 3,
        }
    with open(path, "r") as handle:
        store = json.load(handle)
    store.setdefault("logins", [])
    store.setdefault("potentiallyVulnerablePasswords", [])
    store.setdefault("dismissedBreachAlertsByLoginGUID", {})
    store.setdefault("version", 3)
    store.setdefault("nextId", max((e.get("id", 0) for e in store["logins"]), default=0) + 1)
    return store


def thunderbird_running(profile):
    """True if a live Thunderbird holds this profile's lock."""
    lock = os.path.join(profile, "lock")
    if os.path.islink(lock):
        # Firefox/Thunderbird point this at "<ip>:+<pid>".
        target = os.readlink(lock)
        pid = target.rsplit("+", 1)[-1]
        if pid.isdigit():
            return os.path.exists("/proc/%s" % pid)
        return True
    return False


def main():
    parser = argparse.ArgumentParser(
        description="Seed a Thunderbird profile with NSS-encrypted mail credentials."
    )
    parser.add_argument("--profile", required=True, help="Thunderbird profile directory")
    parser.add_argument(
        "--nss-libdir",
        default=os.environ.get("SEED_THUNDERBIRD_NSS_LIBDIR", ""),
        help="Directory containing libnss3.so (defaults to $SEED_THUNDERBIRD_NSS_LIBDIR)",
    )
    parser.add_argument("--username", required=True, help="Username Thunderbird logs in with")
    parser.add_argument(
        "--password-file", required=True, help="File holding the password (trailing newline ignored)"
    )
    parser.add_argument(
        "--origin",
        action="append",
        default=[],
        metavar="URI",
        help="Server URI such as imap://host or smtp://host. Repeatable.",
    )
    args = parser.parse_args()

    if not args.origin:
        die("no --origin given, nothing to seed")

    try:
        with open(args.password_file, "rb") as handle:
            password = handle.read()
    except OSError as err:
        die("cannot read password file %s: %s" % (args.password_file, err))
    # Only strip the trailing newline; a password may legitimately end in spaces.
    password = password.rstrip(b"\r\n").decode("utf-8")
    if not password:
        die("password file %s is empty" % args.password_file)

    profile = os.path.abspath(args.profile)
    os.makedirs(profile, mode=0o700, exist_ok=True)

    if thunderbird_running(profile):
        print(
            "seed-thunderbird-logins: Thunderbird is running on %s; it would overwrite "
            "logins.json, so skipping. Restart Thunderbird to pick up credentials." % profile,
            file=sys.stderr,
        )
        return

    store_path = os.path.join(profile, "logins.json")
    store = read_store(store_path)

    nss = load_nss(args.nss_libdir)
    # The "sql:" prefix selects the cert9.db/key4.db pair that Thunderbird uses;
    # without it NSS would fall back to the legacy key3.db format.
    if nss.NSS_InitReadWrite(("sql:" + profile).encode()) != SECSuccess:
        die("NSS_InitReadWrite(%s) failed: %s" % (profile, nss_err(nss)))

    changed = 0
    try:
        slot = nss.PK11_GetInternalKeySlot()
        if not slot:
            die("PK11_GetInternalKeySlot failed: " + nss_err(nss))
        try:
            # A freshly created key4.db has no PIN; set the empty one that
            # Thunderbird uses when no primary password is configured.
            if nss.PK11_NeedUserInit(slot):
                if nss.PK11_InitPin(slot, None, b"") != SECSuccess:
                    die("PK11_InitPin failed: " + nss_err(nss))
            if nss.PK11_Authenticate(slot, 1, None) != SECSuccess:
                die(
                    "PK11_Authenticate failed: %s\n"
                    "  A primary password on this profile causes this. Declarative "
                    "seeding requires it to be unset." % nss_err(nss)
                )

            sdr = Sdr(nss)
            for origin in args.origin:
                existing = next(
                    (
                        entry
                        for entry in store["logins"]
                        if entry.get("hostname") == origin
                        and sdr.decrypt(entry.get("encryptedUsername", "")) == args.username
                    ),
                    None,
                )
                if existing is not None and sdr.decrypt(
                    existing.get("encryptedPassword", "")
                ) == password:
                    continue  # Already correct; leave the entry (and its stats) alone.

                encrypted_username = sdr.encrypt(args.username)
                encrypted_password = sdr.encrypt(password)
                # Never write a blob we cannot read back.
                if (
                    sdr.decrypt(encrypted_username) != args.username
                    or sdr.decrypt(encrypted_password) != password
                ):
                    die("NSS round-trip verification failed for %s" % origin)

                now = int(time.time() * 1000)
                if existing is not None:
                    existing.update(
                        {
                            "encryptedUsername": encrypted_username,
                            "encryptedPassword": encrypted_password,
                            "timePasswordChanged": now,
                        }
                    )
                else:
                    store["logins"].append(
                        {
                            "id": store["nextId"],
                            "hostname": origin,
                            "httpRealm": origin,
                            "formSubmitURL": None,
                            "usernameField": "",
                            "passwordField": "",
                            "encryptedUsername": encrypted_username,
                            "encryptedPassword": encrypted_password,
                            "guid": "{%s}" % uuid.uuid4(),
                            "encType": 1,
                            "timeCreated": now,
                            "timeLastUsed": now,
                            "timePasswordChanged": now,
                            "timesUsed": 1,
                            "syncCounter": 0,
                            "everSynced": False,
                            "encryptedUnknownFields": None,
                        }
                    )
                    store["nextId"] += 1
                changed += 1
        finally:
            nss.PK11_FreeSlot(slot)
    finally:
        nss.NSS_Shutdown()

    if not changed:
        print("seed-thunderbird-logins: credentials already current in %s" % store_path)
        return

    tmp = store_path + ".hm-new"
    with open(tmp, "w") as handle:
        json.dump(store, handle)
    os.chmod(tmp, stat.S_IRUSR | stat.S_IWUSR)
    os.replace(tmp, store_path)
    print(
        "seed-thunderbird-logins: updated %d credential(s) in %s" % (changed, store_path)
    )


if __name__ == "__main__":
    main()

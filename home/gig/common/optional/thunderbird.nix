# Thunderbird, configured declaratively against Amazon WorkMail.
#
# Everything Thunderbird needs is generated from this file: the account, the
# servers, the identity, and the password. The password cannot be expressed as
# a Nix option because Thunderbird keeps it in an NSS-encrypted logins.json
# inside the profile, so an activation step seeds it from sops instead (see
# scripts/seed-thunderbird-logins.py).
#
# Prerequisite, once per fleet: the WorkMail password must exist in the secrets
# repo under `email/cashconsults`. Add it with `just sops` before the first
# rebuild, otherwise sops-nix fails activation on a missing key:
#
#   email:
#       cashconsults: <the WorkMail password>
#
# Endpoints come from the account's WorkMail region, which is us-east-1 for
# cashconsults.com (its MX is inbound-smtp.us-east-1.amazonaws.com and
# autodiscover.cashconsults.com is a CNAME to autodiscover.mail.us-east-1).
# WorkMail offers implicit TLS only: IMAP on 993 and SMTP on 465. Port 587 is
# not served, so STARTTLS must stay off.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  profileName = "gig";

  region = "us-east-1";
  imapHost = "imap.mail.${region}.awsapps.com";
  smtpHost = "smtp.mail.${region}.awsapps.com";

  address = "maxwell@cashconsults.com";
  realName = "Maxwell Rupp";

  secretName = "email/cashconsults";
  passwordFile = config.sops.secrets.${secretName}.path;

  profilePath = "${config.home.homeDirectory}/.thunderbird/${profileName}";

  # The URIs Thunderbird searches the login manager with. These must match
  # MsgIncomingServer._getServerURI() and SmtpServer._getServerURISpec(), which
  # both use `<protocol>://<hostname>` with no username and no port.
  loginOrigins = [
    "imap://${imapHost}"
    "smtp://${smtpHost}"
  ];

  # WorkMail is Exchange-backed and its IMAP server advertises neither
  # SPECIAL-USE nor NAMESPACE, so Thunderbird cannot discover the special
  # folders on its own. Point it at the names WorkMail actually uses, otherwise
  # Thunderbird invents its own "Sent"/"Trash" and they diverge from webmail.
  folderBase = "imap://${lib.replaceStrings [ "@" ] [ "%40" ] address}@${imapHost}";
  sentFolder = "Sent Items";
  draftsFolder = "Drafts";
  templatesFolder = "Templates";
  trashFolder = "Deleted Items";
  folderUri = name: "${folderBase}/${lib.replaceStrings [ " " ] [ "%20" ] name}";
in
{
  sops.secrets.${secretName} = { };

  accounts.email.accounts.cashconsults = {
    primary = true;
    inherit address realName;
    # WorkMail authenticates with the full email address.
    userName = address;
    flavor = "plain";

    imap = {
      host = imapHost;
      port = 993;
      # tls.enable with useStartTls left at false means implicit TLS, which is
      # what WorkMail serves on 993.
      tls.enable = true;
    };

    smtp = {
      host = smtpHost;
      port = 465;
      tls.enable = true;
    };

    # Not used by Thunderbird (it reads logins.json), but keeps the account
    # usable by any other mail tooling that honours accounts.email.
    passwordCommand = [
      "${pkgs.coreutils}/bin/cat"
      passwordFile
    ];

    folders = {
      inbox = "INBOX";
      sent = sentFolder;
      drafts = draftsFolder;
      trash = trashFolder;
    };

    thunderbird = {
      enable = true;
      profiles = [ profileName ];

      settings = id: {
        # Normal password over TLS; WorkMail advertises AUTH=PLAIN only.
        "mail.server.server_${id}.authMethod" = 3;
        "mail.smtpserver.smtp_${id}.authMethod" = 3;
        "mail.server.server_${id}.trash_folder_name" = trashFolder;
        # Keep mail available offline and check on a sane cadence.
        "mail.server.server_${id}.offline_download" = true;
        "mail.server.server_${id}.check_new_mail" = true;
        "mail.server.server_${id}.check_time" = 5;
        "mail.server.server_${id}.login_at_startup" = true;
      };

      perIdentitySettings = id: {
        # picker_mode 1 means "use the folder named below" rather than letting
        # Thunderbird guess.
        "mail.identity.id_${id}.fcc_folder" = folderUri sentFolder;
        "mail.identity.id_${id}.fcc_folder_picker_mode" = "1";
        "mail.identity.id_${id}.draft_folder" = folderUri draftsFolder;
        "mail.identity.id_${id}.draft_folder_picker_mode" = "1";
        "mail.identity.id_${id}.stationery_folder" = folderUri templatesFolder;
        "mail.identity.id_${id}.stationery_folder_picker_mode" = "1";
      };
    };
  };

  programs.thunderbird = {
    enable = true;

    profiles.${profileName} = {
      isDefault = true;

      settings = {
        # The login manager must be on for the seeded credentials to be read.
        "signon.rememberSignons" = true;
        # Thunderbird 155 ships signon.storage.rust.enabled=false in
        # all-thunderbird.js (overriding Gecko's greprefs.js, which sets it
        # true), so logins.json is the live store. Pin it so a future default
        # flip cannot silently migrate the store out from under the seeder.
        "signon.storage.rust.enabled" = false;

        # Don't nag about being the default client or about the start page.
        "mail.shell.checkDefaultClient" = false;
        "mailnews.start_page.enabled" = false;
      };
    };
  };

  # Thunderbird stores mail passwords in an NSS-encrypted logins.json, which no
  # Nix option can describe. Seed it after sops has placed the secret and after
  # the profile's own files have been linked. The seeder is idempotent: it only
  # rewrites logins.json when a credential actually differs, and it leaves
  # logins for other servers alone.
  home.activation.seedThunderbirdLogins =
    lib.hm.dag.entryAfter
      [
        "writeBoundary"
        "linkGeneration"
        "sops-nix"
      ]
      ''
        if [ -r ${lib.escapeShellArg passwordFile} ]; then
          run ${lib.getExe pkgs.seed-thunderbird-logins} \
            --profile ${lib.escapeShellArg profilePath} \
            --username ${lib.escapeShellArg address} \
            --password-file ${lib.escapeShellArg passwordFile} \
            ${lib.concatMapStringsSep " \\\n        " (o: "--origin ${lib.escapeShellArg o}") loginOrigins}
        else
          warnEcho "thunderbird: ${passwordFile} is not readable yet, skipping credential seeding."
          warnEcho "thunderbird: add '${secretName}' via 'just sops', then re-run 'just home'."
        fi
      '';
}

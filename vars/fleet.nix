# SSH targets for fleet-wide tooling (currently `als stats --fleet`).
#
# Whether a host is *consulted* comes from vars/hosts.nix (`active`); this file
# only records how to reach it. Keeping the two separate means a host going
# offline is a one-line change in hosts.nix, not here.
#
# `remote` is overridable per host. The default assumes nushell is the login
# shell: plain `nu -c` does NOT load config, so aliases would be invisible and
# `als` undefined — the `-l` is mandatory.
{
  merlin = {
    target = "gig@merlins-windows-wsl";
  };
  ganoslal = {
    target = "gig@ganoslal-wsl";
  };
  spacedock = {
    # Host block in home/gig/common/core/ssh.nix supplies hostname + identity.
    target = "spacedock";
  };
  # wsl is intentionally absent: same machine as ganoslal.
}

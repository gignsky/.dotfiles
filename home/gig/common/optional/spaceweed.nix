# spaceweed -- the Spaceweed Inc. coop ledger TUI, always on $PATH.
#
# Built straight from the spaceweed-inc flake input (no need to evaluate the
# whole annex), and wrapped so every session pulls the annex first and then
# commits (--no-verify) + pushes the ledger afterwards. See scripts/spaceweed.sh.
# Pick up a new spaceweed release with `nix flake update spaceweed-inc`.
{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  spaceweed-bin = inputs.spaceweed-inc.packages.${pkgs.stdenv.hostPlatform.system}.default;

  spaceweed = pkgs.writeShellApplication {
    name = "spaceweed";
    runtimeInputs = with pkgs; [
      git
      git-lfs # the annex is LFS-enabled; its pull/push hooks need this
      openssh
      hostname
      coreutils
    ];
    # errexit is off on purpose: the script handles every failure itself so
    # the commit/push step always gets a chance to run.
    bashOptions = [
      "nounset"
      "pipefail"
    ];
    text = ''
      SPACEWEED_BIN=${lib.getExe spaceweed-bin}
      ${builtins.readFile ../../../../scripts/spaceweed.sh}
    '';
  };
in
{
  home.packages = [ spaceweed ];
}

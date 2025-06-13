{ config, lib, pkgs, isWSL ? false, ... }:

let
  extensionIds = import ./vscode-extensions-list.nix;
  extensions = builtins.map (id: pkgs.vscode-extensions.${id}) extensionIds;
  scriptPath = "${config.home.homeDirectory}/.dotfiles/scripts/install-vscode-extensions-wsl.sh";
  wslpathBin = "${pkgs.wslu}/bin";
  curlBin = "${pkgs.curl}/bin";
  wgetBin = "${pkgs.wget}/bin";
  fileBin = "${pkgs.file}/bin";
  jqBin = "${pkgs.jq}/bin";
in
lib.mkMerge [
  (lib.mkIf isWSL {
    home.activation.vscodeExtensionsWSL = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      chmod +x ${scriptPath} || true
      export PATH=${wslpathBin}:${curlBin}:${wgetBin}:${fileBin}:${jqBin}:$PATH
      # echo "[DEBUG] PATH: $PATH"
      # echo "[DEBUG] wslpath: $(command -v wslpath || echo not found)"
      # echo "[DEBUG] curl: $(command -v curl || echo not found)"
      # echo "[DEBUG] wget: $(command -v wget || echo not found)"
      # echo "[DEBUG] file: $(command -v file || echo not found)"
      # echo "[DEBUG] ls wslpathBin: $(ls -l ${wslpathBin})"
      # echo "[DEBUG] ls curlBin: $(ls -l ${curlBin})"
      # echo "[DEBUG] ls wgetBin: $(ls -l ${wgetBin})"
      # echo "[DEBUG] ls fileBin: $(ls -l ${fileBin})"
      # echo "[DEBUG] ls jqBin: $(ls -l ${jqBin})"
      export DEBUG=1
      export SKIP_ALREADY_INSTALLED_SUMMARY=1
      echo '${builtins.toJSON extensionIds}' > /tmp/vscode-extensions.json
      ${scriptPath} /tmp/vscode-extensions.json || true
    '';
  })
  (lib.mkIf (!isWSL) {
    # info at
    # https://nixos.wiki/wiki/Visual_Studio_Code
    ##############################################

    # search extentions at
    # https://search.nixos.org/packages?type=packages&query=vscode-extensions
    ##############################################

    # Home Manager Way
    programs.vscode = {
      enable = false;
      enableExtensionUpdateCheck = true;
      enableUpdateCheck = true;
      mutableExtensionsDir = false; # disallows vscode from installing its own extensions
      userSettings = { };
      extensions = extensions;
    };
    # # A "wonderful CLI to track your time"
    # watson = {
    #     enable = false;
    #     enableZshIntegration = true;
    # };
  })
]

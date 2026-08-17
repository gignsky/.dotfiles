# Tdarr transcode node run-as-a-service container, ported verbatim from
# dot-spacedock. DISABLED by default (not imported by
# containers/services/default.nix).
#
# ⚠️  Before enabling: needs CIFS/samba mounts and /etc/samba/cifs-creds
# (provisioned via sops-nix), and the hardcoded server IP (192.168.51.3).
#
# GPU: spacedock carries a discrete AMD Polaris card (RX 470/480/570/580/590,
{
  inputs,
  system,
  ...
}:
let
  image = inputs.avec-moi.packages.${system}.site;
in
{
  virtualisation.oci-containers.containers.avec-moi-app = {
    inherit image;
    autoStart = true;
    environment = {
      TZ = "America/New_York";
    };
    ports = [
      "8081:8080/tcp"
    ];
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8081 ];
  };
}

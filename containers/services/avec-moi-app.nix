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
  ...
}:
let
  image = inputs.avec-moi.site;
in
{
  virtualisation.oci-containers.containers.avec-moi-app = {
    inherit image;
    autoStart = true;
    environment = {
      TZ = "America/New_York";
    };
    ports = [
      {
        hostPort = "8081";
        containerPort = "8080";
        protocol = "tcp";
      }
    ];
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8081 ];
  };
}

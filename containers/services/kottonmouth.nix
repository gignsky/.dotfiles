{
  inputs,
  pkgs,
  ...
}:
let
  # imageFile = inputs.avec-moi.packages.${pkgs.system}.default;
in
{
  # virtualisation.oci-containers.containers.avec-moi-app = {
  #   inherit imageFile;
  #   image = "avecmoi:latest";
  #   autoStart = true;
  #   environment = {
  #     TZ = "America/New_York";
  #   };
  #   ports = [
  #     "8081:8080/tcp"
  #   ];
  # };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8082 ];
  };
}

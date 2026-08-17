# avec-moi.app — static slide deck served by static-web-server on :8080,
# packaged as an OCI image by the `avec-moi` flake input.
#
# The image comes from `avec-moi.packages.<system>.default` (a
# `dockerTools.buildLayeredImage` tarball tagged `avecmoi:latest`). NOTE:
# `packages.<system>.site` is NOT the image — it is just the raw HTML site
# directory that the image serves. We reference the input by `pkgs.system`
# so the module does not need `system` threaded through `specialArgs`.
{
  inputs,
  pkgs,
  ...
}:
let
  imageFile = inputs.avec-moi.packages.${pkgs.system}.default;
in
{
  virtualisation.oci-containers.containers.avec-moi-app = {
    inherit imageFile;
    image = "avecmoi:latest";
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

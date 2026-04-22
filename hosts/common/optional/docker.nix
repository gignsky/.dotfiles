{ pkgs, ... }:
let
  podmanTLSPair =
    pkgs.runCommand "podman-tls-certs"
      {
        nativeBuildInputs = [ pkgs.openssl ];
        cert = "$out/server-cert.pem";
        key = "$out/server-key.pem";
      }
      ''
            # generate private key
            ${pkgs.openssl}/bin/openssl genrsa -out server-key.pem 2048

            # generate self-signed cert
        ${pkgs.openssl}/bin/openssl req -new -x509 -sha256 \
            -key server-key.pem -out server-cert.pem \
            -days 365 -subj "/CN=spacedock.local"

            mkdir -p $out
            mv server-cert.pem $out/server-cert.pem
            mv server-key.pem $out/server-key.pem
      '';
in
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      # 2375
    ];
  };
  virtualisation = {
    podman = {
      enable = true;
      dockerSocket.enable = false;
      networkSocket = {
        enable = false;
        openFirewall = false;
        port = 2376;
        server = "ghostunnel";
        tls = {
          cert = "${podmanTLSPair}/server-cert.pem";
          cacert = "${podmanTLSPair}/server-cert.pem";
          key = "${podmanTLSPair}/server-key.pem";
        };
      };
      dockerCompat = true; # maps docker to podman
    };
    docker = {
      enable = false;
      package = pkgs.docker;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
      daemon.settings = {
        hosts = [
          "unix:////var/run/docker.sock"
          "tcp://0.0.0.0:2375"
        ];
      };
    };
  };
  environment.systemPackages = with pkgs; [
    docker
    docker-compose
  ];
}

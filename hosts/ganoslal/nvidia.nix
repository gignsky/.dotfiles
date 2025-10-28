{ config, lib, ... }:
# Ref. https://nixos.wiki/wiki/Nvidia
{
  nixpkgs.config.allowUnfree = lib.mkForce true;
  hardware = {
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
      prime = {
        sync.enable = true;
        nvidiaBusId = "PCI:45:0:0";
        amdgpuBusId = "PCI:23:0:0";
      };
    };
    graphics.enable = true;
  };
}

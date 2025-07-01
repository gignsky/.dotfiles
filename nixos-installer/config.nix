# This file is used during the installation process to allow unfree packages
{
  allowUnfree = true;
  allowUnfreePredicate = pkg: builtins.elem (builtins.parseDrvName pkg.name).name [
    "broadcom-sta"
  ];
}

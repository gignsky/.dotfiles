{ inputs, pkgs, ... }:

{
  home.packages = [
    inputs.neve.packages.${pkgs.system}.default
  ];
  # # Debug statement to ensure the file is being processed
  # environment.etc."gitconfig".text = ''
  #     [pull]
  #         rebase = true
  # '';
}

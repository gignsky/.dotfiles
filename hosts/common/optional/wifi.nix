{ ... }:

{
  # enables network manager to help with wifi
  networking.networkmanager.enable = true;
  # then connect to the wifi with the following command
  # `nmcli device wifi connect <SSID> password <password>`
}

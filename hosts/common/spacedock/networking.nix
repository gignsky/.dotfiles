_:

{
  networking = {
    hostName = "spacedock";

    # Disable DHCP globally
    useDHCP = false;

    # Configure static IP
    interfaces = {
      # You may need to adjust the interface name based on your system
      # Common names: eth0, enp0s25, ens18, etc.
      enp0s25 = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = "192.168.51.2";
            prefixLength = 24;
          }
        ];
      };
    };

    # Set default gateway
    defaultGateway = "192.168.51.1";

    # Set DNS servers
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };
}

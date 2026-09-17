_:

# Pin LAN DNS to the router (192.168.51.1).
#
# Background (2026-09-16): DHCP hands out 192.168.51.3 (memory-alpha) as the
# primary resolver. The Pi-hole container there wedged — pihole-FTL still holds
# UDP/TCP 53, so the port looks open, but it answers nothing. A hung resolver is
# worse than a dead one: queries are blackholed rather than refused, so every
# lookup burns the full resolver timeout (5s) twice before falling through to
# the next nameserver.
#
# Measured cost on both ganoslal and merlin: dns=10.01s, while the subsequent
# TCP connect took 0.02s and the TLS handshake 0.03s. Bandwidth was never the
# problem. Symptoms were "Steam downloads at a crawl" (many CDN hostnames, 10s
# each), apps with sub-10s connectivity checks failing outright, and speedtests
# looking fine (one lookup, then pure throughput).
#
# `networkmanager.dns = "none"` stops NetworkManager feeding the DHCP-provided
# resolver list to resolvconf, so the list below is authoritative. The search
# domain is set explicitly because dropping NM's DNS handling also drops the
# DHCP-supplied search domain.
#
# If Pi-hole is brought back up, either revert this or point `nameservers` at it
# again — but consider leaving a second entry either way so one wedged resolver
# cannot stall the whole fleet.
{
  networking = {
    networkmanager.dns = "none";
    nameservers = [ "192.168.51.1" ];
    search = [ "gignsky.com" ];
  };
}

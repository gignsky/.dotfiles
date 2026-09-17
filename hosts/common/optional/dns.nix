_:

# Put the router (192.168.51.1) first in the resolver list.
#
# Background (2026-09-16): DHCP hands out 192.168.51.3 (memory-alpha) as the
# primary resolver. The Pi-hole container there wedged — pihole-FTL still holds
# UDP/TCP 53, so the port looks open, but it answers nothing; `nslookup
# @127.0.0.1` times out on the box itself. A hung resolver is worse than a dead
# one: queries are blackholed rather than refused, so every lookup burns the
# full 5s resolver timeout twice before falling through to the next entry.
#
# Measured identically on ganoslal and merlin: dns=10.01s, while the subsequent
# TCP connect took 0.02s and the TLS handshake 0.03s. Bandwidth was never the
# problem. Symptoms were Steam downloads crawling (many CDN hostnames, 10s
# each), apps with sub-10s connectivity checks failing outright, and speedtests
# looking fine — one lookup, then pure throughput.
#
# WHY NOT `networking.nameservers`: on this fleet NetworkManager is the only
# thing writing /etc/resolv.conf (dhcpcd is inactive, systemd-resolved is off,
# and /run/resolvconf/interfaces does not exist). `networking.nameservers` is
# not plumbed through to resolvconf.conf on 26.05 and produces no
# environment.etc."resolv.conf" either, so setting it has no effect. Pairing it
# with `networkmanager.dns = "none"` is actively worse: NM stops writing the
# file and nothing replaces it.
#
# `insertNameservers` prepends to whatever DHCP supplies, so the list becomes
# 192.168.51.1 first with .3 and the IPv6 resolver kept as fallbacks. glibc
# tries them in order, so the first — responsive — server answers immediately,
# and no single wedged resolver can stall the fleet again.
#
# If Pi-hole comes back up and ad-blocking is wanted again, this can be dropped;
# leaving it costs only that .1 is preferred over .3.
{
  networking.networkmanager.insertNameservers = [ "192.168.51.1" ];
}

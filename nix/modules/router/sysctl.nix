_: {
  flake.nixosModules.router = {
    config,
    lib,
    ...
  }: let
    cfg = config.router;
  in
    lib.mkIf cfg.enable {
      boot.kernel.sysctl = {
        # Enable IPv4 and IPv6 packet forwarding
        "net.ipv4.conf.all.forwarding" = 1;
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv6.conf.default.forwarding" = 1;

        # Drop inbound ICMP redirects (matches OPNsense net.inet.icmp.drop_redirect=1)
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.secure_redirects" = 0;
        "net.ipv4.conf.default.secure_redirects" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;

        # Do not send ICMP redirects
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;

        # Reject source-routed packets (matches OPNsense sourceroute tunables)
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.default.accept_source_route" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;
        "net.ipv6.conf.default.accept_source_route" = 0;

        # Enable TCP SYN cookies
        "net.ipv4.tcp_syncookies" = 1;

        # Allow services (sshd, AdGuard Home, etc.) to bind to LAN IP before link carrier is up
        "net.ipv4.ip_nonlocal_bind" = 1;
        "net.ipv6.ip_nonlocal_bind" = 1;

        # Loose reverse path filtering on router interfaces
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
      };
    };
}

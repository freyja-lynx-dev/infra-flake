_: {
  flake.nixosModules.router = {
    config,
    lib,
    ...
  }: let
    cfg = config.router;
    hostFqdn = "${config.networking.hostName}.${cfg.domain}";
    unboundAddr = "127.0.0.1:${toString cfg.dns.unbound.port}";
  in
    lib.mkIf cfg.enable {
      # Unbound recursive DNS resolver (matches OPNsense unboundplus on port 5353)
      services.unbound = lib.mkIf cfg.dns.unbound.enable {
        enable = true;
        settings = {
          server = {
            interface = [
              "127.0.0.1"
              "::1"
            ];
            inherit (cfg.dns.unbound) port;
            access-control = [
              "127.0.0.0/8 allow"
              "::1/128 allow"
              "${cfg.lan.ipv4.subnet} allow"
            ];

            # Hardening & NSEC settings from OPNsense unboundplus
            harden-below-nxdomain = true;
            aggressive-nsec = true;
            hide-identity = false;
            hide-version = false;
            prefetch = false;
            prefetch-key = false;
            qname-minimisation-strict = false;
            verbosity = 1;

            # DNS rebinding protection private address ranges
            private-address = cfg.dns.unbound.privateAddresses;
            private-domain = ["\"${cfg.domain}\""];

            # Local transparent zone for the router's domain
            local-zone = ["\"${cfg.domain}.\" transparent"];
            local-data =
              [
                "\"${hostFqdn}. IN A ${cfg.lan.ipv4.address}\""
                "\"LynxRouter.${cfg.domain}. IN A ${cfg.lan.ipv4.address}\""
              ]
              ++ map (res: "\"${res.hostname}.${cfg.domain}. IN A ${res.ipAddress}\"") cfg.lan.dhcp.reservations;
            local-data-ptr =
              [
                "\"${cfg.lan.ipv4.address} ${hostFqdn}.\""
              ]
              ++ map (res: "\"${res.ipAddress} ${res.hostname}.${cfg.domain}.\"") cfg.lan.dhcp.reservations;
          };
        };
      };

      # AdGuard Home network-wide DNS & blocker (primary DNS on port 53, forwarding to Unbound)
      services.adguardhome = lib.mkIf cfg.dns.adguardhome.enable {
        enable = true;
        mutableSettings = true;
        openFirewall = false;
        settings = {
          http = {
            address = "${cfg.lan.ipv4.address}:${toString cfg.dns.adguardhome.webPort}";
          };
          dns = {
            bind_hosts = [
              "127.0.0.1"
              cfg.lan.ipv4.address
            ];
            port = 53;
            upstream_dns =
              if cfg.dns.unbound.enable
              then [unboundAddr]
              else ["1.1.1.1" "9.9.9.9"];
            bootstrap_dns =
              if cfg.dns.unbound.enable
              then [unboundAddr]
              else ["1.1.1.1" "9.9.9.9"];
          };
        };
      };

      networking.nameservers = ["127.0.0.1"];
    };
}

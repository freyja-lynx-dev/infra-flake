_: {
  flake.nixosModules.router = {
    config,
    lib,
    ...
  }: let
    cfg = config.router;

    macAliasSets = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: mac: ''
        set alias_${name} {
          type ether_addr
          elements = { ${lib.toLower mac} }
        }
      '')
      cfg.aliases.mac
    );

    staticPortRules = lib.concatStringsSep "\n" (
      map (cidr: ''
        oifname "${cfg.wan.interface}" ip saddr ${cidr} masquerade comment "Static port outbound NAT for ${cidr}"
      '')
      cfg.nat.staticPortSources
    );
  in
    lib.mkIf cfg.enable {
      networking.firewall.enable = false;
      networking.nftables = {
        enable = true;

        tables.router = {
          family = "inet";
          content = ''
            set rfc1918_v4 {
              type ipv4_addr
              flags interval
              elements = {
                10.0.0.0/8,
                172.16.0.0/12,
                192.168.0.0/16,
                169.254.0.0/16
              }
            }

            set bogons_v4 {
              type ipv4_addr
              flags interval
              elements = {
                0.0.0.0/8,
                127.0.0.0/8,
                192.0.0.0/24,
                192.0.2.0/24,
                198.18.0.0/15,
                198.51.100.0/24,
                203.0.113.0/24,
                224.0.0.0/4,
                240.0.0.0/4
              }
            }

            set bogons_v6 {
              type ipv6_addr
              flags interval
              elements = {
                ::/128,
                ::1/128,
                ::ffff:0:0/96,
                100::/64,
                2001:db8::/32,
                fc00::/7
              }
            }

            ${macAliasSets}

            chain prerouting {
              type nat hook prerouting priority dstnat; policy accept;

              ${lib.optionalString cfg.nat.redirectDnsToLocal ''
              iifname "${cfg.lan.interface}" ip daddr != ${cfg.lan.ipv4.address} meta l4proto { tcp, udp } th dport 53 dnat ip to ${cfg.lan.ipv4.address}:53 comment "Redirect all dns traffic to Adguard"
            ''}
            }

            chain mangle_postrouting {
              type filter hook postrouting priority mangle; policy accept;

              # Broadcom tg3 TX firmware hangs on packets tagged with DSCP EF (0xb8,
              # used by OpenSSH interactive sessions). Clear DSCP EF to CS0 before
              # handing packets to the NIC driver.
              ip dscp ef ip dscp set cs0 comment "Work around Broadcom tg3 TX hang on DSCP EF"
              ip6 dscp ef ip6 dscp set cs0 comment "Work around Broadcom tg3 TX hang on DSCP EF"
            }

            chain postrouting {
              type nat hook postrouting priority srcnat; policy accept;

              ${staticPortRules}
              oifname "${cfg.wan.interface}" ip saddr ${cfg.lan.ipv4.subnet} masquerade comment "Default LAN to WAN outbound NAT"
            }

            chain input {
              type filter hook input priority filter; policy drop;

              iifname "lo" accept comment "Allow loopback"
              ct state vmap { established : accept, related : accept, invalid : drop }

              ${lib.optionalString cfg.wan.blockPriv ''
              iifname "${cfg.wan.interface}" ip saddr @rfc1918_v4 drop comment "Block private networks from WAN"
            ''}
              ${lib.optionalString cfg.wan.blockBogons ''
              iifname "${cfg.wan.interface}" ip saddr @bogons_v4 drop comment "Block IPv4 bogons from WAN"
              iifname "${cfg.wan.interface}" ip6 saddr @bogons_v6 drop comment "Block IPv6 bogons from WAN"
            ''}

              # Allow essential DHCPv4 & DHCPv6 client & ICMPv6 on WAN
              iifname "${cfg.wan.interface}" udp sport 67 udp dport 68 accept comment "Allow DHCPv4 client on WAN"
              iifname "${cfg.wan.interface}" ip6 saddr fe80::/10 udp dport 546 accept comment "Allow DHCPv6 client on WAN"
              iifname "${cfg.wan.interface}" icmpv6 type {
                destination-unreachable,
                packet-too-big,
                time-exceeded,
                parameter-problem,
                echo-request,
                echo-reply,
                nd-router-advert,
                nd-neighbor-solicit,
                nd-neighbor-advert
              } accept comment "Allow essential ICMPv6 on WAN"

              # Allow all traffic from LAN (matches OPNsense default allow LAN to any)
              iifname "${cfg.lan.interface}" accept comment "Allow LAN to router services"
            }

            chain forward {
              type filter hook forward priority filter; policy drop;

              ct state vmap { established : accept, related : accept, invalid : drop }

              ${lib.optionalString cfg.wan.blockPriv ''
              iifname "${cfg.wan.interface}" ip saddr @rfc1918_v4 drop comment "Block private networks from WAN"
            ''}
              ${lib.optionalString cfg.wan.blockBogons ''
              iifname "${cfg.wan.interface}" ip saddr @bogons_v4 drop comment "Block IPv4 bogons from WAN"
              iifname "${cfg.wan.interface}" ip6 saddr @bogons_v6 drop comment "Block IPv6 bogons from WAN"
            ''}

              # Default allow LAN to any (IPv4 & IPv6)
              iifname "${cfg.lan.interface}" accept comment "Default allow LAN to any rule"

              # Allow forwarded packets that matched a DNAT rule (e.g. MiniUPnPd or port forwards)
              ct status dnat accept comment "Allow DNAT forwarded traffic"

              # Allow ICMPv6 forwarding required for end-to-end IPv6 connectivity
              icmpv6 type {
                destination-unreachable,
                packet-too-big,
                time-exceeded,
                parameter-problem,
                echo-request,
                echo-reply
              } accept comment "Allow forwarded ICMPv6"
            }
          '';
        };
      };
    };
}

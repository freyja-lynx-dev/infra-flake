{lib, ...}: {
  flake.nixosModules.router = {config, ...}: let
    cfg = config.router;
  in {
    options.router = {
      enable = lib.mkEnableOption "OPNsense-style NixOS router configuration";

      domain = lib.mkOption {
        type = lib.types.str;
        default = "lynxdomain";
        description = "Local domain name for the router and LAN.";
      };

      wan = {
        interface = lib.mkOption {
          type = lib.types.str;
          default = "wan";
          example = "eno2";
          description = ''
            Linux interface name for WAN (was `bge1` in OPNsense).
            If `macAddress` is set, systemd-udevd will automatically rename the
            matching physical interface to this name.
          '';
        };

        macAddress = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "00:10:18:xx:xx:xx";
          description = "Optional MAC address to bind and rename the WAN interface.";
        };

        pciPath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "pci-0000:09:00.0";
          description = "Optional systemd ID_PATH (e.g. pci-0000:09:00.0) to match and pin the WAN interface name.";
        };

        disableOffloading = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Disable hardware checksum, TCP segmentation, and generic receive
            offloading (matches OPNsense global interface settings).
          '';
        };

        blockPriv = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Block RFC1918 and link-local private networks on WAN ingress.";
        };

        blockBogons = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Block bogon/reserved IP space on WAN ingress.";
        };
      };

      lan = {
        interface = lib.mkOption {
          type = lib.types.str;
          default = "lan";
          example = "eno1";
          description = ''
            Linux interface name for LAN (was `bge0` in OPNsense).
            If `macAddress` is set, systemd-udevd will automatically rename the
            matching physical interface to this name.
          '';
        };

        macAddress = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "00:10:18:xx:xx:xy";
          description = "Optional MAC address to bind and rename the LAN interface.";
        };

        pciPath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "pci-0000:03:00.0";
          description = "Optional systemd ID_PATH (e.g. pci-0000:03:00.0) to match and pin the LAN interface name.";
        };

        disableOffloading = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Disable hardware checksum, TCP segmentation, and generic receive
            offloading (matches OPNsense global interface settings).
          '';
        };

        ipv4 = {
          address = lib.mkOption {
            type = lib.types.str;
            default = "192.168.1.1";
            description = "Static IPv4 address of the router on the LAN interface.";
          };

          prefixLength = lib.mkOption {
            type = lib.types.int;
            default = 24;
            description = "IPv4 subnet prefix length on LAN.";
          };

          subnet = lib.mkOption {
            type = lib.types.str;
            default = "192.168.1.0/24";
            description = "IPv4 CIDR block for the LAN network.";
          };
        };

        ipv6 = {
          trackWan = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Delegate an IPv6 /64 prefix from WAN (DHCPv6-PD) to LAN and send Router Advertisements.";
          };

          subnetId = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "IPv6 delegated prefix subnet ID (matches OPNsense track6-prefix-id).";
          };
        };

        dhcp = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable Kea DHCPv4 server on the LAN interface.";
          };

          rangeStart = lib.mkOption {
            type = lib.types.str;
            default = "192.168.1.10";
            description = "Start of the LAN DHCPv4 dynamic pool.";
          };

          rangeEnd = lib.mkOption {
            type = lib.types.str;
            default = "192.168.1.245";
            description = "End of the LAN DHCPv4 dynamic pool.";
          };

          validLifetime = lib.mkOption {
            type = lib.types.int;
            default = 4000;
            description = "DHCPv4 lease valid lifetime in seconds.";
          };

          reservations = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                hostname = lib.mkOption {
                  type = lib.types.str;
                  description = "Client hostname.";
                };
                hwAddress = lib.mkOption {
                  type = lib.types.str;
                  description = "Client MAC address.";
                };
                ipAddress = lib.mkOption {
                  type = lib.types.str;
                  description = "Reserved IPv4 address.";
                };
              };
            });
            default = [];
            description = "Static DHCPv4 lease reservations on LAN.";
          };
        };
      };

      aliases = {
        mac = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {};
          example = {
          };
          description = "Named MAC address aliases (migrated from OPNsense firewall aliases).";
        };
      };

      nat = {
        staticPortSources = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            cfg.lan.ipv4.subnet
          ];
          description = ''
            Source IPv4 CIDRs whose outbound NAT on WAN preserves static source
            ports (matches OPNsense outbound NAT rules with staticnatport=1).
          '';
        };

        redirectDnsToLocal = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Redirect all LAN IPv4 TCP/UDP port 53 queries destined for external
            resolvers to the router's local DNS server (AdGuard Home).
          '';
        };
      };

      dns = {
        adguardhome = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable AdGuard Home as the primary LAN DNS server on port 53.";
          };

          webPort = lib.mkOption {
            type = lib.types.port;
            default = 3000;
            description = "Port for the AdGuard Home web administration interface.";
          };
        };

        unbound = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable Unbound recursive DNS resolver as upstream for AdGuard Home.";
          };

          port = lib.mkOption {
            type = lib.types.port;
            default = 5353;
            description = "Local port for Unbound (matches OPNsense unboundplus port 5353).";
          };

          privateAddresses = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "0.0.0.0/8"
              "10.0.0.0/8"
              "100.64.0.0/10"
              "169.254.0.0/16"
              "172.16.0.0/12"
              "192.0.2.0/24"
              "192.168.0.0/16"
              "198.18.0.0/15"
              "198.51.100.0/24"
              "203.0.113.0/24"
              "233.252.0.0/24"
              "::1/128"
              "2001:db8::/32"
              "fc00::/8"
              "fd00::/8"
              "fe80::/10"
            ];
            description = "Private IP ranges enforced for DNS rebinding protection in Unbound.";
          };
        };
      };

      upnp = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable MiniUPnPd on LAN for automatic port forwarding.";
        };

        natpmp = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable NAT-PMP / PCP support in MiniUPnPd.";
        };
      };
    };
  };
}

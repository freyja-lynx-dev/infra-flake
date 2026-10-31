_: {
  flake.nixosModules.router = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.router;

    offloadLinkConfig = {
      ReceiveChecksumOffload = false;
      TransmitChecksumOffload = false;
      TCPSegmentationOffload = false;
      TCP6SegmentationOffload = false;
      GenericSegmentationOffload = false;
      GenericReceiveOffload = false;
      GenericReceiveOffloadHardware = false;
      LargeReceiveOffload = false;
      ReceiveVLANCTAGHardwareAcceleration = false;
      TransmitVLANCTAGHardwareAcceleration = false;
    };
  in
    lib.mkIf cfg.enable {
      networking = {
        inherit (cfg) domain;
        useDHCP = false;
        useNetworkd = true;
        networkmanager.enable = lib.mkForce false;

        timeServers = [
          "0.opnsense.pool.ntp.org"
          "1.opnsense.pool.ntp.org"
          "2.opnsense.pool.ntp.org"
          "3.opnsense.pool.ntp.org"
        ];
      };

      services.resolved.enable = false;

      # Ensure Thunderbolt PCIe tunnels (e.g. Apple Thunderbolt Gigabit Ethernet)
      # are automatically authorized on boot even without a desktop session.
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
      '';

      systemd.network = {
        enable = true;
        wait-online.anyInterface = true;

        links = {
          "10-wan" =
            lib.mkIf (cfg.wan.macAddress != null || cfg.wan.pciPath != null || cfg.wan.disableOffloading)
            {
              matchConfig =
                if cfg.wan.macAddress != null
                then {MACAddress = cfg.wan.macAddress;}
                else if cfg.wan.pciPath != null
                then {
                  Path = "${cfg.wan.pciPath} ${cfg.wan.pciPath}-*";
                  Type = "ether";
                }
                else {OriginalName = cfg.wan.interface;};
              linkConfig =
                (lib.optionalAttrs (cfg.wan.macAddress != null || cfg.wan.pciPath != null) {
                  Name = cfg.wan.interface;
                })
                // (lib.optionalAttrs cfg.wan.disableOffloading offloadLinkConfig);
            };

          "20-lan" =
            lib.mkIf (cfg.lan.macAddress != null || cfg.lan.pciPath != null || cfg.lan.disableOffloading)
            {
              matchConfig =
                if cfg.lan.macAddress != null
                then {MACAddress = cfg.lan.macAddress;}
                else if cfg.lan.pciPath != null
                then {
                  Path = "${cfg.lan.pciPath} ${cfg.lan.pciPath}-*";
                  Type = "ether";
                }
                else {OriginalName = cfg.lan.interface;};
              linkConfig =
                (lib.optionalAttrs (cfg.lan.macAddress != null || cfg.lan.pciPath != null) {
                  Name = cfg.lan.interface;
                })
                // (lib.optionalAttrs cfg.lan.disableOffloading offloadLinkConfig);
            };
        };

        networks = {
          "10-wan" = {
            matchConfig.Name = cfg.wan.interface;
            networkConfig = {
              DHCP = "yes";
              IPv6AcceptRA = true;
              IPv4Forwarding = true;
              IPv6Forwarding = true;
            };
            dhcpV4Config = {
              UseDNS = false;
              UseRoutes = true;
            };
            dhcpV6Config = {
              UseDNS = false;
              WithoutRA = "solicit";
              PrefixDelegationHint = "::/64";
            };
            ipv6AcceptRAConfig = {
              UseDNS = false;
              DHCPv6Client = "always";
            };
          };

          "20-lan" = {
            matchConfig.Name = cfg.lan.interface;
            address = [
              "${cfg.lan.ipv4.address}/${toString cfg.lan.ipv4.prefixLength}"
            ];
            networkConfig = {
              IPv4Forwarding = true;
              IPv6Forwarding = true;
              IPv6SendRA = cfg.lan.ipv6.trackWan;
              DHCPPrefixDelegation = cfg.lan.ipv6.trackWan;
              ConfigureWithoutCarrier = true;
            };
            dhcpPrefixDelegationConfig = lib.mkIf cfg.lan.ipv6.trackWan {
              UplinkInterface = cfg.wan.interface;
              SubnetId = cfg.lan.ipv6.subnetId;
              Announce = true;
            };
            ipv6SendRAConfig = lib.mkIf cfg.lan.ipv6.trackWan {
              EmitDNS = true;
              DNS = ["_link_local"];
              EmitDomains = true;
              Domains = [cfg.domain];
            };
          };
        };
      };

      environment.systemPackages = with pkgs; [
        conntrack-tools
        dig
        ethtool
        iperf3
        iproute2
        mtr
        nftables
        tcpdump
      ];
    };
}

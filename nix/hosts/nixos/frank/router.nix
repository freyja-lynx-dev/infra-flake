_: {
  flake.nixosModules.frank = {
    router = {
      enable = true;
      domain = "lynxdomain";

      # Mapped from OPNsense pciconf & dmesg:
      # - WAN (was bge1@pci0:9:0:0, Apple Thunderbolt Gigabit Ethernet BCM57762) -> enp9s0 (44:f0:9e:a8:13:88 / pci-0000:09:00.0)
      # - LAN (was bge0@pci0:3:0:0, Mac Mini onboard BCM57766) -> enp3s0 (0c:4d:e9:c6:1b:af / pci-0000:03:00.0)
      wan = {
        interface = "enp9s0";
        pciPath = "pci-0000:09:00.0";
        macAddress = "44:f0:9e:a8:13:88";
        disableOffloading = false;
        blockPriv = true;
        blockBogons = true;
      };

      lan = {
        interface = "enp3s0";
        pciPath = "pci-0000:03:00.0";
        macAddress = "0c:4d:e9:c6:1b:af";
        disableOffloading = false;

        ipv4 = {
          address = "192.168.1.1";
          prefixLength = 24;
          subnet = "192.168.1.0/24";
        };

        ipv6 = {
          trackWan = true;
          subnetId = 0;
        };

        dhcp = {
          enable = true;
          rangeStart = "192.168.1.10";
          rangeEnd = "192.168.1.245";
          validLifetime = 4000;
          reservations = [];
        };
      };

      # Firewall MAC aliases
      aliases.mac = {};

      # Outbound NAT static port rules + LAN port 53 DNS intercept to AdGuard Home
      nat = {
        staticPortSources = [
          "192.168.1.139/32"
          "192.168.1.0/24"
        ];
        redirectDnsToLocal = true;
      };

      # Primary DNS via AdGuard Home (:53) -> local Unbound recursive resolver (:5353)
      dns = {
        adguardhome = {
          enable = true;
          webPort = 3000;
        };

        unbound = {
          enable = true;
          port = 5353;
        };
      };

      # MiniUPnPd for LAN -> WAN automatic port mapping
      upnp = {
        enable = true;
        natpmp = true;
      };
    };
  };
}

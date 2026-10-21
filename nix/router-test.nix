{
  inputs,
  self,
  ...
}: {
  perSystem = {
    lib,
    pkgs,
    system,
    ...
  }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.router-test = pkgs.testers.runNixOSTest {
        name = "frank-router-test";
        node.specialArgs = {inherit self;};

        nodes = {
          isp = {
            lib,
            pkgs,
            ...
          }: {
            virtualisation.vlans = [1];

            networking = {
              useDHCP = false;
              firewall.enable = false;
              interfaces.eth1 = {
                ipv4.addresses = lib.mkForce [
                  {
                    address = "93.184.216.1";
                    prefixLength = 24;
                  }
                ];
                ipv6.addresses = lib.mkForce [];
              };
            };

            services.kea.dhcp4 = {
              enable = true;
              settings = {
                valid-lifetime = 4000;
                interfaces-config = {
                  interfaces = ["eth1"];
                  dhcp-socket-type = "raw";
                };
                lease-database = {
                  type = "memfile";
                  persist = true;
                  name = "/var/lib/kea/dhcp4.leases";
                };
                subnet4 = [
                  {
                    id = 1;
                    subnet = "93.184.216.0/24";
                    pools = [{pool = "93.184.216.2 - 93.184.216.2";}];
                    option-data = [
                      {
                        name = "routers";
                        data = "93.184.216.1";
                      }
                    ];
                  }
                ];
              };
            };

            services.nginx = {
              enable = true;
              virtualHosts.default = {
                root = pkgs.writeTextDir "index.html" "hello from isp\n";
              };
            };

            environment.systemPackages = [
              pkgs.curl
              pkgs.netcat
            ];
          };

          frank = {lib, ...}: {
            imports = [
              inputs.disko.nixosModules.disko
              inputs.sops-nix.nixosModules.sops
              self.nixosModules.default
              self.nixosModules.router
              self.nixosModules.frank
            ];

            virtualisation.vlans = [
              1
              2
            ];

            # Prevent NixOS test driver from assigning static 192.168.1.x/192.168.2.x VLAN IPs
            networking.interfaces = {
              eth1 = {
                ipv4.addresses = lib.mkForce [];
                ipv6.addresses = lib.mkForce [];
              };
              eth2 = {
                ipv4.addresses = lib.mkForce [];
                ipv6.addresses = lib.mkForce [];
              };
            };

            # Map VM VLAN interfaces: eth1 = WAN (VLAN 1), eth2 = LAN (VLAN 2)
            router = {
              wan = {
                interface = lib.mkForce "eth1";
                pciPath = lib.mkForce null;
              };
              lan = {
                interface = lib.mkForce "eth2";
                pciPath = lib.mkForce null;
              };
            };
          };

          client = {
            lib,
            pkgs,
            ...
          }: {
            virtualisation.vlans = [2];

            networking = {
              useDHCP = false;
              useNetworkd = true;
              firewall.enable = false;
              interfaces.eth1 = {
                ipv4.addresses = lib.mkForce [];
                ipv6.addresses = lib.mkForce [];
              };
            };

            services.resolved.enable = false;

            systemd.network = {
              enable = true;
              networks."10-lan" = {
                matchConfig.Name = "eth1";
                networkConfig.DHCP = "ipv4";
                dhcpV4Config = {
                  UseDNS = true;
                  UseRoutes = true;
                };
              };
            };

            environment.systemPackages = [
              pkgs.curl
              pkgs.dig
              pkgs.miniupnpc
              pkgs.python3
            ];
          };
        };

        testScript = ''
          start_all()

          isp.wait_for_unit("kea-dhcp4-server.service")
          isp.wait_for_unit("nginx.service")

          frank.wait_for_unit("nftables.service")
          frank.wait_for_unit("unbound.service")
          frank.wait_for_unit("adguardhome.service")
          frank.wait_for_unit("kea-dhcp4-server.service")
          frank.wait_for_unit("miniupnpd.service")
          frank.wait_for_unit("sshd.service")

          with subtest("WAN DHCPv4 acquisition"):
              frank.wait_until_succeeds("ip -4 addr show dev eth1 | grep -q '93.184.216.2/24'", timeout=30)

          with subtest("LAN DHCPv4 lease & gateway"):
              client.wait_until_succeeds("ip -4 addr show dev eth1 | grep -Eq '192\\.168\\.1\\.[0-9]+/24'", timeout=30)
              client.succeed("ip route show default | grep -q 'via 192.168.1.1'")
              client.succeed("ping -c 1 192.168.1.1")

          with subtest("DNS resolution via AdGuard Home -> Unbound"):
              client.wait_until_succeeds(
                  "dig +short @192.168.1.1 frank.lynxdomain | grep -qx '192.168.1.1'",
                  timeout=30,
              )
              client.succeed(
                  "dig +short @192.168.1.1 LynxRouter.lynxdomain | grep -qx '192.168.1.1'"
              )

          with subtest("LAN port 53 DNAT redirect to AdGuard Home"):
              # Querying external IP 93.184.216.1:53 from LAN should be transparently
              # redirected by frank's nftables prerouting rule to 192.168.1.1:53
              client.succeed(
                  "dig +short @93.184.216.1 frank.lynxdomain | grep -qx '192.168.1.1'"
              )

          with subtest("LAN to WAN outbound NAT routing"):
              output = client.succeed("curl -sf http://93.184.216.1/")
              assert "hello from isp" in output, f"Unexpected HTTP response: {output}"

          with subtest("WAN ingress firewall blocks unsolicited connections"):
              isp.fail("curl --connect-timeout 2 -sf http://93.184.216.2:3000/")
              isp.fail("nc -z -w 2 93.184.216.2 22")

          with subtest("UPnP dynamic port forwarding (MiniUPnPd + nftables)"):
              client_ip = client.succeed(
                  "ip -4 -o addr show dev eth1 | awk '{split($4, a, \"/\"); print a[1]}'"
              ).strip()
              client.succeed("python3 -m http.server 8080 --directory /etc >/tmp/http.log 2>&1 &")
              client.wait_for_open_port(8080)
              client.succeed(f"upnpc -e 'test-upnp' -a {client_ip} 8080 8080 TCP")
              isp.wait_until_succeeds("curl -sf http://93.184.216.2:8080/hostname | grep -q client", timeout=15)
        '';
      };
    };
}

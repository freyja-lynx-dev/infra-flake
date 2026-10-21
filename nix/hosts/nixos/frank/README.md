# 🛡️ Frank

NixOS edge router replacing `LynxRouter.lynxdomain` (OPNsense).

## OPNsense Feature Mapping

| OPNsense Component                        | NixOS Equivalent (`self.nixosModules.router`)                                                             |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| **Hostname / Domain**                     | `frank.lynxdomain` (with `LynxRouter.lynxdomain` local DNS alias)                                         |
| **WAN (`bge1`)**                          | `systemd-networkd` DHCPv4 + DHCPv6 Prefix Delegation (`::/64`), bogon & RFC1918 ingress blocking          |
| **LAN (`bge0`)**                          | Static `192.168.1.1/24` + IPv6 `track6` (`subnetId = 0`) + Router Advertisements                          |
| **Hardware Offloading**                   | Checksum, TSO, GSO, GRO, LRO, and VLAN hardware filtering disabled via `systemd.network.links`            |
| **DHCPv4 (`os-isc-dhcp`)**                | `services.kea.dhcp4` serving `192.168.1.10` – `192.168.1.245` (`valid-lifetime = 4000s`)                  |
| **AdGuard Home (`os-adguardhome-maxit`)** | `services.adguardhome` listening on `:53` (DNS) and `192.168.1.1:3000` (Web UI)                           |
| **Unbound (`unboundplus` on `:5353`)**    | `services.unbound` on `127.0.0.1:5353` with `aggressive-nsec`, `harden-below-nxdomain`, rebind protection |
| **DNS NAT Redirect**                      | `nftables` `prerouting` DNAT rule redirecting LAN port 53 (`!= 192.168.1.1`) to `192.168.1.1:53`          |
| **Outbound NAT (Hybrid / Static Port)**   | `nftables` `postrouting` masquerade preserving static source ports for `192.168.1.139/32` & LAN           |
| **UPnP (`os-upnp` / `miniupnpd`)**        | `services.miniupnpd` with `nftables` integration (UPnP IGD + NAT-PMP on LAN -> WAN)                       |

## Hardware Notes

In FreeBSD/OPNsense, the Broadcom NetXtreme Gigabit Ethernet NICs were named `bge1` (WAN) and `bge0` (LAN). On Linux (`tg3` driver), either:

1. Set `router.wan.macAddress` and `router.lan.macAddress` in [`router.nix`](./router.nix) so `systemd-udevd` automatically renames them to `bge1` and `bge0`, or
2. Update `router.wan.interface` and `router.lan.interface` in [`router.nix`](./router.nix) to match Linux's interface names (e.g. `eno2` and `eno1`).

Before running Disko on the target hardware, verify `disko.devices.disk.main.device` in [`disko.nix`](./disko.nix).

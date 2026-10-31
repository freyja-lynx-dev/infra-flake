# 🛡️ Frank

NixOS edge router replacing `LynxRouter.lynxdomain` (OPNsense).

## OPNsense Feature Mapping

| OPNsense Component                        | NixOS Equivalent (`self.nixosModules.router`)                                                             |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| **Hostname / Domain**                     | `frank.lynxdomain` (with `LynxRouter.lynxdomain` local DNS alias)                                         |
| **WAN (`bge1`)**                          | `systemd-networkd` DHCPv4 + DHCPv6 Prefix Delegation (`::/64`), bogon & RFC1918 ingress blocking          |
| **LAN (`bge0`)**                          | Static `192.168.1.1/24` + IPv6 `track6` (`subnetId = 0`) + Router Advertisements                          |
| **Hardware Offloading**                   | Native Linux `tg3` kernel offloading defaults (`disableOffloading` optional via `systemd.network.links`)  |
| **DHCPv4 (`os-isc-dhcp`)**                | `services.kea.dhcp4` serving `192.168.1.10` – `192.168.1.245` (`valid-lifetime = 4000s`)                  |
| **AdGuard Home (`os-adguardhome-maxit`)** | `services.adguardhome` listening on `:53` (DNS) and `192.168.1.1:3000` (Web UI)                           |
| **Unbound (`unboundplus` on `:5353`)**    | `services.unbound` on `127.0.0.1:5353` with `aggressive-nsec`, `harden-below-nxdomain`, rebind protection |
| **DNS NAT Redirect**                      | `nftables` `prerouting` DNAT rule redirecting LAN port 53 (`!= 192.168.1.1`) to `192.168.1.1:53`          |
| **Outbound NAT (Hybrid / Static Port)**   | `nftables` `postrouting` masquerade preserving static source ports for `192.168.1.139/32` & LAN           |
| **UPnP (`os-upnp` / `miniupnpd`)**        | `services.miniupnpd` with `nftables` integration (UPnP IGD + NAT-PMP on LAN -> WAN)                       |

## Hardware Notes

- **WAN (`enp9s0`)**: Apple Thunderbolt Gigabit Ethernet Broadcom BCM57762 (`bge1@pci0:9:0:0` -> `44:f0:9e:a8:13:88` / `pci-0000:09:00.0`)
- **LAN (`enp3s0`)**: Mac Mini Onboard Broadcom BCM57766 Gigabit Ethernet (`bge0@pci0:3:0:0` -> `0c:4d:e9:c6:1b:af` / `pci-0000:03:00.0`)
- **Storage**: SATA SSD (`/dev/disk/by-id/wwn-0x5002538e40307989`) with `tmpfs` ephemeral root (`/`) and Btrfs `@nix`, `@persist`, and `@var-log` subvolumes via [`impermanence.nix`](impermanence.nix)

## Bootable USB Image (`frank-usb`)

[`usb-image.nix`](usb-image.nix) defines `packages.x86_64-linux.frank-usb` (`nixosConfigurations.frank.config.system.build.images.usb`), a self-contained GPT/UEFI raw disk image for testing `frank` on real hardware before wiping the internal OPNsense SSD:

- Overrides `disko.devices` so only `/dev/disk/by-label/nixos` (`ext4`) and `/dev/disk/by-label/ESP` (`vfat`, `nofail`) are mounted, with `boot.growPartition = false` so slow USB flash I/O never stalls `local-fs.target`.
- Sets `boot.loader.efi.canTouchEfiVariables = false` so `systemd-boot` installs to `/EFI/BOOT/BOOTX64.EFI` without altering Mac NVRAM boot variables.
- Enables `services.getty.autologinUser = "freyja"` on the physical console (`tty1`) and pre-authorizes `freyja@192.168.1.1` SSH key login (`root` login disabled).

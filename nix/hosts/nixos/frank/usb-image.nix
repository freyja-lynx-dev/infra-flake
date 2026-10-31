{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.frank = {lib, ...}: {
    # Self-contained bootable GPT/UEFI raw disk image for testing `frank` on real
    # hardware from a USB stick without touching the internal OPNsense SSD or NVRAM.
    image.modules.usb = {pkgs, ...}: let
      ssdToplevel = self.nixosConfigurations.frank.config.system.build.toplevel;
      ssdDiskoScript = self.nixosConfigurations.frank.config.system.build.diskoScript;
      installFrankToSsd = pkgs.writeShellApplication {
        name = "install-frank-to-ssd";
        runtimeInputs = with pkgs; [
          coreutils
          nixos-install-tools
          util-linux
        ];
        text = ''
          if [ "$(id -u)" -ne 0 ]; then
            echo "error: install-frank-to-ssd must be run as root (use: sudo install-frank-to-ssd)" >&2
            exit 1
          fi

          target_disk="/dev/disk/by-id/wwn-0x5002538e40307989"
          if [ ! -b "$target_disk" ]; then
            echo "error: target SSD $target_disk not found" >&2
            exit 1
          fi

          echo "=================================================================="
          echo " WARNING: Permanent NixOS Installation to Internal SSD"
          echo " Target disk: $target_disk ($(readlink -f "$target_disk"))"
          echo " System:      ${ssdToplevel}"
          echo "=================================================================="
          echo "This will WIPE OPNsense on the internal SSD, format it with Btrfs"
          echo "(@nix, @persist, @var-log) + impermanence tmpfs root, migrate your"
          echo "current SSH host keys, DHCP leases, and AdGuard Home state from"
          echo "this USB drive into /persist, and install NixOS."
          echo ""
          read -r -p "Type 'yes' to permanently install frank to the internal SSD: " confirm
          if [ "$confirm" != "yes" ]; then
            echo "Aborted."
            exit 1
          fi

          echo "==> Partitioning, formatting, and mounting $target_disk via Disko..."
          "${ssdDiskoScript}"

          echo "==> Migrating live router state from USB to /mnt/persist..."
          mkdir -p /mnt/persist/etc/ssh /mnt/persist/var/lib
          if [ -f /etc/machine-id ]; then
            cp -a /etc/machine-id /mnt/persist/etc/machine-id
          fi
          cp -a /etc/ssh/ssh_host_* /mnt/persist/etc/ssh/
          for state_dir in nixos private systemd; do
            if [ -d "/var/lib/$state_dir" ]; then
              cp -a "/var/lib/$state_dir" /mnt/persist/var/lib/
            fi
          done

          echo "==> Installing frank NixOS closure to /mnt..."
          nixos-install --no-root-passwd --no-channel-copy --root /mnt --system "${ssdToplevel}"

          echo "==> Syncing filesystems and unmounting /mnt..."
          sync
          umount -Rv /mnt

          echo "==> Installation complete! You can now run 'sudo poweroff', unplug"
          echo "    the USB drive, and power frank back on to boot from the SSD."
        '';
      };
    in {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/virtualisation/disk-image.nix"
      ];

      environment.systemPackages = [installFrankToSsd];

      image = {
        baseName = "frank-router-usb";
        efiSupport = true;
        format = "raw";
      };

      # Disable Disko's internal SSD partition mounts and `/persist` bind mounts
      # so the self-contained USB image only mounts its own /dev/disk/by-label/nixos
      # and /dev/disk/by-label/ESP.
      disko.devices = lib.mkForce {};
      environment.persistence."/persist".enable = lib.mkForce false;
      fileSystems."/persist".enable = lib.mkForce false;
      fileSystems."/var/log".enable = lib.mkForce false;

      # Do not block or abort local-fs.target if slow USB stick I/O or partition
      # table probing delays /dev/disk/by-label/ESP during boot.
      boot.growPartition = lib.mkForce false;
      fileSystems."/".autoResize = lib.mkForce false;
      fileSystems."/boot".options = ["nofail"];

      # Install systemd-boot to the removable media path (/EFI/BOOT/BOOTX64.EFI)
      # and never modify the host motherboard's EFI NVRAM boot order.
      boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

      # Automatically log admin user `freyja` in on a local physical console
      # (HDMI + USB keyboard) for easy local debugging when booting from USB,
      # and allow emergency/rescue shells on physical console even with root locked.
      services.getty.autologinUser = "freyja";
      systemd.services.emergency.environment.SYSTEMD_SULOGIN_FORCE = "1";
      systemd.services.rescue.environment.SYSTEMD_SULOGIN_FORCE = "1";
      boot.initrd.systemd.services.emergency.environment.SYSTEMD_SULOGIN_FORCE = "1";
    };
  };

  perSystem = {system, ...}:
    inputs.nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
      packages.frank-usb = self.nixosConfigurations.frank.config.system.build.images.usb;
    };
}

{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.frank = {lib, ...}: {
    # Self-contained bootable GPT/UEFI raw disk image for testing `frank` on real
    # hardware from a USB stick without touching the internal OPNsense SSD or NVRAM.
    image.modules.usb = {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/virtualisation/disk-image.nix"
      ];

      image = {
        baseName = "frank-router-usb";
        efiSupport = true;
        format = "raw";
      };

      # Disable Disko's internal SSD partition mounts so the USB image only mounts
      # its own /dev/disk/by-label/nixos (auto-resizing ext4) and /dev/disk/by-label/ESP.
      disko.devices = lib.mkForce {};

      # Install systemd-boot to the removable media path (/EFI/BOOT/BOOTX64.EFI)
      # and never modify the host motherboard's EFI NVRAM boot order.
      boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

      # Automatically log root in on a local physical console (HDMI + USB keyboard)
      # for easy local debugging when booting from USB.
      services.getty.autologinUser = "root";
    };
  };

  perSystem = {system, ...}:
    inputs.nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
      packages.frank-usb = self.nixosConfigurations.frank.config.system.build.images.usb;
    };
}

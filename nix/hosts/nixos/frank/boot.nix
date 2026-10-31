_: {
  flake.nixosModules.frank = {
    boot = {
      loader = {
        systemd-boot = {
          enable = true;
          configurationLimit = 10;
        };
        efi.canTouchEfiVariables = true;
      };

      # SATA/NVMe and USB mass-storage/HID modules for USB live/test boot.
      # Keep `tg3` out of stage-1 initrd so stage-2 systemd-udevd applies our
      # `/etc/systemd/network/*.link` rules cleanly when `tg3` loads.
      initrd.availableKernelModules = [
        "ahci"
        "ehci_pci"
        "hid_apple"
        "hid_generic"
        "nvme"
        "sd_mod"
        "uas"
        "uhci_hcd"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];

      # Authorize Thunderbolt devices (Apple Thunderbolt Gigabit Ethernet WAN
      # adapter) and load the Broadcom NetXtreme (`tg3`) driver in stage 2.
      kernelModules = [
        "thunderbolt"
        "tg3"
      ];

      # Matches OPNsense serialspeed=115200 with primaryconsole=video.
      # `nomodeset` keeps the UEFI GOP framebuffer (efifb/simpledrm) active so
      # KMS does not switch the HDMI output to an unsupported monitor mode.
      kernelParams = [
        "nomodeset"
        "console=ttyS0,115200n8"
        "console=tty0"
      ];
    };
  };
}

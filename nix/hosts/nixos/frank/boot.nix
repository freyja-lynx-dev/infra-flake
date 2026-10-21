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

      # Broadcom NetXtreme Gigabit Ethernet (bge0/bge1 in FreeBSD -> tg3 in Linux)
      # plus SATA/NVMe and USB mass-storage/HID modules for USB live/test boot
      initrd.availableKernelModules = [
        "ahci"
        "ehci_pci"
        "hid_apple"
        "hid_generic"
        "nvme"
        "sd_mod"
        "tg3"
        "uas"
        "uhci_hcd"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];

      # Matches OPNsense serialspeed=115200 with primaryconsole=video
      kernelParams = [
        "console=ttyS0,115200n8"
        "console=tty0"
      ];
    };
  };
}

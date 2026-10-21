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
      initrd.availableKernelModules = [
        "ahci"
        "nvme"
        "sd_mod"
        "tg3"
        "uas"
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

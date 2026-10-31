_: {
  flake.nixosModules.frank = {lib, ...}: {
    disko.devices.disk.main = {
      device = "/dev/disk/by-id/wwn-0x5002538e40307989";
      type = "disk";

      content = {
        type = "gpt";

        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";

            content = {
              format = "vfat";
              mountOptions = ["umask=0077"];
              mountpoint = "/boot";
              type = "filesystem";
            };
          };

          root = {
            size = "100%";

            content = {
              extraArgs = ["-f"];
              type = "btrfs";

              subvolumes = {
                "@nix" = {
                  mountOptions = ["compress=zstd" "noatime"];
                  mountpoint = "/nix";
                };

                "@persist" = {
                  mountOptions = ["compress=zstd" "noatime"];
                  mountpoint = "/persist";
                };

                "@var-log" = {
                  mountOptions = ["compress=zstd" "noatime"];
                  mountpoint = "/var/log";
                };
              };
            };
          };
        };
      };
    };

    # Ephemeral root on tmpfs ("erase your darlings")
    fileSystems = {
      "/" = lib.mkDefault {
        device = "none";
        fsType = "tmpfs";
        options = ["defaults" "size=1G" "mode=755"];
      };
      "/persist".neededForBoot = true;
      "/var/log".neededForBoot = true;
    };
  };
}

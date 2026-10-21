_: {
  flake.nixosModules.frank = {
    disko.devices.disk.main = {
      # Update to match the target router disk (e.g. /dev/disk/by-id/...)
      device = "/dev/sda";
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
                "@" = {
                  mountOptions = ["compress=zstd" "noatime"];
                  mountpoint = "/";
                };

                "@home" = {
                  mountOptions = ["compress=zstd" "noatime"];
                  mountpoint = "/home";
                };

                "@nix" = {
                  mountOptions = ["compress=zstd" "noatime"];
                  mountpoint = "/nix";
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
  };
}

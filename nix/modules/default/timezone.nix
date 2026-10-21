{lib, ...}: {
  flake.nixosModules.default = {
    time.timeZone = lib.mkDefault "Etc/UTC";
  };
}

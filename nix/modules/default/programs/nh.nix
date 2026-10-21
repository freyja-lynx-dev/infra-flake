_: {
  flake.nixosModules.default = {pkgs, ...}: {
    environment.systemPackages = [pkgs.git];
    programs.nh.enable = true;
  };
}

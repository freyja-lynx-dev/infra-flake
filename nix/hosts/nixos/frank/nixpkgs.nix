{
  lib,
  sharedPackageSets,
  ...
}: {
  flake.nixosModules.frank.nixpkgs.pkgs = lib.mkDefault sharedPackageSets.x86_64-linux;
}

{sharedPackageSets, ...}: {
  flake.nixosModules.frank.nixpkgs.pkgs = sharedPackageSets.x86_64-linux;
}

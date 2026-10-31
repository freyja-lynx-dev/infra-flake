{
  inputs,
  self,
  ...
}: {
  config.flake.nixosConfigurations.frank = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = [
      inputs.disko.nixosModules.disko
      inputs.impermanence.nixosModules.impermanence
      inputs.sops-nix.nixosModules.sops
      self.nixosModules.default
      self.nixosModules.router
      self.nixosModules.frank
    ];

    specialArgs = {inherit self;};
  };
}

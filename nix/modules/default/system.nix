_: {
  flake.nixosModules.default = {self, ...}: {
    system.configurationRevision = self.rev or self.dirtyRev or null;
  };
}

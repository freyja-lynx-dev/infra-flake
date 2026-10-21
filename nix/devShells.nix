_: {
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      packages = [
        pkgs.age
        pkgs.git
        pkgs.just
        pkgs.nh
        pkgs.nixd
        pkgs.sops
        pkgs.ssh-to-age
      ];

      shellHook = ''
        export FLAKE="." NH_FLAKE="."
        echo "👋 Welcome to the infra-flake devShell!"
      '';
    };
  };
}

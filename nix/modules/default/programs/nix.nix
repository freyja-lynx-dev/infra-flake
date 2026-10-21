_: {
  flake.nixosModules.default = {
    nix.daemonCPUSchedPolicy = "idle";

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      extra-substituters = [
        "https://install.determinate.systems"
        "https://nix-community.cachix.org"
      ];

      extra-trusted-public-keys = [
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      max-free = 5 * 1024 * 1024 * 1024;
      min-free = 1024 * 1024 * 1024;
    };

    nix.gc = {
      automatic = true;
      options = "--delete-older-than 7d";
      persistent = true;
      randomizedDelaySec = "60min";
    };

    nix.optimise = {
      automatic = true;
      persistent = true;
      randomizedDelaySec = "60min";
    };
  };
}

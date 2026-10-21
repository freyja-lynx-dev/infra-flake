_: {
  flake.nixosModules.default = {
    systemd = {
      coredump.enable = false;
      enableEmergencyMode = false;

      oomd = {
        enable = true;
        enableRootSlice = true;
        enableSystemSlice = true;
        enableUserSlices = true;
      };
    };
  };
}

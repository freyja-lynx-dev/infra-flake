_: {
  flake.nixosModules.default = {
    services.journald.settings.Journal = {
      Storage = "persistent";
      SystemMaxUse = "1G";
      SystemKeepFree = "1G";
      MaxRetentionSec = "1month";
    };
  };
}

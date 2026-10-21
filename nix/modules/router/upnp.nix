_: {
  flake.nixosModules.router = {
    config,
    lib,
    ...
  }: let
    cfg = config.router;
  in
    lib.mkIf (cfg.enable && cfg.upnp.enable) {
      services.miniupnpd = {
        enable = true;
        externalInterface = cfg.wan.interface;
        internalIPs = [cfg.lan.interface];
        upnp = true;
        inherit (cfg.upnp) natpmp;
      };

      systemd.services.miniupnpd = {
        after = [
          "network-online.target"
          "nftables.service"
        ];
        wants = [
          "network-online.target"
          "nftables.service"
        ];
      };
    };
}

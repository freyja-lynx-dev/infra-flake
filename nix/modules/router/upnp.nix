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
    };
}

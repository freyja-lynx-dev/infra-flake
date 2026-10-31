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
        serviceConfig = {
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";
          RestrictSUIDSGID = true;
          CapabilityBoundingSet = [
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
            "CAP_NET_BROADCAST"
            "CAP_NET_RAW"
          ];
        };
      };
    };
}

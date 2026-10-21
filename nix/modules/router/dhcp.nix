_: {
  flake.nixosModules.router = {
    config,
    lib,
    ...
  }: let
    cfg = config.router;
  in
    lib.mkIf (cfg.enable && cfg.lan.dhcp.enable) {
      services.kea.dhcp4 = {
        enable = true;
        settings = {
          valid-lifetime = cfg.lan.dhcp.validLifetime;
          renew-timer = cfg.lan.dhcp.validLifetime / 4;
          rebind-timer = cfg.lan.dhcp.validLifetime / 2;

          interfaces-config = {
            interfaces = [cfg.lan.interface];
            dhcp-socket-type = "raw";
          };

          lease-database = {
            type = "memfile";
            persist = true;
            name = "/var/lib/kea/dhcp4.leases";
          };

          subnet4 = [
            {
              id = 1;
              subnet = cfg.lan.ipv4.subnet;
              pools = [
                {
                  pool = "${cfg.lan.dhcp.rangeStart} - ${cfg.lan.dhcp.rangeEnd}";
                }
              ];
              option-data = [
                {
                  name = "routers";
                  data = cfg.lan.ipv4.address;
                }
                {
                  name = "domain-name-servers";
                  data = cfg.lan.ipv4.address;
                }
                {
                  name = "domain-name";
                  data = cfg.domain;
                }
                {
                  name = "domain-search";
                  data = cfg.domain;
                }
              ];
              reservations =
                map (res: {
                  inherit (res) hostname;
                  hw-address = res.hwAddress;
                  ip-address = res.ipAddress;
                })
                cfg.lan.dhcp.reservations;
            }
          ];
        };
      };
    };
}

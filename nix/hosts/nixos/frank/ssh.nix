_: {
  flake.nixosModules.frank = {config, ...}: {
    # Matches OPNsense SSH configuration (LAN interface, root & password auth allowed)
    services.openssh = {
      enable = true;
      openFirewall = false;
      listenAddresses = [
        {
          addr = config.router.lan.ipv4.address;
          port = 22;
        }
      ];
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "yes";
      };
    };
  };
}

_: {
  flake.nixosModules.frank = {
    # Rootless SSH configuration (root login & password auth disabled; WAN
    # access is blocked by the nftables input chain in `router/firewall.nix`).
    services.openssh = {
      enable = true;
      openFirewall = false;
      settings = {
        IPQoS = "none";
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    users = {
      mutableUsers = false;

      # Lock root account completely
      users.root.hashedPassword = "!";

      # Admin user `freyja` with passwordless sudo and SSH key authentication
      users.freyja = {
        isNormalUser = true;
        extraGroups = ["wheel"];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDKzPQwVhunyLGzCWrWcqjXLBdKbDV2iqwfNwWx/SHcs freyja@freyja-lynx.dev"
        ];
      };
    };
  };
}

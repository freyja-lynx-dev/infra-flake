_: {
  flake.nixosModules.frank = {
    environment.persistence."/persist" = {
      hideMounts = true;

      # Note: kea-dhcp4-server and adguardhome both use DynamicUser = true with
      # StateDirectory, so their state lives under /var/lib/private/{kea,AdGuardHome}.
      directories = [
        "/var/lib/nixos"
        "/var/lib/private"
        "/var/lib/systemd"
      ];

      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
  };
}

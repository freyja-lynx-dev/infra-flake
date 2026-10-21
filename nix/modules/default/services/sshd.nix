{lib, ...}: {
  flake.nixosModules.default = {
    services.openssh = {
      enable = true;
      openFirewall = lib.mkDefault true;

      settings = {
        KbdInteractiveAuthentication = lib.mkDefault false;
        PasswordAuthentication = lib.mkDefault false;
        PermitRootLogin = lib.mkDefault "prohibit-password";
      };
    };
  };
}

{ pkgs, ... }: {
  environment.systemPackages = [
    pkgs.gitMinimal
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
  };

  networking.firewall.enable = true;

  services.journald.extraConfig = ''
    RuntimeMaxUse=100M
    SystemMaxUse=500M
  '';
}

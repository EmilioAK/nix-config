{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    gitMinimal
    mosh
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

  networking.firewall = {
    enable = true;
    allowedUDPPortRanges = [
      {
        from = 60000;
        to = 61000;
      }
    ];
  };

  services.journald.extraConfig = ''
    RuntimeMaxUse=100M
    SystemMaxUse=500M
  '';
}

{ username, ... }: {
  nix.settings.trusted-users = [ "root" "@wheel" ];

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.11";
}

{ pkgs, username, ... }: {
  nix.extraOptions = ''
    !include /home/${username}/.config/nix/github-access-token.conf
  '';

  nix.settings.trusted-users = [ "root" "@wheel" ];

  users.defaultUserShell = pkgs.zsh;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.11";
}

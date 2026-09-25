{ pkgs, username, dotfile, ... }: {
  imports = [
    ./dotfiles-lib.nix
    ./packages.nix
    ./zsh.nix
    ./agents.nix
  ];

  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
  programs.starship.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      vps = {
        HostName = "vps.emilioak.dev";
        User = "emilio";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = "yes";
        ConnectTimeout = 15;
        ConnectionAttempts = 3;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.file.".gitconfig".source = dotfile "gitconfig";

  xdg.configFile."git/ignore".source = dotfile "git/ignore";
  xdg.configFile."nvim".source = dotfile "nvim";
  xdg.configFile."starship.toml".source = dotfile "starship.toml";
  xdg.configFile."zsh/antidote-before-compinit.txt".source =
    dotfile "zsh/antidote-before-compinit.txt";
  xdg.configFile."zsh/antidote-after-compinit.txt".source =
    dotfile "zsh/antidote-after-compinit.txt";
}

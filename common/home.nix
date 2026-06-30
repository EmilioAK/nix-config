{ config, pkgs, username, ... }:
let
  flakeRoot = "${config.home.homeDirectory}/.config/nix-darwin";
  dotfile = path: config.lib.file.mkOutOfStoreSymlink "${flakeRoot}/dotfiles/${path}";
in {
  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    fish
    git
    neovim
    fd
    fzf
    lazygit
    nodejs
    ripgrep
    mosh
    fastfetch
    starship
    gh
    tmux
    taskwarrior3
    tasksh
    codex
    claude-code
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      vps = {
        HostName = "vps.emilioak.dev";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = "yes";
      };
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.file.".zshenv".source = dotfile "zshenv";
  home.file.".zshrc".source = dotfile "zshrc";
  home.file.".codex/config.toml".source = dotfile "codex/config.toml";
  home.file.".codex/rules/default.rules".source = dotfile "codex/rules/default.rules";
  home.file.".codex/skills".source = dotfile "codex/skills";
  home.file.".gitconfig".source = dotfile "gitconfig";
  xdg.configFile."git/ignore".source = dotfile "git/ignore";
  xdg.configFile."nvim".source = dotfile "nvim";
  xdg.configFile."starship.toml".source = dotfile "starship.toml";
}

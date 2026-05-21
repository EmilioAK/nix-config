{ pkgs, config, username, ... }:
let
  flakeRoot = "${config.home.homeDirectory}/.config/nix-darwin";
  dotfile = path: config.lib.file.mkOutOfStoreSymlink "${flakeRoot}/dotfiles/${path}";
in {
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      vps = {
        hostname = "vps.emilioak.dev";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # Temporary Darwin workaround: direnv's upstream fish check is currently
    # getting killed during nix builds, so disable checks until nixpkgs lands
    # the proper fix.
    package = pkgs.direnv.overrideAttrs (_: { doCheck = false; });
  };

  home.file.".zshenv".source = dotfile "zshenv";
  home.file.".zshrc".source = dotfile "zshrc";
  home.file.".codex/config.toml".source = dotfile "codex/config.toml";
  home.file.".codex/rules/default.rules".source = dotfile "codex/rules/default.rules";
  home.file.".gitconfig".source = dotfile "gitconfig";
  xdg.configFile."git/ignore".source = dotfile "git/ignore";
  xdg.configFile."ghostty/config".source = dotfile "ghostty/config";
  xdg.configFile."fish".source = dotfile "fish";
  xdg.configFile."aerospace/aerospace.toml".source = dotfile "aerospace/aerospace.toml";
  xdg.configFile."karabiner/karabiner.json".source = dotfile "karabiner/karabiner.json";
  xdg.configFile."nvim".source = dotfile "nvim";
  xdg.configFile."starship.toml".source = dotfile "starship.toml";
}

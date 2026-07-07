{ config, ... }:
let
  flakeRoot = "${config.home.homeDirectory}/.config/nix-config";
  dotfile = path: config.lib.file.mkOutOfStoreSymlink "${flakeRoot}/dotfiles/${path}";
in {
  home.file.".tmux.conf".source = dotfile "tmux/tmux.conf";
}

{ config, ... }:
let
  flakeRoot = "${config.home.homeDirectory}/.config/nix-config";
  dotfile = path: config.lib.file.mkOutOfStoreSymlink "${flakeRoot}/dotfiles/${path}";
in {
  home.file.".tmux.conf".source = dotfile "tmux/tmux.conf";

  home.file.".local/bin/tmux-bell-alerts" = {
    source = dotfile "tmux/bin/tmux-bell-alerts";
    executable = true;
  };
  home.file.".local/bin/tmux-clear-pi-agent-alert" = {
    source = dotfile "tmux/bin/tmux-clear-pi-agent-alert";
    executable = true;
  };
  home.file.".local/bin/tmux-jump-agent-alert" = {
    source = dotfile "tmux/bin/tmux-jump-agent-alert";
    executable = true;
  };
}

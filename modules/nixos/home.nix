{ dotfile, inputs, pkgs, ... }: {
  # The headless VPS uses terminal agents; the Mac uses the desktop apps.
  home.packages = [
    pkgs.claude-code
    pkgs.codex
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home.file.".tmux.conf".source = dotfile "tmux/tmux.conf";

  home.file.".codex/hooks.json" = {
    source = dotfile "codex/hooks.json";
    force = true;
  };
  home.file.".codex/hooks/herdr-agent-state.sh" = {
    source = dotfile "codex/hooks/herdr-agent-state.sh";
    force = true;
  };
  home.file.".claude/hooks/herdr-agent-state.sh" = {
    source = dotfile "claude/hooks/herdr-agent-state.sh";
    force = true;
  };

  xdg.configFile."herdr/config.toml" = {
    source = dotfile "herdr/config.toml";
    force = true;
  };
  xdg.configFile."herdr/rename-agent-launch.sh" = {
    source = dotfile "herdr/rename-agent-launch.sh";
    force = true;
  };
  xdg.configFile."herdr/rename-agent-prompt.sh" = {
    source = dotfile "herdr/rename-agent-prompt.sh";
    force = true;
  };
}

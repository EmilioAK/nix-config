{ config, lib, pkgs, hostname, dotfile, flakeRoot, ... }:
let
  # Hosts without an entry fall back to the shared default context.
  agentContextByHost = {
    nix-vps = "agents/AGENTS.vps.md";
  };
  agentContextFile =
    agentContextByHost.${hostname} or "agents/AGENTS.default.md";

  codexConfigByHost = {
    nix-vps = "codex/config.vps.toml";
    Emilios-MacBook-Pro = "codex/config.mac.toml";
  };
  codexConfigFile = codexConfigByHost.${hostname}
    or (throw "No Codex config declared for host ${hostname}");

  # Desktop Code sessions also use these settings. Keep the Mac's settings
  # separate from the VPS's terminal integration.
  claudeSettingsFile = if pkgs.stdenv.isDarwin
    then "claude/settings.mac.json"
    else "claude/settings.json";
in {
  # The desktop app uses the same Codex configuration as the CLI.
  home.file.".codex/AGENTS.md".source = dotfile agentContextFile;
  home.file.".codex/config.toml".source = dotfile codexConfigFile;
  home.file.".codex/rules/default.rules".source = dotfile "codex/rules/default.rules";

  # Claude Code atomically rewrites settings beside the symlink's immediate
  # target. Home Manager's normal store indirection makes that directory
  # read-only, so create a direct, writable out-of-store link instead.
  home.activation.linkClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settingsPath=${lib.escapeShellArg "${config.home.homeDirectory}/.claude/settings.json"}
    sourcePath=${lib.escapeShellArg "${flakeRoot}/dotfiles/${claudeSettingsFile}"}
    run mkdir -p "$(${pkgs.coreutils}/bin/dirname "$settingsPath")"
    run rm -f "$settingsPath"
    run ln -s "$sourcePath" "$settingsPath"
  '';
}

{ config, pkgs, ... }:
let
  flakeRoot = "${config.home.homeDirectory}/.config/nix-config";
  dotfile = path: config.lib.file.mkOutOfStoreSymlink "${flakeRoot}/dotfiles/${path}";
in {
  home.file.".tmux.conf".source = dotfile "tmux/tmux.conf";

  home.packages = with pkgs; [
    playwright-test
    playwright-mcp
  ];

  xdg.configFile."mcp/mcp.json".text = builtins.toJSON {
    mcpServers = {
      playwright = {
        command = "${pkgs.playwright-mcp}/bin/playwright-mcp";
        args = [
          "--headless"
          "--browser" "chromium"
          "--isolated"
          "--output-dir" "${config.xdg.cacheHome}/playwright-mcp-output"
        ];
        lifecycle = "lazy";
        requestTimeoutMs = 60000;
      };
    };
  };
}

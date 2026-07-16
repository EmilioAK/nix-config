{ config, pkgs, ... }:
let
  flakeRoot = "${config.home.homeDirectory}/.config/nix-config";
  dotfile = path: config.lib.file.mkOutOfStoreSymlink "${flakeRoot}/dotfiles/${path}";
  moshiHookVersion = "0.2.47";
  moshiHookArch =
    if pkgs.stdenv.hostPlatform.isx86_64 then "x86_64"
    else if pkgs.stdenv.hostPlatform.isAarch64 then "arm64"
    else throw "moshi-hook does not support ${pkgs.stdenv.hostPlatform.system}";
  moshiHookHash = {
    x86_64 = "sha256-jKT1yib6MWuOl4G5ESeFXdEydNWg/aLgYXZUs79U1uk=";
    arm64 = "sha256-t4MAhk35lmnantfGUHfiO2/u37o3OyPMU7HaXjP7uvs=";
  }.${moshiHookArch};
  moshiHook = pkgs.stdenvNoCC.mkDerivation {
    pname = "moshi-hook";
    version = moshiHookVersion;
    src = pkgs.fetchurl {
      url = "https://cdn.getmoshi.app/hook/v${moshiHookVersion}/moshi-hook_Linux_${moshiHookArch}.tar.gz";
      hash = moshiHookHash;
    };
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      install -Dm755 moshi-hook "$out/bin/moshi-hook"
      ln -s moshi-hook "$out/bin/moshi"
      runHook postInstall
    '';
  };
in {
  home.file.".tmux.conf".source = dotfile "tmux/tmux.conf";

  home.packages = with pkgs; [
    playwright-test
    playwright-mcp
    moshiHook
  ];

  home.file.".local/bin/moshi-hook" = {
    source = "${moshiHook}/bin/moshi-hook";
    force = true;
  };
  home.file.".local/bin/moshi" = {
    source = "${moshiHook}/bin/moshi";
    force = true;
  };

  systemd.user.services.moshi-hook = {
    Unit = {
      Description = "Moshi hook daemon";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${moshiHook}/bin/moshi-hook serve";
      Restart = "on-failure";
      RestartSec = 5;
      WorkingDirectory = config.home.homeDirectory;
    };
    Install.WantedBy = [ "default.target" ];
  };

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

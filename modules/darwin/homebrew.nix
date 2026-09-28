{ username, ... }:
let
  # Keep downloads for one week and check for full cleanup daily when Brew runs
  # an install, upgrade, or reinstall (defaults are 120 and 30 days).
  cachePolicy = ''
    HOMEBREW_CLEANUP_MAX_AGE_DAYS=7
    HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=1
  '';
in
{
  home-manager.users.${username} = {
    # Brew chooses its user config path based on whether XDG_CONFIG_HOME is set.
    xdg.configFile."homebrew/brew.env".text = cachePolicy;
    home.file.".homebrew/brew.env".text = cachePolicy;
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
      extraFlags = [ "--force-cleanup" ];
    };

    taps = [
      "nikitabobko/tap"
    ];

    brews = [
      "mas"
    ];

    casks = [
      "ghostty"
      "nikitabobko/tap/aerospace"
      "karabiner-elements"
      "google-chrome"
      # ChatGPT desktop app, including Codex; separate from the CLI package.
      "chatgpt"
      "claude"
      "discord"
      "element"
      "visual-studio-code"
      "vlc"
      "trezor-suite"
      "obsidian"
      "anki"
      "highball"
    ];

    masApps = {
      "Bitwarden" = 1352778147;
      "WhatsApp Messenger" = 310633997;
      "Xcode" = 497799835;
    };
  };
}

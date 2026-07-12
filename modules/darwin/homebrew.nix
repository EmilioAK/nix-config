{ ... }: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
      extraFlags = [ "--force-cleanup" ];
    };

    taps  = [ "nikitabobko/tap" ];

    brews = [
      "mas"
    ];

    casks = [
      "ghostty"
      "nikitabobko/tap/aerospace"
      "karabiner-elements"
      "google-chrome"
      # Codex desktop app; Homebrew retains the historical cask token.
      "chatgpt"
      "discord"
      "element"
      "visual-studio-code"
      "vlc"
      "trezor-suite"
      "obsidian"
    ];

    masApps = {
      "Bitwarden" = 1352778147;
      "WhatsApp Messenger" = 310633997;
      "Xcode" = 497799835;
    };
  };
}

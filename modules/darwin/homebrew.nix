{ ... }: {
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
    ];

    masApps = {
      "Bitwarden" = 1352778147;
      "WhatsApp Messenger" = 310633997;
      "Xcode" = 497799835;
    };
  };
}

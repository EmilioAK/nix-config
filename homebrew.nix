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
      "fish"
      "git"
      "mas"
      "neovim"
      "fd"
      "fzf"
      "lazygit"
      "node"
      "ripgrep"
      "mosh"
      "fastfetch"
      "starship"
      "gh"
      "dafny"
      "tmux"
    ];

    casks = [
      "font-jetbrains-mono-nerd-font"
      "ghostty"
      "nikitabobko/tap/aerospace"
      "karabiner-elements"
      "google-chrome"
      "discord"
      "codex"
      "element"
      "visual-studio-code"
      "vlc"
      "trezor-suite"
    ];

    masApps = {
      "Bitwarden" = 1352778147;
      "WhatsApp Messenger" = 310633997;
      "OmniFocus 4" = 1542143627;
    };
  };
}

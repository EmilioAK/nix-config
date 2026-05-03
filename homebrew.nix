{ ... }: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
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
    ];

    masApps = {
      "Bitwarden" = 1352778147;
      "WhatsApp Messenger" = 310633997;
    };
  };
}

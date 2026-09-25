{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Editor and language tooling
    neovim
    nil
    nixfmt
    statix
    pyright
    ruff

    # Shell and search
    antidote
    fd
    fzf
    nix-zsh-completions
    ripgrep

    # Version control
    git
    gh
    lazygit

    # Misc
    fastfetch
    mosh
    nodejs
    tmux
  ];
}

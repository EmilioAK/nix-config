{ ... }: {
  nixpkgs.config.allowUnfree = true;

  programs.zsh.enable = true;

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };
}

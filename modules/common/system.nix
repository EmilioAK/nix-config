{ lib, pkgs, platform, username, ... }: {
  nixpkgs.config.allowUnfree = true;

  programs.zsh.enable = true;

  users.users.${username}.shell = pkgs.zsh;

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };
} // lib.optionalAttrs (platform == "nixos") {
  users.defaultUserShell = pkgs.zsh;
}

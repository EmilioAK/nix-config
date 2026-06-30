{
  platform = "nixos";
  username = "emilio";
  system = "x86_64-linux";
  extraSystemModules = [ ../modules/nixos/devbox.nix ];
  extraHomeModules = [ ];
}

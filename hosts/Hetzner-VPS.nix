{
  platform = "nixos";
  username = "emilio";
  system = "x86_64-linux";
  extraSystemModules = [ ../nixos/devbox.nix ];
  extraHomeModules = [ ];
}

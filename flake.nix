{
  description = "Emilio's Darwin system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nix-darwin, nixpkgs, home-manager, ... }:
  let
    inherit (nixpkgs) lib;

    # Each machine is a tracked file in ./hosts named after its LocalHostName,
    # e.g. hosts/Emilios-MacBook-Pro.nix. Paths inside a host file are relative
    # to ./hosts (so work modules are ../work/foo.nix).
    hostNames = map (lib.removeSuffix ".nix")
      (builtins.attrNames (builtins.readDir ./hosts));

    mkHost = hostname:
      let
        cfg = import (./hosts + "/${hostname}.nix");
        specialArgs = { inherit hostname; inherit (cfg) username; };
      in
      nix-darwin.lib.darwinSystem {
        inherit (cfg) system;
        inherit specialArgs;
        modules = [
          ./system.nix
          ./homebrew.nix
          { networking.hostName = hostname; }
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.${cfg.username} = import ./home.nix;
          }
        ] ++ (cfg.workModules or [ ]);
      };
  in {
    darwinConfigurations = lib.genAttrs hostNames mkHost;
  };
}

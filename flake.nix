{
  description = "Emilio's systems";

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
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nix-darwin, nixpkgs, home-manager, disko, ... }:
  let
    inherit (nixpkgs) lib;

    profiles = {
      capisoft = import ./profiles/work/capisoft;
      thesis = import ./profiles/uni/thesis;
    };

    getSelectedProfiles = cfg:
      map (name: profiles.${name}
        or (throw "Unknown profile '${name}'"))
        (cfg.profiles or [ ]);

    getProfileModules = cfg: field:
      lib.concatMap (profile: profile.${field} or [ ])
        (getSelectedProfiles cfg);

    # Each machine is a tracked file in ./hosts named after its hostname,
    # e.g. hosts/Emilios-MacBook-Pro.nix. Host files declare their platform.
    hostNames = map (lib.removeSuffix ".nix")
      (lib.filter (lib.hasSuffix ".nix")
        (builtins.attrNames (builtins.readDir ./hosts)));

    hostConfigs = lib.genAttrs hostNames
      (hostname: import (./hosts + "/${hostname}.nix"));

    hostsWithPlatform = platform:
      lib.filterAttrs (_: cfg: cfg.platform == platform) hostConfigs;

    mkDarwinHost = hostname: cfg:
      let
        specialArgs = {
          inherit hostname inputs;
          inherit (cfg) platform username;
        };
      in
      nix-darwin.lib.darwinSystem {
        inherit (cfg) system;
        inherit specialArgs;
        modules = [
          ./modules/common/system.nix
          ./modules/darwin/system.nix
          ./modules/darwin/homebrew.nix
          { networking.hostName = hostname; }
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.${cfg.username} = {
              imports = [
                ./modules/common/home.nix
                ./modules/darwin/home.nix
              ] ++ getProfileModules cfg "homeModules"
                ++ (cfg.extraHomeModules or [ ]);
            };
          }
        ] ++ getProfileModules cfg "darwinModules"
          ++ (cfg.extraSystemModules or [ ]);
      };

    mkNixosHost = hostname: cfg:
      let
        specialArgs = {
          inherit hostname inputs;
          inherit (cfg) platform username;
        };
      in
      nixpkgs.lib.nixosSystem {
        inherit (cfg) system;
        inherit specialArgs;
        modules = [
          ./modules/common/system.nix
          ./modules/nixos/system.nix
          disko.nixosModules.disko
          { networking.hostName = hostname; }
        ] ++ lib.optionals (cfg.enableHomeManager or true) [
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.${cfg.username} = {
              imports = [
                ./modules/common/home.nix
                ./modules/nixos/home.nix
              ] ++ getProfileModules cfg "homeModules"
                ++ (cfg.extraHomeModules or [ ]);
            };
          }
        ] ++ getProfileModules cfg "nixosModules"
          ++ (cfg.extraSystemModules or [ ]);
      };
  in {
    darwinConfigurations = lib.mapAttrs mkDarwinHost
      (hostsWithPlatform "darwin");
    nixosConfigurations = lib.mapAttrs mkNixosHost
      (hostsWithPlatform "nixos");
  };
}

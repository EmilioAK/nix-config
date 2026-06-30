let
  sshKeys = import ../modules/common/ssh-keys.nix;
in {
  platform = "nixos";
  username = "emilio";
  system = "x86_64-linux";
  includeProfiles = false;
  enableHomeManager = false;
  extraSystemModules = [
    ../modules/nixos/hetzner-vps.nix
    ../modules/nixos/server.nix
    ({ username, ... }: {
      users.users.${username}.openssh.authorizedKeys.keys = [
        sshKeys.emilio.personal
      ];
    })
  ];
  extraHomeModules = [ ];
}

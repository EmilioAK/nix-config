let
  sshKeys = import ../modules/common/ssh-keys.nix;
in {
  platform = "nixos";
  username = "emilio";
  system = "x86_64-linux";
  includeProfiles = false;
  enableHomeManager = true;
  extraSystemModules = [
    ../modules/nixos/hetzner-vps.nix
    ../modules/nixos/server.nix
    ../profiles/work/capisoft/nixos.nix
    ({ username, ... }: {
      programs.fish.enable = true;

      systemd.tmpfiles.rules = [
        "L /home/${username}/Repos - - - - /mnt/data/home/${username}/Repos"
      ];

      users.users.${username} = {
        uid = 1000;
        openssh.authorizedKeys.keys = [
          sshKeys.emilio.personal
        ];
      };
    })
  ];
  extraHomeModules = [
    ../profiles/work/capisoft/home.nix
  ];
}

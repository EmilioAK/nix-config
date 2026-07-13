{ config, ... }:
let
  flakeRoot = "${config.home.homeDirectory}/.config/nix-config";
  capisoftFile = path: config.lib.file.mkOutOfStoreSymlink
    "${flakeRoot}/profiles/work/capisoft/${path}";
in {
  programs.ssh.settings."bitbucket.org" = {
    IdentityFile = "~/.ssh/id_ed25519_bitbucket";
    IdentitiesOnly = "yes";
  };

  home.file.".agents/skills/capisoft-jira-tasks" = {
    source = capisoftFile "skills/capisoft-jira-tasks";
    force = true;
  };
}

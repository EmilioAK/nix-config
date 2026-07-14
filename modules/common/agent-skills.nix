{ config, lib, pkgs, ... }:
let
  cfg = config.emilio.agentSkills;
in {
  options.emilio.agentSkills.sources = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    internal = true;
  };

  config = lib.mkIf (cfg.sources != { }) {
    # Manage the discovery root as one link. Managing its children separately
    # can make Home Manager follow an older root symlink into the source tree.
    home.file.".agents/skills" = {
      source = pkgs.linkFarm "agent-skills" cfg.sources;
      force = true;
    };
  };
}

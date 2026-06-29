{ username, ... }: {
  homebrew = {
    taps = [
      { name = "netbirdio/tap"; trusted = true; }
    ];
    casks = [
      "netbirdio/tap/netbird-ui"
      "slack"
    ];
  };

  home-manager.users.${username}.programs.ssh.settings."bitbucket.org" = {
    IdentityFile = "~/.ssh/id_ed25519_bitbucket";
    IdentitiesOnly = "yes";
  };
}

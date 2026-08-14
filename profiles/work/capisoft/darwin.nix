{ ... }: {
  homebrew = {
    taps = [
      { name = "netbirdio/tap"; trusted = true; }
    ];
    brews = [
      "netbirdio/tap/netbird"
    ];
    casks = [
      "docker-desktop"
      "netbirdio/tap/netbird-ui"
      "obs"
      "slack"
      "mactex-no-gui"
    ];
  };
}

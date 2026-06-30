{ ... }: {
  homebrew = {
    taps = [
      { name = "netbirdio/tap"; trusted = true; }
    ];
    casks = [
      "netbirdio/tap/netbird-ui"
      "slack"
    ];
  };
}

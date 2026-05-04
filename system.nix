{ username, ... }:
let
  keyboardLayout = id: name: {
    InputSourceKind = "Keyboard Layout";
    "KeyboardLayout ID" = id;
    "KeyboardLayout Name" = name;
  };

  usLayout = keyboardLayout 0 "U.S.";
  swedishProLayout = keyboardLayout 7 "Swedish - Pro";
in {
  system.primaryUser = username;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  nix.settings.experimental-features = "nix-command flakes";

  security.pam.services.sudo_local.touchIdAuth = true;

  # Bump only when `darwin-rebuild changelog` tells you to.
  system.stateVersion = 6;

  # macOS preference defaults — discover more in the nix-darwin manual.
  system.defaults = {
    CustomUserPreferences = {
      # Observed from System Settings after configuring Color Filters.
      "com.apple.mediaaccessibility" = {
        "__Color__-MADisplayFilterType" = 16;
        MADisplayFilterSingleColorIntensity = 0.8940475583076477;
      };
      "com.apple.HIToolbox" = {
        AppleCurrentKeyboardLayoutInputSourceID = "com.apple.keylayout.US";
        AppleDefaultAsciiInputSource = usLayout;
        AppleEnabledInputSources = [ usLayout swedishProLayout ];
        AppleInputSourceHistory = [ usLayout swedishProLayout ];
        AppleSelectedInputSources = [ usLayout ];
      };
      "com.apple.TextInputMenu" = {
        visible = true;
      };
    };
    WindowManager = {
      GloballyEnabled = false;
      EnableStandardClickToShowDesktop = false;
      StandardHideWidgets = true;
      StageManagerHideWidgets = true;
    };
    dock = {
      autohide = true;
      expose-group-apps = true;
      mru-spaces = false;
      persistent-apps = [
        "/Applications/Google Chrome.app"
        "/Applications/Ghostty.app"
      ];
      show-recents = false;
      wvous-bl-corner = 1;
      wvous-br-corner = 1;
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
    };
    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      FXPreferredViewStyle = "clmv";  # column view
    };
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      InitialKeyRepeat = 14;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };
  };
}

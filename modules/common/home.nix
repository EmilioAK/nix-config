{ config, lib, pkgs, username, hostname, ... }:
let
  flakeRoot = "${config.home.homeDirectory}/.config/nix-config";
  dotfile = path: config.lib.file.mkOutOfStoreSymlink "${flakeRoot}/dotfiles/${path}";
  agentContextByHost = {
    nix-vps = "agents/AGENTS.vps.md";
    Emilios-MacBook-Pro = "agents/AGENTS.mac.md";
  };
  agentContextFile =
    agentContextByHost.${hostname} or "agents/AGENTS.default.md";
  zshConfigDir = "${config.xdg.configHome}/zsh";
  # npm CLIs that move faster than nixpkgs. `sup` installs each package at
  # `version` or `latest` into ~/.local/share/npm and verifies its expected bins.
  trackedNpmPackages = [
    {
      package = "@earendil-works/pi-coding-agent";
      bins = [ "pi" ];
    }
    {
      package = "@openai/codex";
      bins = [ "codex" ];
    }
    # To move Claude Code to npm later, add:
    # {
    #   package = "@anthropic-ai/claude-code";
    #   bins = [ "claude" ];
    # }
  ];
  trackedNpmPackageSpecs = lib.concatMapStringsSep "\n            "
    (pkg: builtins.toJSON "${pkg.package}@${pkg.version or "latest"}")
    trackedNpmPackages;
  trackedNpmBins = lib.concatMapStringsSep "\n            " builtins.toJSON
    (lib.concatMap (pkg: pkg.bins or [ ]) trackedNpmPackages);
in {
  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    fish
    git
    neovim
    fd
    fzf
    lazygit
    nodejs
    ripgrep
    mosh
    fastfetch
    gh
    tmux
    taskwarrior3
    tasksh
    claude-code
    herdr
    antidote
    nix-zsh-completions
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = false;

    shellAliases = {
      t = "task";
      ti = "task add +inbox";
      tin = "task inbox";
      tf = "task focus";
      ts = "task stale";
      ta = "task await";
      tsh = "tasksh";
      trev = "tasksh";
    };

    history = {
      size = 50000;
      save = 50000;
      append = true;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
    };

    envExtra = ''
      typeset -U path PATH

      path=(
        $HOME/.local/share/npm/bin
        $HOME/.nix-profile/bin
        /etc/profiles/per-user/$USER/bin
        /run/wrappers/bin
        /run/current-system/sw/bin
        /nix/var/nix/profiles/default/bin
        $path
      )

      if [ -d /opt/homebrew/bin ]; then
        path+=(
          /opt/homebrew/bin
          /opt/homebrew/sbin
        )
      elif [ -d /usr/local/bin ]; then
        path+=(
          /usr/local/bin
          /usr/local/sbin
        )
      fi

      export PATH
    '';

    initContent = lib.mkMerge [
      (lib.mkOrder 530 ''
        export ANTIDOTE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}/antidote"
        source ${pkgs.antidote}/share/antidote/antidote.zsh

        __antidote_static_source() {
          local name="$1"
          local bundle_file="$2"
          local static_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
          local static_file="$static_dir/antidote-$name.zsh"

          mkdir -p "$static_dir"
          if [[ ! "$static_file" -nt "$bundle_file" ]]; then
            antidote bundle < "$bundle_file" >| "$static_file"
          fi

          source "$static_file"
        }
      '')

      (lib.mkOrder 540 ''
        __antidote_static_source completions ${zshConfigDir}/antidote-before-compinit.txt
      '')

      (lib.mkOrder 570 ''
        autoload -Uz compinit
        mkdir -p "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
        compinit -d "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
      '')

      (lib.mkOrder 1200 ''
        __antidote_static_source interactive ${zshConfigDir}/antidote-after-compinit.txt
        unfunction __antidote_static_source
      '')

      (lib.mkOrder 1290 ''
        __sup_update_npm_packages() {
          local npm_prefix="$HOME/.local/share/npm"
          local pi_bin="$npm_prefix/bin/pi"
          local npm_update_status=0
          local rc
          local tracked_npm_packages=(
            ${trackedNpmPackageSpecs}
          )
          local tracked_npm_bins=(
            ${trackedNpmBins}
          )

          if ! command -v npm >/dev/null 2>&1; then
            echo "sup: npm not found; skipping tracked npm package updates" >&2
            return 1
          fi

          mkdir -p "$npm_prefix" || return $?
          path=("$npm_prefix/bin" $path)

          if (( ''${#tracked_npm_packages[@]} > 0 )); then
            echo "sup: updating tracked npm packages"
            npm install -g --prefix "$npm_prefix" --no-audit --no-fund "''${tracked_npm_packages[@]}" || {
              rc=$?
              (( npm_update_status == 0 )) && npm_update_status=$rc
            }
          fi

          for bin in "''${tracked_npm_bins[@]}"; do
            if [ ! -x "$npm_prefix/bin/$bin" ]; then
              echo "sup: expected npm bin not found: $npm_prefix/bin/$bin" >&2
              (( npm_update_status == 0 )) && npm_update_status=1
            fi
          done

          if [ -x "$pi_bin" ]; then
            echo "sup: updating Pi packages"
            (cd "$HOME" && "$pi_bin" update --extensions --no-approve) || {
              rc=$?
              (( npm_update_status == 0 )) && npm_update_status=$rc
            }
          fi

          return "$npm_update_status"
        }
      '')

      (lib.mkIf pkgs.stdenv.isDarwin (lib.mkOrder 1300 ''
        sb() {
          local flake="$HOME/.config/nix-config"
          local host

          host="$(scutil --get LocalHostName)" || return $?
          darwin-rebuild build --flake "$flake#$host"
        }

        ssw() {
          local flake="$HOME/.config/nix-config"
          local host

          host="$(scutil --get LocalHostName)" || return $?
          sudo -H darwin-rebuild switch --flake "$flake#$host"
        }

        sup() {
          local flake="$HOME/.config/nix-config"
          local host
          local zsh_plugin_status=0
          local npm_update_status=0

          host="$(scutil --get LocalHostName)" || return $?

          nix flake update --flake "$flake" || return $?

          if sudo -H darwin-rebuild switch --flake "$flake#$host"; then
            if command -v antidote >/dev/null 2>&1; then
              echo "sup: updating zsh plugins"
              antidote update || zsh_plugin_status=$?
            fi

            __sup_update_npm_packages || npm_update_status=$?

            if ! git -C "$flake" diff --quiet -- flake.lock; then
              git -C "$flake" commit -m "flake.lock: update inputs" -- flake.lock
            fi

            echo "sup: collecting Nix garbage older than 30 days"
            sudo -H nix-collect-garbage --delete-older-than 30d || return $?
            if (( zsh_plugin_status != 0 )); then
              return "$zsh_plugin_status"
            fi
            return "$npm_update_status"
          else
            echo "sup: switch failed; restoring flake.lock" >&2
            git -C "$flake" restore flake.lock
            return 1
          fi
        }
      ''))

      (lib.mkIf pkgs.stdenv.isLinux (lib.mkOrder 1300 ''
        sb() {
          local flake="$HOME/.config/nix-config"
          local host

          host="$(hostname)" || return $?
          nixos-rebuild build --flake "$flake#$host"
        }

        ssw() {
          local flake="$HOME/.config/nix-config"
          local host

          host="$(hostname)" || return $?
          sudo -H nixos-rebuild switch --flake "$flake#$host"
        }

        sup() {
          local flake="$HOME/.config/nix-config"
          local host
          local zsh_plugin_status=0
          local npm_update_status=0

          host="$(hostname)" || return $?

          nix flake update --flake "$flake" || return $?

          if sudo -H nixos-rebuild switch --flake "$flake#$host"; then
            if command -v antidote >/dev/null 2>&1; then
              echo "sup: updating zsh plugins"
              antidote update || zsh_plugin_status=$?
            fi

            __sup_update_npm_packages || npm_update_status=$?

            if ! git -C "$flake" diff --quiet -- flake.lock; then
              git -C "$flake" commit -m "flake.lock: update inputs" -- flake.lock
            fi

            echo "sup: collecting Nix garbage older than 30 days"
            sudo -H nix-collect-garbage --delete-older-than 30d || return $?
            if (( zsh_plugin_status != 0 )); then
              return "$zsh_plugin_status"
            fi
            return "$npm_update_status"
          else
            echo "sup: switch failed; restoring flake.lock" >&2
            git -C "$flake" restore flake.lock
            return 1
          fi
        }
      ''))

      (lib.mkOrder 1310 ''
        autoload -Uz add-zsh-hook
        typeset -g __auto_ls_last_pwd=""

        __auto_ls_on_prompt() {
          if [[ "$PWD" == "$__auto_ls_last_pwd" ]]; then
            return
          fi

          __auto_ls_last_pwd="$PWD"
          ls
        }

        add-zsh-hook precmd __auto_ls_on_prompt
      '')
    ];
  };

  programs.starship.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      vps = {
        HostName = "vps.emilioak.dev";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = "yes";
      };
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Shared Agent Skills location. Both Pi and Codex discover ~/.agents/skills.
  home.file.".agents/skills" = {
    source = dotfile "agents/skills";
    force = true;
  };
  home.file.".agents/.skill-lock.json" = {
    source = dotfile "agents/.skill-lock.json";
    force = true;
  };

  home.file.".codex/AGENTS.md".source = dotfile agentContextFile;
  home.file.".codex/config.toml".source = dotfile "codex/config.toml";
  home.file.".codex/rules/default.rules".source = dotfile "codex/rules/default.rules";
  # Codex-only system skills stay here; shared skills live in ~/.agents/skills.
  home.file.".codex/skills".source = dotfile "codex/skills";
  home.file.".claude/settings.json" = {
    source = dotfile "claude/settings.json";
    force = true;
  };
  home.file.".claude/hooks/herdr-agent-state.sh" = {
    source = dotfile "claude/hooks/herdr-agent-state.sh";
    force = true;
  };
  home.file.".pi/agent/settings.json".source = dotfile "pi/agent/settings.json";
  home.file.".pi/remote/config.json".source = dotfile "pi/remote/config.json";
  home.file.".pi/agent/AGENTS.md".source = dotfile agentContextFile;
  home.file.".pi/agent/extensions/herdr-agent-state.ts" = {
    source = dotfile "pi/agent/extensions/herdr-agent-state.ts";
    force = true;
  };
  home.file.".gitconfig".source = dotfile "gitconfig";
  xdg.configFile."herdr/config.toml" = {
    source = dotfile "herdr/config.toml";
    force = true;
  };
  xdg.configFile."herdr/rename-agent-launch.sh" = {
    source = dotfile "herdr/rename-agent-launch.sh";
    force = true;
  };
  xdg.configFile."herdr/rename-agent-prompt.sh" = {
    source = dotfile "herdr/rename-agent-prompt.sh";
    force = true;
  };
  xdg.configFile."git/ignore".source = dotfile "git/ignore";
  xdg.configFile."nvim".source = dotfile "nvim";
  xdg.configFile."starship.toml".source = dotfile "starship.toml";
  xdg.configFile."zsh/antidote-before-compinit.txt".source =
    dotfile "zsh/antidote-before-compinit.txt";
  xdg.configFile."zsh/antidote-after-compinit.txt".source =
    dotfile "zsh/antidote-after-compinit.txt";
}

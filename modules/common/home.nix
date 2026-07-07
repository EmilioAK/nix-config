{ config, lib, pkgs, username, ... }:
let
  flakeRoot = "${config.home.homeDirectory}/.config/nix-config";
  dotfile = path: config.lib.file.mkOutOfStoreSymlink "${flakeRoot}/dotfiles/${path}";
  zshConfigDir = "${config.xdg.configHome}/zsh";
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
    codex
    claude-code
    pi-coding-agent
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

          host="$(scutil --get LocalHostName)" || return $?

          nix flake update --flake "$flake" || return $?

          if sudo -H darwin-rebuild switch --flake "$flake#$host"; then
            if command -v antidote >/dev/null 2>&1; then
              echo "sup: updating zsh plugins"
              antidote update || zsh_plugin_status=$?
            fi

            if ! git -C "$flake" diff --quiet -- flake.lock; then
              git -C "$flake" commit -m "flake.lock: update inputs" -- flake.lock
            fi

            echo "sup: collecting Nix garbage older than 30 days"
            sudo -H nix-collect-garbage --delete-older-than 30d || return $?
            return "$zsh_plugin_status"
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

          host="$(hostname)" || return $?

          nix flake update --flake "$flake" || return $?

          if sudo -H nixos-rebuild switch --flake "$flake#$host"; then
            if command -v antidote >/dev/null 2>&1; then
              echo "sup: updating zsh plugins"
              antidote update || zsh_plugin_status=$?
            fi

            if ! git -C "$flake" diff --quiet -- flake.lock; then
              git -C "$flake" commit -m "flake.lock: update inputs" -- flake.lock
            fi

            echo "sup: collecting Nix garbage older than 30 days"
            sudo -H nix-collect-garbage --delete-older-than 30d || return $?
            return "$zsh_plugin_status"
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

  home.file.".codex/config.toml".source = dotfile "codex/config.toml";
  home.file.".codex/rules/default.rules".source = dotfile "codex/rules/default.rules";
  home.file.".codex/skills".source = dotfile "codex/skills";
  home.file.".gitconfig".source = dotfile "gitconfig";
  xdg.configFile."git/ignore".source = dotfile "git/ignore";
  xdg.configFile."nvim".source = dotfile "nvim";
  xdg.configFile."starship.toml".source = dotfile "starship.toml";
  xdg.configFile."zsh/antidote-before-compinit.txt".source =
    dotfile "zsh/antidote-before-compinit.txt";
  xdg.configFile."zsh/antidote-after-compinit.txt".source =
    dotfile "zsh/antidote-after-compinit.txt";
}

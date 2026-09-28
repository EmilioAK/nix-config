{ config, lib, pkgs, ... }:
let
  zshConfigDir = "${config.xdg.configHome}/zsh";

  # The rebuild helpers are identical across platforms apart from these two
  # commands, so define them once and interpolate.
  rebuild = if pkgs.stdenv.hostPlatform.isDarwin then "darwin-rebuild" else "nixos-rebuild";
  currentHostname =
    if pkgs.stdenv.hostPlatform.isDarwin then "scutil --get LocalHostName" else "hostname";

  rebuildFunctions = ''
    sb() {
      local flake="$HOME/.config/nix-config"
      local host

      host="$(${currentHostname})" || return $?
      ${rebuild} build --flake "$flake#$host"
    }

    ssw() {
      local flake="$HOME/.config/nix-config"
      local host

      host="$(${currentHostname})" || return $?
      sudo -H ${rebuild} switch --flake "$flake#$host"
    }

    sup() {
      local flake="$HOME/.config/nix-config"
      local host
      local zsh_plugin_status=0

      host="$(${currentHostname})" || return $?

      nix flake update --flake "$flake" || return $?

      if sudo -H ${rebuild} switch --flake "$flake#$host"; then
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
  '';
in {
  programs.zsh = {
    enable = true;
    enableCompletion = false;

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
        $HOME/.local/bin
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

      (lib.mkOrder 1300 rebuildFunctions)

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
}

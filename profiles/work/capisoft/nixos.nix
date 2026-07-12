{ pkgs, username, lib, ... }:
let
  netbirdPublicRoute = pkgs.writeShellScript "netbird-public-route" ''
    set -eu

    export PATH=${lib.makeBinPath [
      pkgs.gawk
      pkgs.gnugrep
      pkgs.iproute2
    ]}

    RULE_PREF="''${RULE_PREF:-100}"

    get_public_iface() {
      if [ -n "''${PUBLIC_IFACE:-}" ]; then
        printf '%s\n' "$PUBLIC_IFACE"
        return
      fi

      ip -4 route show default | awk '
        {
          for (i = 1; i <= NF; i++) {
            if ($i == "dev") {
              print $(i + 1)
              exit
            }
          }
        }
      '
    }

    get_public_ipv4() {
      public_iface="$(get_public_iface)"
      [ -n "$public_iface" ]
      ip -4 -o addr show dev "$public_iface" scope global | awk '{split($4, a, "/"); print a[1]; exit}'
    }

    get_public_ipv6() {
      public_iface="$(get_public_iface)"
      [ -n "$public_iface" ]
      ip -6 -o addr show dev "$public_iface" scope global | awk '{split($4, a, "/"); print a[1]; exit}'
    }

    rule_exists() {
      family="$1"
      public_ip="$2"
      ip "$family" rule show | grep -Fq "from ''${public_ip} lookup main"
    }

    add_rule() {
      family="$1"
      prefix="$2"
      public_ip="$3"
      [ -n "$public_ip" ] || return 0

      if ! rule_exists "$family" "$public_ip"; then
        ip "$family" rule add pref "$RULE_PREF" from "''${public_ip}/''${prefix}" table main
      fi
    }

    add_rules() {
      public_ipv4="$(get_public_ipv4)"
      [ -n "$public_ipv4" ]
      add_rule -4 32 "$public_ipv4"

      public_ipv6="$(get_public_ipv6 || true)"
      add_rule -6 128 "''${public_ipv6:-}"
    }

    del_rule() {
      family="$1"
      prefix="$2"
      public_ip="$3"
      [ -n "$public_ip" ] || return 0

      while rule_exists "$family" "$public_ip"; do
        ip "$family" rule del pref "$RULE_PREF" from "''${public_ip}/''${prefix}" table main || break
      done
    }

    del_rules() {
      public_ipv4="$(get_public_ipv4 || true)"
      del_rule -4 32 "''${public_ipv4:-}"

      public_ipv6="$(get_public_ipv6 || true)"
      del_rule -6 128 "''${public_ipv6:-}"
    }

    case "''${1:-up}" in
      up)
        add_rules
        ;;
      down)
        del_rules
        ;;
      status)
        {
          ip -4 rule show
          ip -6 rule show
        } | grep "^''${RULE_PREF}:" || true
        ;;
      *)
        echo "usage: $0 {up|down|status}" >&2
        exit 2
        ;;
    esac
  '';
in {
  environment.systemPackages = with pkgs; [
    awscli2
    docker-compose
    fastfetch
    fd
    fzf
    gitMinimal
    htop
    jq
    kubectl
    ncdu
    nodejs
    postgresql_16
    python312
    rancher
    redis
    ripgrep
    terraform
    tmux
    uv
    zellij
  ];

  networking.iproute2 = {
    enable = true;
    rttablesExtraConfig = ''
      7120 netbird
    '';
  };

  services.netbird = {
    enable = true;
    useRoutingFeatures = "client";
    clients.default.environment.NB_CONFIG =
      lib.mkForce "/var/lib/netbird/default.json";
  };

  systemd.services.netbird-public-route = {
    description = "Keep public IP sourced traffic off the NetBird exit node";
    after = [
      "network-online.target"
      "netbird.service"
    ];
    wants = [ "network-online.target" ];
    partOf = [ "netbird.service" ];
    wantedBy = [
      "multi-user.target"
      "netbird.service"
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${netbirdPublicRoute} up";
      ExecStop = "${netbirdPublicRoute} down";
    };
  };

  users.users.${username}.extraGroups = [ "docker" ];

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      data-root = "/mnt/data/docker";
    };
  };
}

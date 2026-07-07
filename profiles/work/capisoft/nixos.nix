{ pkgs, username, lib, ... }:
let
  netbirdPublicRoute = pkgs.writeShellScript "netbird-public-route" ''
    set -eu

    export PATH=${lib.makeBinPath [
      pkgs.gawk
      pkgs.gnugrep
      pkgs.iproute2
    ]}

    PUBLIC_IFACE="''${PUBLIC_IFACE:-eth0}"
    RULE_PREF="''${RULE_PREF:-100}"

    get_public_ipv4() {
      ip -4 -o addr show dev "$PUBLIC_IFACE" scope global | awk '{split($4, a, "/"); print a[1]; exit}'
    }

    rule_exists() {
      public_ip="$1"
      ip rule show | grep -Fq "from ''${public_ip} lookup main"
    }

    add_rule() {
      public_ip="$(get_public_ipv4)"
      [ -n "$public_ip" ]

      if ! rule_exists "$public_ip"; then
        ip rule add pref "$RULE_PREF" from "''${public_ip}/32" table main
      fi
    }

    del_rule() {
      public_ip="$(get_public_ipv4 || true)"
      [ -n "''${public_ip:-}" ] || exit 0

      while rule_exists "$public_ip"; do
        ip rule del pref "$RULE_PREF" from "''${public_ip}/32" table main || break
      done
    }

    case "''${1:-up}" in
      up)
        add_rule
        ;;
      down)
        del_rule
        ;;
      status)
        ip rule show | grep "^''${RULE_PREF}:" || true
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
    fish
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
    description = "Keep public IPv4 sourced traffic off the NetBird exit node";
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

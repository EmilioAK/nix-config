{ ... }: {
  # Self-hosted Remote Pi WebSocket relay for the mobile app / cross-PC mesh.
  # Caddy exposes it as https://vps.emilioak.dev and proxies to the container on
  # localhost only; the relay state lives on the persistent Hetzner volume.
  systemd.tmpfiles.rules = [
    "d /mnt/data/remote-pi-relay 0750 root root - -"
  ];

  virtualisation.oci-containers = {
    backend = "docker";
    containers.remote-pi-relay = {
      image = "jacobmoura7/remote-pi-relay:latest";
      autoStart = true;
      ports = [ "127.0.0.1:3000:3000" ];
      volumes = [ "/mnt/data/remote-pi-relay:/data" ];
      environment = {
        REMOTEPI_RELAY_PORT = "3000";
        REMOTEPI_MESH_DB_PATH = "/data/mesh.db";
        RUST_LOG = "info";
      };
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."vps.emilioak.dev".extraConfig = ''
      reverse_proxy 127.0.0.1:3000
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}

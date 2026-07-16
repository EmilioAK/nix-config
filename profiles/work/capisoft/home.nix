{ pkgs, ... }:
{
  # Portable Capisoft development tooling shared by the Mac and VPS. Runtime
  # services such as the Docker daemon and NetBird remain platform-specific.
  home.packages = with pkgs; [
    awscli2
    docker-client
    docker-compose
    htop
    jq
    kubectl
    ncdu
    postgresql_16
    python312
    rancher
    redis
    terraform
    uv
    zellij
  ];

  programs.ssh.settings."bitbucket.org" = {
    IdentityFile = "~/.ssh/id_ed25519_bitbucket";
    IdentitiesOnly = "yes";
  };
}

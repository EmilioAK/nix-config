# Capisoft Profile

This profile contains Capisoft-specific NixOS tooling for the VPS, including
AWS, Kubernetes, Rancher, Docker, and NetBird.

## NetBird

NetBird is installed by the Capisoft NixOS module, but authentication is local
machine state. On a fresh VPS, enroll it after install:

```sh
sudo netbird up
```

The module keeps normal outbound traffic on NetBird while public IPv4 sourced
traffic uses the Hetzner route. Once NetBird is connected, verify both paths:

```sh
systemctl status netbird.service netbird-public-route.service
ip rule show
ip route get 1.1.1.1
ip route get 1.1.1.1 from "$(ip -4 -o addr show dev eth0 scope global | awk '{split($4, a, "/"); print a[1]; exit}')"
```

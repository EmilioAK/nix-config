# nix-vps migration notes

Target host: `nix-vps`.

This machine is intended to be installed with `nixos-anywhere` from this flake.
The disko config wipes only `/dev/sda`; the Hetzner data volume `/dev/sdb` is
mounted at `/mnt/data` by UUID.

## Safety state

A provider snapshot was taken before the migration.

A local migration backup was created on the data volume at:

```text
/mnt/data/nixos-migration-backup/20260707-211336
```

That backup contains:

- `user-secrets.tar.gz`
- `system-state.tar.gz`
- `SHA256SUMS`
- manifests/logs

It deliberately does not contain Pi (`~/.pi`, `~/.local/share/pi-node`) or the
old zsh startup files (`~/.zshrc`, `~/.zprofile`).

## State to seed before first boot / first service start

For continuity, restore these from `system-state.tar.gz` into the install target
before the new system first starts services:

```text
/etc/ssh/ssh_host_*
/var/lib/netbird
```

This keeps SSH host keys stable and lets NetBird reconnect as the existing peer.

The backup also contains reference copies of the old NetBird route fix:

```text
/etc/systemd/system/netbird-public-route.service
/usr/local/sbin/netbird-public-route
```

The NixOS work profile declares the replacement service/script, so these files
are for reference/rollback rather than manual installation.

## Suggested extra-files preparation

`nixos-anywhere --extra-files` expects a directory on the machine that runs
`nixos-anywhere` (usually the laptop), not a path on the target VPS.

Before wiping the VPS, copy the system-state archive to the installer machine.
The backup directory is root-only on the VPS, so read it through passwordless
sudo instead of plain `scp`:

```sh
ssh emilio@<current-vps> \
  'sudo cat /mnt/data/nixos-migration-backup/20260707-211336/system-state.tar.gz' \
  > system-state.tar.gz
```

On the installer machine, prepare a local staging directory outside git. Extract
as your normal user so the `nixos-anywhere` process can read the files; they are
installed as root-owned files on the target.

```sh
stage=$PWD/nix-vps-extra-files
rm -rf "$stage"
mkdir -p "$stage"
tar -C "$stage" -xzf system-state.tar.gz \
  etc/ssh/ssh_host_ecdsa_key \
  etc/ssh/ssh_host_ecdsa_key.pub \
  etc/ssh/ssh_host_ed25519_key \
  etc/ssh/ssh_host_ed25519_key.pub \
  etc/ssh/ssh_host_rsa_key \
  etc/ssh/ssh_host_rsa_key.pub \
  var/lib/netbird
```

Then pass that local staging directory to `nixos-anywhere`:

```sh
nix run github:nix-community/nixos-anywhere -- \
  --extra-files "$stage" \
  --flake "path:$PWD#nix-vps" \
  emilio@<current-vps>
```

## Mosh

Mosh is expected to work after the NixOS switch. General NixOS server config
installs `mosh` and opens UDP ports `60000-61000`; this is intentionally not
part of the Capisoft work profile.

## After first boot

Clone this repo to the path expected by Home Manager:

```sh
mkdir -p ~/.config
git clone https://github.com/EmilioAK/nix-config ~/.config/nix-config
cd ~/.config/nix-config
sudo nixos-rebuild switch --flake "path:$PWD#nix-vps"
```

Then selectively restore user secrets/state from `user-secrets.tar.gz`. Avoid
blindly overwriting Home Manager-managed files; restore auth/state files as
needed.

Important checks:

```sh
hostname
findmnt /mnt/data
systemctl status sshd
systemctl status netbird
netbird status
mosh emilio@<host>
tmux new -A -s main
```

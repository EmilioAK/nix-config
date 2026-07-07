# systems

Personal system config. The active machine is managed with nix-darwin,
home-manager, and Homebrew; NixOS host scaffolding lives alongside it for the
future VPS. Inputs track rolling release (nixpkgs-unstable, nix-darwin master,
home-manager master), and `sup` commits `flake.lock` so every machine
reproduces a known-good state.

## Setup A New Mac

1. Install Nix: <https://nixos.org/download/>
2. Install Homebrew: <https://brew.sh/>
3. Sign in to the App Store (required for the `masApps` in
   `modules/darwin/homebrew.nix`).
4. Clone the repo. It must live at `~/.config/nix-config` because Home Manager
   links dotfiles from that path:

   ```sh
   mkdir -p ~/.config
   git clone https://github.com/EmilioAK/nix-config ~/.config/nix-config
   cd ~/.config/nix-config
   git remote set-url --push origin git@github.com:EmilioAK/nix-config.git
   ```

5. Create this Mac's host file if it does not already exist:

   ```sh
   host="$(scutil --get LocalHostName)"
   system="$(case "$(uname -m)" in arm64) echo aarch64-darwin ;; *) echo x86_64-darwin ;; esac)"

   cat > "hosts/$host.nix" <<EOF
   {
     platform = "darwin";
     username = "$(id -un)";
     system = "$system";
     extraSystemModules = [ ];
     extraHomeModules = [ ];
   }
   EOF
   ```

6. Run the first switch:

   ```sh
   sudo -H nix --extra-experimental-features "nix-command flakes" \
     run github:nix-darwin/nix-darwin#darwin-rebuild -- \
     switch --flake "path:$PWD#$host"
   ```

   `path:` is intentional for the first switch because the new host file may not
   be committed yet.

7. Open a fresh shell so the Nix-managed tools are on `PATH`, then authenticate
   GitHub and install the GitHub token for Nix:

   ```sh
   scripts/install-github-nix-token
   ssw
   ```

   The script uses `gh auth login` if needed. That handles GitHub
   authentication for pushing over SSH, then writes the GitHub token to
   `~/.config/nix/github-access-token.conf` so Nix flake fetches can use
   authenticated GitHub requests. The extra `ssw` activates the system/root Nix
   config after the token file exists.

8. Commit and push the new host entry:

   ```sh
   git add "hosts/$host.nix"
   git commit -m "hosts: add $host"
   git push
   ```

## Setup The Hetzner VPS

The `nix-vps` host is a NixOS system installed from this repo with
`nixos-anywhere`. Start from any fresh Hetzner VPS image or rescue system where
SSH works as `root` or as a user with passwordless sudo.

From this repo on your local machine, choose the install target:

```sh
cd ~/.config/nix-config
target=root@<vps-ip>
```

Confirm the remote disk layout before installing. The current config wipes
`/dev/sda`; the attached data volume, when present, is mounted separately at
`/mnt/data` by UUID.

```sh
ssh "$target" 'lsblk -f; echo; findmnt -R /mnt || true'
```

Verify the local config:

```sh
nix eval --no-write-lock-file \
  "path:$PWD#nixosConfigurations.nix-vps.config.system.build.toplevel.drvPath"
nix build --dry-run --no-write-lock-file \
  "path:$PWD#nixosConfigurations.nix-vps.config.system.build.toplevel"
```

Install NixOS:

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake "path:$PWD#nix-vps" \
  "$target"
```

After the reboot, SSH in as `emilio`, clone the repo to its expected path, and
switch once from the checked-out repo:

```sh
ssh emilio@<vps-ip>
mkdir -p ~/.config
git clone https://github.com/EmilioAK/nix-config ~/.config/nix-config
cd ~/.config/nix-config
sudo nixos-rebuild switch --flake "path:$PWD#nix-vps"
```

## Daily use

Use the zsh helpers from the Home Manager zsh config for normal system work:

- `sb`: build the current host without switching.
- `ssw`: switch the current host without updating inputs.
- `sup`: update inputs, switch, commit `flake.lock`, and collect old garbage.

`sup` does the following:

1. Updates flake inputs with `nix flake update`.
2. Rebuilds the current host with `sudo -H darwin-rebuild switch`.
3. Lets nix-darwin activation handle Homebrew updates, upgrades, and cleanup
   from `modules/darwin/homebrew.nix`.
4. Updates zsh plugins with Antidote.
5. Commits `flake.lock` if the rebuild succeeds and the lock changed.
6. Deletes Nix garbage older than 30 days with
   `sudo -H nix-collect-garbage --delete-older-than 30d`.

If the rebuild fails, `sup` restores `flake.lock` and skips cleanup. The 30-day
GC window keeps recent rollback/build outputs around while preventing the Nix
store from growing forever. Nix is configured with `auto-optimise-store`, so new
store paths are deduplicated as they are added. To deduplicate paths that already
existed before enabling that setting, run `sudo nix store optimise` once.

Zsh plugins are loaded by Antidote from `dotfiles/zsh/antidote-*.txt`. The
manager and bundle list are Nix/Home Manager-managed; cloned plugin checkouts
live in Antidote's cache and are updated by `sup`.

## Adding a machine

For another Mac, follow the setup steps above. Work profiles are configured
globally in `flake.nix`, with platform-specific pieces under `profiles/`.

## GitHub token

`scripts/install-github-nix-token` takes the `gh` CLI token, writes it to
`~/.config/nix/github-access-token.conf`, and `!include`s it from the user Nix
config. The nix-darwin system config includes the same token file for root-run
Nix commands after the next switch. The token file is local-only: it is never
committed and never copied into the Nix store. Re-run the script after
re-authenticating `gh`, since `gh auth login`/`refresh` rotates the token.

## Notes / gotchas

- The repo must live at `~/.config/nix-config`.
- First switch: if Nix's installer left an unmanaged `/etc/nix/nix.conf` (or
  `/etc/zshrc`, etc.), activation stops and prints `mv` instructions; follow
  them and re-run the first switch command.
- SSH keys: `gh auth login` can generate and upload the GitHub key when you run
  the token script. The Bitbucket work key
  (`~/.ssh/id_ed25519_bitbucket`) is provisioned manually.
- Rolling release: roll back a bad update with
  `git -C ~/.config/nix-config checkout <good-commit> -- flake.lock` followed by
  `sudo -H darwin-rebuild switch --flake ~/.config/nix-config#$(scutil --get LocalHostName)`.

## Not tracked

- Control Center layout — macOS stores it in an opaque format with no supported
  declarative knob.
- Shortcuts automations — device-local, not synced via iCloud, and Nix has no
  hook into the Shortcuts database.

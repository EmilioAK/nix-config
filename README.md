# systems

Personal system config. The Mac is managed with nix-darwin, Home Manager, and
Homebrew; the VPS is managed with NixOS and Home Manager from the same flake.
Inputs track rolling release (nixpkgs-unstable, nix-darwin master, Home Manager
master), and `sup` commits `flake.lock` so every machine reproduces a known-good
state.

Layout:

- `flake.nix` discovers hosts from `hosts/*.nix`; each host file declares its
  platform, system, and the profiles it selects.
- `modules/common` applies everywhere, `modules/darwin` and `modules/nixos` are
  platform-specific.
- `profiles/` holds opt-in bundles (`capisoft`, `thesis`) that contribute
  Home Manager and system modules to the hosts that name them.
- `dotfiles/` is linked into `$HOME` out of the Nix store, so tools that
  rewrite their own config keep working.

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
     profiles = [ "capisoft" "thesis" ];
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

8. Restore the local-only Capisoft state. Copy it from the VPS over an encrypted
   connection or recreate it with fresh logins; none of it belongs in git:

   - `~/.agents/secrets/`
   - `~/.ssh/id_ed25519_bitbucket` and its public key
   - `~/.aws/config`
   - `~/.kube/config` plus any separate kubeconfig files you still use

   Use mode `0700` for `~/.agents/secrets` and `0600` for private SSH keys. Do
   not copy AWS login/SSO caches, GitHub token files, `known_hosts`, or the Nix
   store. Authenticate GitHub with the script above, enroll NetBird as a new
   machine, refresh AWS/Rancher/Kubernetes credentials, and sign in to Docker,
   Codex, and Claude as needed.

9. Launch Docker Desktop once and verify the Capisoft environment:

   ```sh
   open -a Docker
   docker info
   aws configure list-profiles
   kubectl config get-contexts

   for command in aws docker kubectl psql rancher redis-cli terraform uv; do
     command -v "$command" || exit 1
   done
   ```

10. Clone or transfer the work repositories; Nix installs the development
    environment but deliberately does not manage project checkouts.

11. Commit and push the new host entry:

   ```sh
   git add "hosts/$host.nix"
   git commit -m "hosts: add $host"
   git push
   ```

## Setup The Hetzner VPS

The `nix-vps` host is a NixOS system installed from this repo with
`nixos-anywhere`. Start from a Hetzner rescue system where SSH works as `root`.

1. In the Hetzner Cloud Console, enable Rescue for the server, then reboot it.

2. From this repo on your local machine, choose the install target:

   ```sh
   cd ~/.config/nix-config
   target=root@vps.emilioak.dev
   ```

3. Confirm the remote disk layout before installing. The current config wipes
   only `/dev/sda`; the attached data volume is `/dev/sdb` and is mounted
   separately at `/mnt/data` by UUID.

   ```sh
   ssh "$target" 'lsblk -f; echo; findmnt -R /mnt || true'
   ```

4. Verify the local config:

   ```sh
   nix eval --no-write-lock-file \
     "path:$PWD#nixosConfigurations.nix-vps.config.system.build.toplevel.drvPath"
   nix build --dry-run --no-write-lock-file \
     "path:$PWD#nixosConfigurations.nix-vps.config.system.build.toplevel"
   ```

5. Install NixOS:

   ```sh
   nix run github:nix-community/nixos-anywhere -- \
     --build-on remote \
     --flake "path:$PWD#nix-vps" \
     --target-host "$target"
   ```

6. After the reboot, SSH in as `emilio` and clone the repo to the path Home
   Manager expects. The repo must live at `~/.config/nix-config` because
   dotfiles are linked from that path.

   ```sh
   ssh vps
   mkdir -p ~/.config
   git clone https://github.com/EmilioAK/nix-config ~/.config/nix-config
   cd ~/.config/nix-config
   git remote set-url --push origin git@github.com:EmilioAK/nix-config.git
   ```

7. Run the first switch from the checked-out repo, then open a fresh shell:

   ```sh
   sudo nixos-rebuild switch --flake .#nix-vps
   exec zsh -l
   ```

8. Check the expected services and mounts:

   ```sh
   hostname
   findmnt /mnt/data
   systemctl is-active sshd
   systemctl is-active netbird
   netbird status
   ```

## Daily use

Use the zsh helpers from the Home Manager zsh config for normal system work:

- `sb`: build the current host without switching.
- `ssw`: switch the current host without updating inputs.
- `sup`: update inputs, switch, commit `flake.lock`, and collect old garbage.

On macOS the helpers use `darwin-rebuild` and the host name from
`scutil --get LocalHostName`. On NixOS they use `nixos-rebuild` and the host
name from `hostname`; for the VPS that means `.#nix-vps`.

`sup` does the following:

1. Updates flake inputs with `nix flake update`.
2. Rebuilds the current host with `sudo -H darwin-rebuild switch` on macOS or
   `sudo -H nixos-rebuild switch` on NixOS.
3. On macOS, lets nix-darwin activation handle Homebrew updates, upgrades, and
   cleanup from `modules/darwin/homebrew.nix`.
4. Updates zsh plugins with Antidote.
5. Commits `flake.lock` if the rebuild succeeds and the lock changed.
6. Deletes Nix garbage older than 30 days with
   `sudo -H nix-collect-garbage --delete-older-than 30d`.

If the rebuild fails, `sup` restores `flake.lock` and skips cleanup. If a
post-switch updater fails, `sup` still runs cleanup but returns a non-zero status.
The 30-day GC window keeps recent rollback/build outputs around while preventing
the Nix store from growing forever. Nix is configured with `auto-optimise-store`,
so new store paths are deduplicated as they are added. To deduplicate paths that
already existed before enabling that setting, run `sudo nix store optimise` once.

Zsh plugins are loaded by Antidote from `dotfiles/zsh/antidote-*.txt`. The
manager and bundle list are Nix/Home Manager-managed; cloned plugin checkouts
live in Antidote's cache and are updated by `sup`.

The Mac uses the ChatGPT (including Codex) and Claude desktop apps, installed
through the `chatgpt` and `claude` casks in `modules/darwin/homebrew.nix`.
It does not install the standalone `codex`, `claude-code`, or `herdr` packages.
The headless VPS keeps those packages and the Herdr configuration/hooks in
`modules/nixos/home.nix`; the `herdr` flake input is still needed there.

App and agent settings remain wired up in `modules/common/agents.nix`:

- `dotfiles/agents/AGENTS.default.md` is the global instruction file. A host
  gets its own file only if `agentContextByHost` names one; everything else
  falls back to the default.
- Codex config is per-host: `dotfiles/codex/config.<host>.toml`. The desktop
  app also uses `~/.codex/config.toml`, instructions, and rules.
- Claude desktop Code sessions share `~/.claude/settings.json` with the CLI.
  The Mac uses `dotfiles/claude/settings.mac.json`, without Herdr hooks; the
  VPS keeps `dotfiles/claude/settings.json` and its terminal hooks.
- Settings use writable out-of-store symlinks because the apps and agents
  update their own configuration. Claude settings use a direct link so its
  atomic writes do not target a read-only Nix store directory.
- Secrets live outside git at `~/.agents/secrets`.

Use `sb` to build the Mac changes before applying them with `ssw`. Check the
Homebrew cask list first: activation also upgrades apps and runs
`cleanup = "zap"`, which can remove apps absent from the declared configuration.

## Adding a machine

For another Mac, follow the setup steps above, then list the named profiles the
host should load. Profiles remain separate under `profiles/`; a host receives
only the modules it explicitly selects:

```nix
profiles = [ "capisoft" ];
```

The available profile names are declared in `flake.nix`.

## Capisoft development environment

The portable Capisoft CLI stack is declared in
`profiles/work/capisoft/home.nix` and is installed on every host selecting the
`capisoft` profile. It includes AWS CLI, the Docker client and Compose,
Kubernetes and Rancher clients, Terraform, PostgreSQL and Redis clients, Python,
`uv`, and supporting terminal tools.

Platform runtimes stay separate: NixOS owns the VPS Docker and NetBird services,
while macOS installs Docker Desktop and the NetBird app through Homebrew. Their
authentication and machine enrollment remain local state.

## GitHub token

`scripts/install-github-nix-token` takes the `gh` CLI token, writes it to
`~/.config/nix/github-access-token.conf`, and `!include`s it from the user Nix
config. The system config includes the same token file for root-run Nix commands
after the next switch. The token file is local-only: it is never
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

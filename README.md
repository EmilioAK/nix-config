# nix-darwin

Personal macOS system config: nix-darwin + home-manager + Homebrew. Inputs track
rolling release (nixpkgs-unstable, nix-darwin master, home-manager master), and
`drs` commits `flake.lock` so every machine reproduces a known-good state.

## Setup (new machine)

1. Install Nix: <https://nixos.org/download/>
2. Install Homebrew: <https://brew.sh/>
3. Sign in to the App Store (required for the `masApps` in `homebrew.nix`).
4. Clone the repo (it must live at `~/.config/nix-darwin`) and run the bootstrap:

   ```sh
   mkdir -p ~/.config
   git clone https://github.com/EmilioAK/nix-darwin-config ~/.config/nix-darwin
   cd ~/.config/nix-darwin
   git remote set-url --push origin git@github.com:EmilioAK/nix-darwin-config.git
   scripts/bootstrap
   ```

   `scripts/bootstrap` will:
   - create `hosts/<LocalHostName>.nix` for this machine (if missing),
   - install `gh` and store a GitHub API token for Nix (see below),
   - run the first `darwin-rebuild switch`,
   - commit the new host file.

5. Push the new host entry: `git push`.

## Daily use

Run `drs` from fish for the normal update/rebuild/maintenance flow. It is
defined in `dotfiles/fish/functions/drs.fish` and does the following:

1. Updates flake inputs with `nix flake update`.
2. Rebuilds the current host with `sudo darwin-rebuild switch`.
3. Lets nix-darwin activation handle Homebrew updates, upgrades, and cleanup
   from `homebrew.nix`.
4. Commits `flake.lock` if the rebuild succeeds and the lock changed.
5. Deletes Nix garbage older than 30 days with
   `sudo nix-collect-garbage --delete-older-than 30d`.

If the rebuild fails, `drs` restores `flake.lock` and skips cleanup. The 30-day
GC window keeps recent rollback/build outputs around while preventing the Nix
store from growing forever. Nix is configured with `auto-optimise-store`, so new
store paths are deduplicated as they are added. To deduplicate paths that already
existed before enabling that setting, run `sudo nix store optimise` once.

## Adding a machine

Run `scripts/bootstrap` on the new machine; it creates and commits a
`hosts/<LocalHostName>.nix` entry. Edit that file to set `workModules` if needed
— paths are relative to `hosts/`, e.g. `[ ../work/capisoft.nix ]`.

## GitHub token

`scripts/install-github-nix-token` takes the `gh` CLI token, writes it to
`~/.config/nix/github-access-token.conf`, and `!include`s it from both the user
and system Nix config (so user- and root-run flake fetches are authenticated and
don't hit the unauthenticated rate limit). The token file is local-only: it is
never committed and never copied into the Nix store. Re-run the script after
re-authenticating `gh`, since `gh auth login`/`refresh` rotates the token.

## Notes / gotchas

- The repo must live at `~/.config/nix-darwin`.
- First switch: if Nix's installer left an unmanaged `/etc/nix/nix.conf` (or
  `/etc/zshrc`, etc.), activation stops and prints `mv` instructions — follow
  them and re-run `scripts/bootstrap`.
- SSH keys: `gh auth login` (triggered by the token script) can generate and
  upload the GitHub key. The Bitbucket work key
  (`~/.ssh/id_ed25519_bitbucket`) is provisioned manually.
- Rolling release: roll back a bad update with
  `git -C ~/.config/nix-darwin checkout <good-commit> -- flake.lock` followed by
  `sudo darwin-rebuild switch --flake ~/.config/nix-darwin#$(scutil --get LocalHostName)`.

## Not tracked

- Control Center layout — macOS stores it in an opaque format with no supported
  declarative knob.
- Shortcuts automations — device-local, not synced via iCloud, and Nix has no
  hook into the Shortcuts database.

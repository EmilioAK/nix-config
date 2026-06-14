function drs --description "Update flake inputs, rebuild, and commit flake.lock on success"
    set -l flake "$HOME/.config/nix-darwin"
    set -l host (scutil --get LocalHostName)

    nix flake update --flake "$flake"
    or return $status

    if sudo darwin-rebuild switch --flake "$flake#$host"
        if not git -C "$flake" diff --quiet -- flake.lock
            git -C "$flake" commit -m "flake.lock: update inputs" -- flake.lock
        end
    else
        echo "drs: switch failed — restoring flake.lock" >&2
        git -C "$flake" restore flake.lock
        return 1
    end
end

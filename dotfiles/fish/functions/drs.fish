function drs --description "Update flake inputs, rebuild, commit flake.lock, and collect old Nix garbage"
    set -l flake "$HOME/.config/nix-darwin"
    set -l host (scutil --get LocalHostName)

    nix flake update --flake "$flake"
    or return $status

    if sudo -H darwin-rebuild switch --flake "$flake#$host"
        if not git -C "$flake" diff --quiet -- flake.lock
            git -C "$flake" commit -m "flake.lock: update inputs" -- flake.lock
        end

        echo "drs: collecting Nix garbage older than 30 days"
        sudo nix-collect-garbage --delete-older-than 30d
        or return $status
    else
        echo "drs: switch failed — restoring flake.lock" >&2
        git -C "$flake" restore flake.lock
        return 1
    end
end

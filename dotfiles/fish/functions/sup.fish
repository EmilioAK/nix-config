function sup --description "Update flake inputs, switch, commit flake.lock, and collect old Nix garbage"
    set -l flake "$HOME/.config/nix-darwin"
    set -l host (scutil --get LocalHostName)

    nix flake update --flake "$flake"
    or return $status

    if sudo -H darwin-rebuild switch --flake "$flake#$host"
        if not git -C "$flake" diff --quiet -- flake.lock
            git -C "$flake" commit -m "flake.lock: update inputs" -- flake.lock
        end

        echo "sup: collecting Nix garbage older than 30 days"
        sudo -H nix-collect-garbage --delete-older-than 30d
        or return $status
    else
        echo "sup: switch failed; restoring flake.lock" >&2
        git -C "$flake" restore flake.lock
        return 1
    end
end

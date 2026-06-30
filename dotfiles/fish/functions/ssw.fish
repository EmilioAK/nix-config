function ssw --description "Switch the current nix-darwin host without updating inputs"
    set -l flake "$HOME/.config/nix-config"
    set -l host (scutil --get LocalHostName)

    sudo -H darwin-rebuild switch --flake "$flake#$host"
end

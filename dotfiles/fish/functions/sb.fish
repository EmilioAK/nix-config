function sb --description "Build the current nix-darwin host without switching"
    set -l flake "$HOME/.config/nix-config"
    set -l host (scutil --get LocalHostName)

    darwin-rebuild build --flake "$flake#$host"
end

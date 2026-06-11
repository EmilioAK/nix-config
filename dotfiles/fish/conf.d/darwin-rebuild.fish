abbr --add --global drs 'cd $HOME/.config/nix-darwin && nix flake update && sudo darwin-rebuild switch --flake path:$HOME/.config/nix-darwin#default'

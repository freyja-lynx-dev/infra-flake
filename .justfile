# just is a command runner, Justfile is very similar to Makefile, but simpler.
############################################################################
#
#  Common recipes
#
############################################################################

# List all recipes
_default:
    @printf '\033[1;36minfra-flake recipes\033[0m\n\n'
    @printf '\033[1;33mUsage:\033[0m just <recipe> [args...]\n\n'
    @just --list --list-heading $'Available recipes:\n\n'

# Update flake inputs
[group('flake')]
update *inputs:
    nix flake update {{ inputs }} --commit-lock-file

# Update all nixpkgs inputs
[group('flake')]
update-nixpkgs: (update "nixpkgs")

# Format and check the flake
[group('flake')]
check:
    nix fmt
    nix flake check

# Build a NixOS host configuration
[group('nixos')]
build host="frank":
    nix build .#nixosConfigurations.{{ host }}.config.system.build.toplevel

############################################################################
#
#  Secrets (sops + age)
#
############################################################################

# Derive this machine's age private key from its ssh ed25519 key, install
# at ~/.config/sops/age/keys.txt. Run once per machine.
[group('secrets')]
sops-bootstrap:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -f ~/.config/sops/age/keys.txt ]]; then
        echo "~/.config/sops/age/keys.txt already exists; skipping."
        exit 0
    fi
    mkdir -p ~/.config/sops/age
    ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
    chmod 600 ~/.config/sops/age/keys.txt
    echo "wrote ~/.config/sops/age/keys.txt"
    echo "this machine's age recipient (must be in .sops.yaml):"
    ssh-to-age -i ~/.ssh/id_ed25519.pub

# Edit a sops-encrypted secrets file. Usage: just sops-edit <file>.yaml
[group('secrets')]
[positional-arguments]
sops-edit FILE:
    #!/usr/bin/env bash
    set -euo pipefail
    case "$1" in
        secrets/*) sops "$1" ;;
        *) sops "secrets/$1" ;;
    esac

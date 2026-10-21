# Work in infra-flake

`infra-flake` configures NixOS hosts using the dendritic `flake-parts` + `import-tree` pattern inspired by `devon-systems/hoenn`.

- Keep host-specific state in `nix/hosts/nixos/<host>/`.
- Put shared feature modules in `nix/modules/<feature>/`.
- Cross-host defaults live in `nix/modules/default/`.
- `flake.nix` automatically imports all Nix files under `nix/`.

## Check a change

Run `nix fmt` and `nix flake check` before committing. Build each host output affected by the change:

```sh
nix build .#nixosConfigurations.frank.config.system.build.toplevel
```

## Commit messages

Use scoped Conventional Commits: `fix(<scope>): <description>` for fixes and `feat(<scope>): <description>` for new features.

## Keep secrets and local backups out of Git

Do not commit decrypted secrets, private keys, or OPNsense XML backups (`*.xml`).

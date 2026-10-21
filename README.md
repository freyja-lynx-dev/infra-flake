# infra-flake

Declarative NixOS infrastructure flake structured after [devon-systems/hoenn](https://github.com/devon-systems/hoenn), using `flake-parts` and `import-tree` for modular, extensible multi-host configurations.

## Configurations

| Host                                       | Role                       | Platform | Flake output                |
| ------------------------------------------ | -------------------------- | -------- | --------------------------- |
| [`frank`](nix/hosts/nixos/frank/README.md) | Edge router (`lynxdomain`) | NixOS    | `nixosConfigurations.frank` |

## Repository Layout

```text
nix/
├── hosts/nixos/       Per-host configuration and hardware state
├── modules/           Shared feature modules (router, default platform settings)
├── devShells.nix      Development tools
├── overlays.nix       Shared package overlays
└── treefmt.nix        Formatting and linting configuration
```

`flake.nix` recursively imports all Nix files under `nix/` via `import-tree`. Each file declares or extends a `flake-parts` module or `flake.nixosModules.<name>`, so adding new hosts or feature modules requires no central import list updates.

## Adding a New Host

Create a directory under `nix/hosts/nixos/<hostname>/` with:

- `default.nix`: defines `config.flake.nixosConfigurations.<hostname>` and imports `self.nixosModules.default`, `self.nixosModules.<hostname>`, and any feature modules.
- Host-specific aspect files (`hostname.nix`, `nixpkgs.nix`, `state-version.nix`, `disko.nix`, etc.) contributing to `flake.nixosModules.<hostname>`.

## Working Locally

Enter the development shell with `nix develop` (or `direnv allow`):

```sh
nix fmt
nix flake check
nix build .#nixosConfigurations.frank.config.system.build.toplevel
```

## Validating the Router in a VM Lab

Run the automated 3-node QEMU/KVM integration test (`isp` <-> `frank` <-> `client`) defined in [`nix/router-test.nix`](nix/router-test.nix):

```sh
nix build -L .#router-test
# or via just:
just test-router
```

To drop into an interactive test driver with all three VMs (`isp`, `frank`, `client`) for manual experimentation:

```sh
just test-router-interactive
# Inside the driver REPL:
# >>> start_all()
# >>> frank.succeed("nft list ruleset")
```

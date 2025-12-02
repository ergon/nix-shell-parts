# nix-shell-parts

> [!IMPORTANT]
> This repository is in its early stages and not yet stable.

`nix-shell-parts` is a lightweight kickstarter for adding Nix development and deployment shells to a project without needing to know much about Nix, flakes and how to structure a project upfront.
It provides a buffet of reusable [Flake Parts](https://flake.parts/) modules and shell modules (under `perSystem.shellModules`) for common needs like devshells, formatting, and git hooks.
You have all options available but nothing is enabled until you turn it on, with only a few sensible defaults set (mainly `system`).

## Getting started

### Prerequisites

- [Nix](https://nix.dev/install-nix) with [Flakes enabled](https://nix.dev/manual/nix/2.28/development/experimental-features)

### Initial setup

#### Start with a template

Standard template (uses this repo as an input):

```bash
nix flake init -t github:ergon/nix-shell-parts?ref=v1
````

Vendored template (copies all modules into your repo):

```bash
nix flake init -t github:ergon/nix-shell-parts?ref=v1#vendored
```

**When to use which?**

- **Standard template**: normal flake dependency, easy upgrades by updating your flake input.
- **Vendored template**: everything lives in your repo, but you must manually pull updates later.

### Add to an existing flake

See [`templates/nix-shell-parts/flake.nix`](templates/nix-shell-parts/flake.nix) for a minimal example.

## Usage

All modules are already exported by this flake, so you do not need to import anything manually. You simply enable and configure the pieces you want through the module system, and leave the rest off. If you want to see concrete setups, the [templates directory contains minimal working examples](.md) to copy from.

## Documentation

The documentation including all options are published at: [https://ergon.github.io/nix-shell-parts/](https://ergon.github.io/nix-shell-parts/)

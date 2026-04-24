# nix-shell-parts

> This project is actively developed.
> Some APIs may change.

`nix-shell-parts` is a lightweight collection of modules to kickstart Nix (development) shells.
Built on [flake-parts](https://flake.parts/), it lets you declaratively configure formatting, git hooks, language tooling, and more.

## Why nix-shell-parts

Setting up a `devShell` with language tooling, formatting, git hooks and helper scripts requires a lot of Nix boilerplate.
Flakes and the module system provide the right foundations (version pinning, declarative configuration), but the glue code is still on you.

nix-shell-parts provides reusable modules that handle this glue code:

- **Opt-in**: every module is optional.
  Pick what you need today, add more as your project grows.
  The essentials are covered, but nothing is forced on you.
- **Native flake integration**: works with [flakes](https://nix.dev/concepts/flakes) directly.
  Standard `nix develop`, pure evaluation, no `--impure` flag needed.
- **Lightweight and extensible**: uses just the module system you already know.
  Easy to add your own modules.
- **Built on [flake-parts](https://flake.parts/)**: integrates into your flake as a module.

The goal is to be simple enough to adopt without deep Nix knowledge, and flexible enough for expert use cases.

## Getting started

### Prerequisites

- [Nix](https://nix.dev/install-nix) with [flakes enabled](https://nix.dev/manual/nix/latest/development/experimental-features)

### Without an existing flake

```bash
nix flake init -t github:ergon/nix-shell-parts?ref=v1
nix develop
```

This creates a `flake.nix` and configuration files under `./nix/`.
Edit those to configure your shell.

### Add to an existing flake

See [`templates/nix-shell-parts/flake.nix`](templates/nix-shell-parts/flake.nix) for a minimal example.

### Example configuration

A shell with treefmt (formatting) and a pre-commit hook:

```nix
# ./nix/devshell.nix
{pkgs, ...}: {
  treefmt.enable = true;
  treefmt.pre-commit-hook = true;
  treefmt.programs.alejandra.enable = true;
  treefmt.programs.prettier.enable = true;

  packages = [
    pkgs.nodejs_24
    pkgs.curl
  ];
}
```

## Documentation

The documentation including all options are published at: [https://ergon.github.io/nix-shell-parts/](https://ergon.github.io/nix-shell-parts/)

## Feedback

Feedback is very welcome. [Open an issue](https://github.com/ergon/nix-shell-parts/issues) with first impressions, questions, or things you find missing.

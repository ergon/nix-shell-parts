# Customizing nixpkgs

Some packages in nixpkgs require extra configuration before they can be used.
Common cases:

- A package is marked as **unfree** (e.g. `terraform`, `vault`) and Nix refuses to build it.
- You need a **patched or overridden version** of a package.

To handle this, you can override the `pkgs` instance that nix-shell-parts uses.

Create a file like `./nix/nixpkgs-customization.nix`:

```nix
{self, ...}: {
  perSystem = {system, ...}: {
    _module.args.pkgs = import self.inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  };
}
```

Then import it in your `flake.nix`:

```nix
outputs = inputs @ {flake-parts, ...}:
  flake-parts.lib.mkFlake {inherit inputs;} {
    imports = [
      inputs.nix-shell-parts.flakeModules.default
      ./nix/nixpkgs-customization.nix
    ];

    perSystem = {...}: {
      shells.default.imports = [./nix/devshell.nix];
    };
  };
```

For more advanced use cases like overlays, see the [flake-parts documentation](https://flake.parts/overlays.html#consuming-an-overlay).

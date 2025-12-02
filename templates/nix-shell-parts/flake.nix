{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    nix-shell-parts.url = "github:ergon/nix-shell-parts";
    nix-shell-parts.inputs.nixpkgs.follows = "nixpkgs";
    nix-shell-parts.inputs.flake-parts.follows = "flake-parts";
  };

  # NOTE: where should me project specific settings go?
  # | location           | description                          | edit?        |
  # |--------------------|--------------------------------------|--------------|
  # | ./nix/*.nix        | your project specific configurations | YES          |
  # | ./flake.{nix,lock} | combines everything                  | rarely       |

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.nix-shell-parts.flakeModules.default
      ];

      perSystem = {...}: {
        # define your shell environments, for example:
        # - ci: jenkins builds with minimal dependencies
        # - default: extends ci with all tools need for local development
        shells.ci.imports = [./nix/configuration.ci.nix];
        shells.default.imports = [./nix/configuration.dev.nix];
      };
    };
}

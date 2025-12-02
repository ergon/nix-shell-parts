{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  # NOTE: where should me project specific settings go?
  # | location           | description                          | edit?        |
  # |--------------------|--------------------------------------|--------------|
  # | ./nix/*.nix        | your project specific configurations | YES          |
  # | ./nix/vendored/*   | ergon provided settings              | normally not |
  # | ./flake.{nix,lock} | combines everything                  | rarely       |

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        (import ./nix/vendored {inherit inputs;})
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

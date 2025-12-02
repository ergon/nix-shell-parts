{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} ({flake-parts-lib, ...}: let
      flakeModules.default = flake-parts-lib.importApply ./modules {inherit inputs;};
    in {
      imports = [flakeModules.default];
      flake = {
        inherit flakeModules;
        templates = {
          default = {
            description = "Standard template for nix-shell-parts: normal flake dependency, easy upgrades by updating your flake input.";
            path = ./templates/nix-shell-parts;
          };
          vendored = {
            description = "Vendored template for nix-shell-parts: everything lives in your repo, but you must manually pull updates later.";
            path = ./templates/nix-shell-parts-vendored;
          };
        };
      };

      perSystem = {
        config,
        pkgs,
        lib,
        ...
      }: {
        packages.docs = pkgs.callPackage ./docs {
          inherit pkgs lib inputs;
        };
        shells.default = {
          inputsFrom = [config.packages.docs];

          treefmt = {
            enable = true;
            pre-commit-hook = true;
            programs.alejandra.enable = true;
          };
        };
      };
    });
}

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./modules
      ];
      flake.flakeModules.default = ./modules;

      perSystem = {
        shells.default = {
          treefmt = {
            enable = true;
            pre-commit-hook = true;
            programs.alejandra.enable = true;
          };
        };
      };
    };
}

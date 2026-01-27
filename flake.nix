# Copyright (c) 2025 Ergon Informatik AG
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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
      flakeModules.default = flake-parts-lib.importApply ./modules inputs;
      mkShell = import ./lib/mk-shell.nix {inherit (inputs) treefmt-nix;};
    in {
      imports = [flakeModules.default];
      flake = {
        inherit flakeModules;
        lib.mkShell = mkShell;
        templates = {
          default = {
            description = "Standard template for nix-shell-parts: normal flake dependency, easy upgrades by updating your flake input.";
            path = ./templates/nix-shell-parts;
          };
          minimal = {
            description = "Minimal template for nix-shell-parts: uses lib.mkShell without flake-parts.";
            path = ./templates/nix-shell-parts-minimal;
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
        system,
        ...
      }: {
        checks = let
          checkTemplate = name: fakeInputs: let
            template = import ./templates/${name}/flake.nix;
            outputs = template.outputs (fakeInputs
              // {
                self = outputs // {inputs = fakeInputs;};
              });
            shell = outputs.devShells.${system}.default;
          in
            pkgs.runCommand "template-${name}-check" {} ''
              test -e ${shell}
              touch $out
            '';
        in {
          mk-shell = let
            shell = mkShell {inherit pkgs;} {
              packages = [pkgs.hello];
            };
          in
            pkgs.runCommand "mk-shell-check" {
              nativeBuildInputs = shell.nativeBuildInputs;
            } ''
              # Ensure the shell derivation itself builds
              test -e ${shell}
              # Verify packages from the shell are available
              hello > $out
            '';

          template-default =
            checkTemplate
            "nix-shell-parts"
            {
              inherit (inputs) nixpkgs flake-parts;
              nix-shell-parts = inputs.self;
            };

          template-minimal =
            checkTemplate
            "nix-shell-parts-minimal" {
              inherit (inputs) nixpkgs;
              nix-shell-parts = inputs.self;
              systems.outPath = builtins.toFile "default.nix" ''[ "${system}" ]'';
            };

          template-vendored =
            checkTemplate
            "nix-shell-parts-vendored"
            {
              inherit (inputs) nixpkgs flake-parts treefmt-nix;
            };
        };

        packages.docs = pkgs.callPackage ./docs {
          inherit pkgs lib inputs;
        };
        shells.default = {
          inputsFrom = [config.packages.docs];

          treefmt = {
            enable = true;
            pre-commit-hook = true;
            programs.alejandra.enable = true;
            settings.formatter = {
              addlicense = {
                command = "${lib.getExe pkgs.addlicense}";
                options = [
                  "-c=Ergon Informatik AG"
                  "-l=MIT"
                ];
                excludes = [
                  "**/zensical.toml"
                ];
                includes = [
                  "*.nix"
                  "*.css"
                  "*.sh"
                  "*.jq"
                  "*.yml"
                  "*.toml"
                ];
              };
            };
          };
        };
      };
    });
}

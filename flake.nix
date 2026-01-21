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

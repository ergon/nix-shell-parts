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

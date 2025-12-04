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
  inputs,
  flake-parts-lib,
  nix-flake-parts,
  ...
}: {
  options = {
    perSystem = flake-parts-lib.mkPerSystemOption (
      {
        lib,
        config,
        pkgs,
        ...
      }: let
        inherit (lib) types;
      in {
        options.shellModules = lib.mkOption {
          type = lib.types.listOf lib.types.deferredModule;
          description = ''
            Extra modules that are automatically included in every shell.
            This allows other Flake Parts modules to define shared options and behavior for all shells.
          '';
          default = [];
        };

        options.shells = lib.mkOption {
          type = types.attrsOf (types.submoduleWith {
            modules =
              [
                {
                  _module.args = {
                    inherit pkgs inputs nix-flake-parts;
                  };
                }
                ./shell-modules
              ]
              ++ config.shellModules;
          });
          description = ''
            Collection of named (development) shells.
            Each entry defines its own packages and settings and is exported to the flake outputs as `devShells.<name>`.;
          '';
          default = {};
        };

        config.devShells = lib.mapAttrs (_name: shell: shell.finalPackage) config.shells;
      }
    );
  };
}

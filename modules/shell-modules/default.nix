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
  pkgs,
  config,
  lib,
  name,
  ...
}: let
  inherit (lib) types;
in {
  options = {
    name = lib.mkOption {
      type = types.str;
      description = "The name of the shell package";
      default = name;
    };
    env = lib.mkOption {
      type = types.submodule {
        freeformType = types.attrsOf types.anything;
      };
      description = "Extra environment variables to set when entering the shell.";
      default = {};
    };

    packages = lib.mkOption {
      type = types.listOf types.package;
      description = "List of packages to make available in the shell.";
      default = [];
    };

    inputsFrom = lib.mkOption {
      type = types.listOf types.package;
      description = "Add build dependencies of the listed derivations to the shell.";
      default = [];
    };

    shellHook = lib.mkOption {
      type = types.lines;
      description = "Commands to be executed when entering the shell.";
      default = "";
    };

    finalPackage = lib.mkOption {
      type = types.package;
      readOnly = true;
      description = "The actual development shell derivation created from this definition.";
    };
  };
  config = {
    finalPackage = pkgs.mkShellNoCC ({
        inherit (config) name inputsFrom;
        shellHook = ''
          # backup current shell options
          old_set_opts=$(set +o)
          old_shopt_opts=$(shopt -p)

          # turn on strict mode
          set -euo pipefail
          IFS=$'\n\t'
          ${config.shellHook}

          # restore previous shell options
          eval "$old_set_opts"
          eval "$old_shopt_opts"
        '';
        nativeBuildInputs = [config.packages];
      }
      // config.env);
  };
}

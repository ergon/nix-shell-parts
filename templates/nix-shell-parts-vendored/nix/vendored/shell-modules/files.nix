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
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) types;
  install-symlink = name: drv: ''
    mkdir -p "$(dirname "${name}")" && ln -fs "${drv}" "${name}"
  '';
in {
  options = {
    files-install = lib.mkOption {
      type = types.package;
      readOnly = true;
      description = "script to imperatively install the defined files";
    };
    files = lib.mkOption {
      type = types.attrsOf (types.oneOf [types.package types.path]);
      default = {};
      description = ''
        Allows for "installing" files into the projects setup.
        Currently only supports symlinking, but possibly copying in the future.

        - key: the name of the target file (relative to repository root)
        - value: the path or derivation to be symlinked
      '';
    };
  };
  config = {
    files-install = pkgs.writeShellApplication {
      name = "install-symlinks";
      runtimeInputs = [pkgs.coreutils];
      text = ''
        if ! _git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
          echo 'Error: Cannot install files when not inside a git repository. Did you forget to run git init?' >&2
          exit 1
        fi

        cd "$_git_root"
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList install-symlink config.files)}
      '';
    };

    shellHook = lib.mkIf (config.files != {}) (lib.mkOrder 100 "${lib.getExe config.files-install}");
  };
}

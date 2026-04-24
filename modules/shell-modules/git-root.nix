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
  lib,
  config,
  ...
}: let
  cfg = config.git;
in {
  options.git = {
    root = {
      enable = lib.mkEnableOption "git root directory shell integration";
      shellVariable = lib.mkOption {
        type = lib.types.str;
        description = ''
          The value of the git repository root directory to be used in shell scripts.

          When this module is enabled, the shell hook sets the environment variable
          named by `git.root.shellVariableName` to the output of:

            git rev-parse --show-toplevel

          This option exposes a safe, typed way to reference that variable in other Nix configuration (for example additional shellHook fragments).
        '';
        default = ''''${${cfg.root.shellVariableName}?${cfg.root.shellVariableName} is not set}'';
        apply = value:
          if cfg.root.enable
          then value
          else
            throw ''
              git.root.shellVariable was accessed while git.root.enable is false.
              Enable the module with git.root.enable = true before using this option.
            '';
      };
      shellVariableName = lib.mkOption {
        type = lib.types.str;
        description = ''
          Name of the environment variable that will hold the git repository root inside the dev shell.

          You can override the name if you need to avoid clashes with other tooling.
        '';
        default = "_GIT_ROOT";
        apply = value:
          if cfg.root.enable
          then value
          else
            throw ''
              git.root.shellVariableName was accessed while git.root.enable is false.
              Enable the module with git.root.enable = true before using this option.
            '';
      };
    };
  };
  config =
    lib.mkIf cfg.root.enable
    {
      shellHook = lib.mkMerge [
        # `nix develop` runs the shellHooks in the current $PWD, which is often surprising.
        # Therefore, change into the repository root directory so all subsequent shellHook fragments execute there.
        (lib.mkOrder 100 ''
          export ${cfg.root.shellVariableName}=$(git rev-parse --show-toplevel)
          pushd "${cfg.root.shellVariable}" > /dev/null
        '')
      ];
    };
}

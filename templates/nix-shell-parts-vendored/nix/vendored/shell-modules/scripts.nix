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
  lib,
  config,
  ...
}: let
  inherit (lib) types;
  scriptOpts = {
    config,
    name,
    ...
  }: {
    imports = [
      # For devenv backward compatibility
      (lib.mkRenamedOptionModule ["exec"] ["text"])
    ];
    options = {
      text = lib.mkOption {
        type = types.str;
        description = ''
          The script body to expose as an executable command named after the attribute key.
          If the text starts with a shebang (e.g. "#!/usr/bin/env python"), it is written verbatim and executed with that interpreter.
          Otherwise the text is treated as a shell script (bash).
        '';
      };
      path = lib.mkOption {
        type = types.str;
        description = ''Absolute path to the generated executable for this script.'';
        readOnly = true;
      };
      strict = lib.mkOption {
        type = types.bool;
        description = ''When the script is treated as bash (no shebang), enable strict mode and lint it with shellcheck.'';
        default = true;
      };
      finalPackage = lib.mkOption {
        type = types.package;
        internal = true;
      };
    };
    config = {
      finalPackage =
        # prioritize scripts over plain packages
        lib.hiPrioSet (
          # if a shebang is present, write a the script as is
          # otherwise, write a bash shell scrip
          if lib.hasPrefix "#!" config.text
          then
            pkgs.writeTextFile {
              inherit name;
              text = config.text;
              executable = true;
              destination = "/bin/${name}";
              allowSubstitutes = true;
            }
          else if config.strict
          then
            pkgs.writeShellApplication {
              inherit name;
              text = config.text;
            }
          else pkgs.writeShellScriptBin name config.text
        );
      path = lib.getExe config.finalPackage;
    };
  };
in {
  options = {
    scripts = lib.mkOption {
      type = types.attrsOf (types.submodule scriptOpts);
      description = "Set of named scripts that each add an executable command to the shell.";
      default = {};
    };
  };

  config = {
    packages = lib.mapAttrsToList (name: value: value.finalPackage) config.scripts;
  };
}

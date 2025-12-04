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
  cfg = config.profile;

  inherit (lib) types;

  # Returns all store paths from a derivation or package, supporting multi-output derivations.
  #
  # Examples:
  #   drvOrPackageToPaths pkgs.openssl
  #     => [ /nix/store/...-openssl /nix/store/...-openssl-dev ... ]
  #
  #   drvOrPackageToPaths pkgs.git
  #     => [ /nix/store/...-git ]
  drvOrPackageToPaths = drvOrPackage:
    if drvOrPackage ? outputs
    then builtins.map (output: drvOrPackage.${output}) drvOrPackage.outputs
    else [drvOrPackage];
in {
  options.profile = {
    enable = lib.mkEnableOption "bin profile directory";
    destination = lib.mkOption {
      type = types.str;
      description = "The destination directory in which to create the profile";
      default =
        if config.git.root.enable
        then "${config.git.root.shellVariable}/bin"
        else "$PWD/bin";
    };
    finalPackage = lib.mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        An environment profile derivation containing all binaries of the packages of this shell.
        This profile is used to create this shell, but can also be linked or reused elsewhere.
        For example, you can symlink it to a `bin/` folder in your repository to get stable paths to tools like nodejs.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    profile = {
      finalPackage = pkgs.buildEnv {
        name = "${config.name}-profile";
        paths = lib.flatten (builtins.map drvOrPackageToPaths config.packages);
        pathsToLink = [
          "/bin"
        ];
      };
    };

    shellHook = ''
      rm -rf "${cfg.destination}"
      ln -fs ${config.profile.finalPackage}/bin "${cfg.destination}"
    '';
  };
}

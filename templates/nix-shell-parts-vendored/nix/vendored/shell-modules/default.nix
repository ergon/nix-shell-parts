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

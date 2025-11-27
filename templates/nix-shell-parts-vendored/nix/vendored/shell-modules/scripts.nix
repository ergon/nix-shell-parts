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
      };
      path = lib.mkOption {
        type = types.str;
        readOnly = true;
      };
      strict = lib.mkOption {
        type = types.bool;
        default = false;
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

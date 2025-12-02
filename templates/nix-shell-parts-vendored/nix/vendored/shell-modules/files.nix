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

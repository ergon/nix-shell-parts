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

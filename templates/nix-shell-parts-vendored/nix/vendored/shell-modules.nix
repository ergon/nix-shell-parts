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

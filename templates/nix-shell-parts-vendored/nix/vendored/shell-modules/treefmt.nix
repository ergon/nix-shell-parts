{
  nix-flake-parts,
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (nix-flake-parts.inputs) treefmt-nix;
  cfg = config.treefmt;
in {
  options.treefmt = lib.mkOption {
    description = "treefmt config";
    type = treefmt-nix.lib.submoduleWith lib {
      specialArgs = {inherit pkgs;};
      modules = [
        {
          options = {
            enable = lib.mkEnableOption "treefmt formatting";
            pre-commit-hook = lib.mkEnableOption "Setup pre commit hook for treefmt";
            pkgs = lib.mkOption {internal = true;};
          };
        }
      ];
    };
    default = {};
  };
  config = {
    packages = lib.mkIf cfg.enable [
      cfg.build.wrapper
    ];
    git.hooks.pre-commit-command = lib.mkIf cfg.pre-commit-hook "${lib.getExe cfg.build.wrapper} --fail-on-change $FILES";
  };
}

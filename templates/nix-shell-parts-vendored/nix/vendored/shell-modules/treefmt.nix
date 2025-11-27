{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (inputs) treefmt-nix;
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
  };
  config = {
    packages = lib.mkIf cfg.enable [
      config.treefmt.build.wrapper
    ];
    git.hooks.pre-commit-command = lib.mkIf cfg.pre-commit-hook "${lib.getExe config.treefmt.build.wrapper} --fail-on-change $FILES";
  };
}

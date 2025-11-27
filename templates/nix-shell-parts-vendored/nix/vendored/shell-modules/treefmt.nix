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
    type = treefmt-nix.lib.submoduleWith lib {
      modules = [
        {
          options = {
            enable = lib.mkEnableOption "treefmt formatting";
            pre-commit-hook = lib.mkEnableOption "Setup pre commit hook for treefmt";
          };
        }
      ];
    };
  };
  config = {
    treefmt.pkgs = pkgs;
    packages = lib.mkIf cfg.enable [
      config.treefmt.build.wrapper
    ];
    git.hooks.pre-commit-command = lib.mkIf cfg.pre-commit-hook "${lib.getExe config.treefmt.build.wrapper} --fail-on-change $FILES";
  };
}

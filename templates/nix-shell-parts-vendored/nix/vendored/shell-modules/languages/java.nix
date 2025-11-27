{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.languages.java;
in {
  options.languages.java = {
    enable = lib.mkEnableOption "jdk";
    jdk.package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.jdk;
    };
    gradle = {
      enable = lib.mkEnableOption "gradle";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.gradle;
      };
    };
  };
  config = lib.mkIf (cfg.enable) {
    packages = [cfg.jdk.package] ++ (lib.optional (cfg.gradle.enable) cfg.gradle.package);
    env."JAVA_HOME" = cfg.jdk.package.home;
  };
}

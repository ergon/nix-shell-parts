{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.languages.java;
in {
  options.languages.java = {
    gradle = {
      version = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "The gradle version to use";
        default = null;
      };
      hash = lib.mkOption {
        type = lib.types.str;
        description = "The SRI hash of the gradle distribution";
        default = "";
      };
    };
  };
  config = {
    languages.java.gradle.package = lib.mkIf (cfg.gradle.version != null) (
      pkgs.gradle-packages.mkGradle {
        inherit (cfg.gradle) version hash;
        defaultJava = cfg.jdk.package;
      }
    );
  };
}

{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.profile;

  inherit (lib) types;

  # Returns all store paths from a derivation or package, supporting multi-output derivations.
  #
  # Examples:
  #   drvOrPackageToPaths pkgs.openssl
  #     => [ /nix/store/...-openssl /nix/store/...-openssl-dev ... ]
  #
  #   drvOrPackageToPaths pkgs.git
  #     => [ /nix/store/...-git ]
  drvOrPackageToPaths = drvOrPackage:
    if drvOrPackage ? outputs
    then builtins.map (output: drvOrPackage.${output}) drvOrPackage.outputs
    else [drvOrPackage];
in {
  options.profile = {
    enable = lib.mkEnableOption "bin profile directory";
    destination = lib.mkOption {
      type = types.str;
      description = "The destination directory in which to create the profile";
      default =
        if config.git.root.enable
        then "${config.git.root.shellVariable}/bin"
        else "$PWD/bin";
    };
    finalPackage = lib.mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        An environment profile derivation containing all binaries of the packages of this shell.
        This profile is used to create this shell, but can also be linked or reused elsewhere.
        For example, you can symlink it to a `bin/` folder in your repository to get stable paths to tools like nodejs.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    profile = {
      finalPackage = pkgs.buildEnv {
        name = "${config.name}-profile";
        paths = lib.flatten (builtins.map drvOrPackageToPaths config.packages);
        pathsToLink = [
          "/bin"
        ];
      };
    };

    shellHook = ''
      rm -rf "${cfg.destination}"
      ln -fs ${config.profile.finalPackage}/bin "${cfg.destination}"
    '';
  };
}

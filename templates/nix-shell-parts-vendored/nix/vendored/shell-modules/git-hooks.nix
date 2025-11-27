{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) types;
  command = config.git.hooks.pre-commit-command;

  pre-commit = pkgs.writeShellScript "pre-commit" ''
    set -e

    # Get list of staged files (added, copied, modified, renamed)
    FILES=$(git diff --cached --name-only --diff-filter=ACMR)

    # No files → skip
    [ -z "$FILES" ] && exit 0

    # Example: run a formatter, linter, or custom command
    ${command}

    exit 0
  '';
in {
  options.git.hooks.pre-commit-command = lib.mkOption {
    type = types.nullOr types.str;
    description = ''
      command to be run as pre-commit.

      $FILES is an environment variable that contains all changes files
    '';
    example = "treefmt $FILES";
    default = null;
  };
  config.files.".git/hooks/pre-commit" = lib.mkIf (command != null) pre-commit;
}

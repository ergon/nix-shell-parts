# Copyright (c) 2025 Ergon Informatik AG
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) types;
  cfg = config.git.hooks;

  pre-commit = pkgs.writeShellScript "pre-commit" ''
    set -e

    # Get list of staged files (added, copied, modified, renamed)
    FILES=$(git diff --cached --name-only --diff-filter=ACMR)

    # No files → skip
    [ -z "$FILES" ] && exit 0

    ${cfg.pre-commit-command}

    exit 0
  '';

  commit-msg = pkgs.writeScript "commit-msg" ''
    set -e

    MSG_FILE="$1"

    ${cfg.commit-msg-command}

    exit 0
  '';
in {
  options.git.hooks = {
    pre-commit-command = lib.mkOption {
      type = types.lines;
      description = ''
        command to be run as pre-commit.

        $FILES is an environment variable that contains all changes files
      '';
      example = "treefmt $FILES";
      default = "";
    };

    commit-msg-command = lib.mkOption {
      type = types.lines;
      description = ''
        command to be run as commit-msg.

        $MSG_FILE is an environment variable that contains all changes files
      '';
      default = "";
    };
  };
  config = {
    shellHook = lib.mkOrder 200 ''
      _git_hooks_dir="$(git rev-parse --git-dir 2>/dev/null)/hooks"
      if [ -d "$(git rev-parse --git-dir 2>/dev/null)" ]; then
        mkdir -p "$_git_hooks_dir"
        ${lib.optionalString (cfg.pre-commit-command != "") ''ln -fs "${pre-commit}" "$_git_hooks_dir/pre-commit"''}
        ${lib.optionalString (cfg.commit-msg-command != "") ''ln -fs "${commit-msg}" "$_git_hooks_dir/commit-msg"''}
      fi
    '';
  };
}

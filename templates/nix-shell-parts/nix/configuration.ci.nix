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
}: {
  # NOTE: configuration.ci.nix is for jenkins builds
  # keep dependencies small and add dev dependencies in configuration.dev
  languages.java = {
    enable = true;
    jdk.package = pkgs.jdk21;
    gradle.enable = true;
    gradle.version = "8.9";
    gradle.hash = "sha256-1yXXB7+r1N/clYxiQAOzyArMwD9wN7USLEsdDvFc7Ks=";
  };

  treefmt.enable = true; # enable treefmt for formatting with multiple formatters
  # https://github.com/numtide/treefmt-nix?tab=readme-ov-file#supported-programs
  treefmt.programs.alejandra.enable = true; #nix linter
  treefmt.programs.ktlint.enable = true;
  # installing pre-commit hook is optional
  treefmt.pre-commit-hook = true;

  # other packages (see search.nixos.org)
  packages = [
    pkgs.nodejs_24
    pkgs.curl
  ];

  imports = [
    # NOTE: feel free to split your configuration into individual modules
    # and include them here (or in any other configuration.*.nix).
    # For example, you can split it into frontend.nix, backend.nix, devops.nix
  ];
}

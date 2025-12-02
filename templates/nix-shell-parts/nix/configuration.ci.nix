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

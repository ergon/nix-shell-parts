{pkgs, ...}: {
  # NOTE: configuration.dev.nix is for local developer environment
  # this (typically) extends configuration.ci.nix with dev-only dependencies
  imports = [./configuration.ci.nix];

  # enable treefmt for formatting with multiple formatters
  # https://github.com/numtide/treefmt-nix?tab=readme-ov-file#supported-programs
  treefmt.enable = true;
  treefmt.programs.alejandra.enable = true;
  treefmt.programs.ktlint.enable = true;

  #additional packages: search.nixos.org
  packages = [
    #pkgs.k9s
    #pkgs.google-cloud-sdk
    #pkgs.awscli2
    #pkgs.terraform
    #pkgs.kubectl
    #pkgs.kubernetes-helm
    #pkgs.k9s
  ];
}

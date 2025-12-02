{self, ...}: {
  perSystem = {system, ...}: {
    # The following allows to customize nixpkgs (config & overlays)
    # Explanation: https://flake.parts/overlays.html#consuming-an-overlay
    _module.args.pkgs = import self.inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        # overlay.nix
      ];
    };
  };
}

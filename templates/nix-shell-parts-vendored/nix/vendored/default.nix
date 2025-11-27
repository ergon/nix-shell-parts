{
  imports = [
    ./systems.nix
    ./shell-modules.nix
  ];
  perSystem.shellModules = [
    ./shell-modules/devenv-compatibility.nix
    ./shell-modules/scripts.nix
  ];
}

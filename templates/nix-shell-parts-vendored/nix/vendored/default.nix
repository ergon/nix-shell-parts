{
  imports = [
    ./systems.nix
    ./shell-modules.nix
  ];
  perSystem.shellModules = [
    ./shell-modules/devenv-compatibility.nix
    ./shell-modules/files.nix
    ./shell-modules/git-hooks.nix
    ./shell-modules/scripts.nix
  ];
}

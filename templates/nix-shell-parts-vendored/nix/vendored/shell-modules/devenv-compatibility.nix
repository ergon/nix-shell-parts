{lib, ...}: {
  imports = [
    (lib.mkRenamedOptionModule ["enterShell"] ["shellHook"])
  ];
}

{
  pkgs,
  lib,
  inputs,
  ...
}: let
  configuration =
    inputs.flake-parts.lib.evalFlakeModule
    {
      inputs = {inherit (inputs) nixpkgs;};
    }
    {
      imports = [
        inputs.self.flakeModules.default
      ];
      systems = [throw "The `systems` option value is not available when generating documentation. "];
    };

  isShellModuleOption = option: lib.strings.hasPrefix "perSystem.shells.<name>" option.name;

  isNixShellPartsOption = option:
    lib.all (
      declaration:
        declaration != "lib/modules.nix" && !(lib.strings.hasPrefix "${inputs.flake-parts}" declaration)
    )
    option.declarations;

  flakePartsOptions = pkgs.nixosOptionsDoc {
    inherit (configuration) options;

    transformOptions = option: let
      visible =
        option.visible
        # Only show our flake parts options
        && isNixShellPartsOption option
        # Shell Modules are documented separately
        && !isShellModuleOption option;
      option' = option // {inherit visible;};
    in
      if visible
      then mapDeclarations option'
      else option';
  };

  githubBaseUrl = "https://github.com/ergon/nix-shell-parts/blob/v1/";
  rootPrefix = toString ../.;
  declarationToLink = storePathPrefix: baseUrl: decl: let
    subpath = lib.removePrefix "/" (lib.removePrefix storePathPrefix (toString decl));
  in rec {
    url = "${baseUrl}${subpath}";
    name =
      if lib.hasPrefix githubBaseUrl url
      then subpath
      else url;
  };
  mapDeclarations = option:
    option
    // {
      declarations =
        map (
          decl:
            if lib.hasPrefix rootPrefix (toString decl)
            then declarationToLink rootPrefix githubBaseUrl decl
            else if lib.hasPrefix (toString inputs.treefmt-nix) (toString decl)
            then declarationToLink (toString inputs.treefmt-nix) "https://github.com/numtide/treefmt-nix/blob/${inputs.treefmt-nix.rev}/" decl
            else throw "Cannot map declaration of ${decl}"
        )
        option.declarations;
    };

  allShellOptions = let
    nix-flake-parts = {inherit inputs;};
  in
    lib.evalModules {
      modules =
        [
          {git.root.enable = true;}
          ../templates/nix-shell-parts-vendored/nix/vendored/shell-modules/default.nix
        ]
        ++ (
          (import ../templates/nix-shell-parts-vendored/nix/vendored nix-flake-parts)
        ).perSystem.shellModules;
      specialArgs = {
        name = "<name>";
        inherit pkgs inputs nix-flake-parts;
      };
    };

  hasDeclaringFile = option: declaringFile:
    lib.any (declaration: declaration == declaringFile) option.declarations;

  hasNamePrefix = prefixes: option:
    lib.any (p: lib.strings.hasPrefix p option.name) prefixes;

  # For a given docs page, decide if an option should be visible there
  optionVisibleFor = declaringFile: option: let
    # normal rule: must be declared in the file
    declaredHere = hasDeclaringFile option declaringFile;

    # extra rule for treefmt module:
    # include any option whose name starts with "treefmt"
    extraForTreefmt =
      lib.strings.hasPrefix rootPrefix declaringFile
      && builtins.baseNameOf declaringFile == "treefmt.nix"
      && hasNamePrefix ["treefmt"]
      option;
  in
    declaredHere || extraForTreefmt;

  optionsDocFor = declaringFile:
    pkgs.nixosOptionsDoc {
      inherit (allShellOptions) options;
      transformOptions = option:
        if option.name == "_module.args" || !(optionVisibleFor declaringFile option)
        then option // {visible = false;}
        else mapDeclarations option;
    };

  rawOpts = lib.optionAttrSetToDocList allShellOptions.options;
  shellOptionsByDeclaringFile = lib.lists.groupBy (it: lib.head it.declarations) rawOpts;
  shellModulesByDeclaringFile = lib.filterAttrs (key: _: lib.strings.hasPrefix rootPrefix key) shellOptionsByDeclaringFile;
  docsByShellModules = lib.mapAttrs' (name: value: lib.nameValuePair (lib.removeSuffix ".nix" (builtins.baseNameOf name)) (optionsDocFor name)) shellModulesByDeclaringFile;
in
  pkgs.stdenvNoCC.mkDerivation {
    name = "nix-shell-parts-docs";
    src = ./.;

    nativeBuildInputs = [
      pkgs.mdbook
    ];

    patchPhase = ''
      cp ${../README.md} src/README.md

      substituteInPlace src/SUMMARY.md \
        --replace-fail '<!-- Shell modules -->' \
        ${
        lib.escapeShellArg (
          lib.strings.concatMapAttrsStringSep "\n" (
            name: value: "- [${name}](./shell_module_${name}.md)"
          )
          docsByShellModules
        )
      }
      cp "${flakePartsOptions.optionsCommonMark}" src/flake_parts_options.md

      ${
        lib.strings.concatMapAttrsStringSep "\n" (
          name: value: "cp ${value.optionsCommonMark} src/shell_module_${name}.md"
        )
        docsByShellModules
      }

    '';
    buildPhase = ''mdbook build --dest-dir $out'';
  }

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
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types;
  json = pkgs.formats.json {};
  cfg = config.renovate;
  generateValidatedConfig = name: value:
    pkgs.runCommand name
    {
      nativeBuildInputs = [
        pkgs.jq
        cfg.package
      ];
      value = builtins.toJSON value;
      passAsFile = ["value"];
      preferLocalBuild = true;
    }
    ''
      jq . "$valuePath"> $out
      renovate-config-validator $out
    '';
  generateConfig =
    if cfg.validateSettings
    then generateValidatedConfig
    else json.generate;
in {
  options.renovate = {
    enable = lib.mkEnableOption "renovate";
    package = lib.mkPackageOption pkgs "renovate" {};

    validateSettings = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Wether to run renovate's config validator on the built configuration.";
    };

    enableErgonMirrors = lib.mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables the use of Ergon-internal mirrors as default registries for various datasources
        such as Docker, Maven, and NPM.

        When set to true, this option configures Renovate to automatically use pre-defined internal mirrors.

        This setting is complementary to `registryUrls`, which allows explicit specification of registry URLs.
        Use `registryUrls` directly in addition to this option to add additional mirrors, for example if you need the JasperSoft Repository.
      '';
    };

    registryUrls = lib.mkOption {
      type = types.attrsOf (types.listOf types.str);
      description = ''
        Specifies custom registry URLs for Renovate to use when looking up dependencies.

        By default, Renovate uses the default (or automatically detected) registries associated with each datasource.
        This option allows explicitly defining alternative registries per datasource, simplifying
        the configuration and merging of related package rules with nix.

        Each attribute name corresponds to a datasource type (e.g., "maven", "npm", "docker"), with the value
        being a list of registry URLs Renovate should use for dependency lookup.

        For more details, see: https://docs.renovatebot.com/configuration-options/#registryurls
      '';
      default = {};
      example = {
        maven = ["https://repo.example.com"];
      };
    };

    recommendedJenkinsSettings = lib.mkOption {
      type = types.bool;
      default = false;
      description = ''
        When set to true, adds recommended Renovate settings optimized for execution within Jenkins CI jobs.
      '';
    };

    settings = lib.mkOption {
      type = json.type;
      default = {};
      description = ''
        Renovate's global configuration.

        This option directly maps to Renovate's configuration settings, allowing full control
        over Renovate's behavior and integration with platforms, authentication, and commit handling.

        For detailed configuration options and examples, refer to:
        https://docs.renovatebot.com/self-hosted-configuration/
      '';
      example = {
        platform = "bitbucket-server";
        endpoint = "https://stash.ergon.ch";
        gitAuthor = "Renovate <renovate@ergon.ch>";
      };
    };
  };

  config = let
    renovatePreview = pkgs.writeShellApplication {
      name = "renovate-preview";
      runtimeInputs = [pkgs.jq pkgs.gnused pkgs.coreutils cfg.package];
      runtimeEnv.RENOVATE_PREVIEW_JQ = ./renovate-preview.jq;
      text = builtins.readFile ./renovate-preview.sh;
    };
    configFile = generateConfig "renovate-config.json" cfg.settings;
  in
    lib.mkIf cfg.enable {
      renovate = lib.mkMerge [
        {
          settings.timezone = lib.mkDefault "Europe/Zurich";
          settings.packageRules =
            lib.mapAttrsToList (dataSource: values: {
              matchDatasources = [dataSource];
              registryUrls = values;
            })
            cfg.registryUrls;
        }
        (lib.mkIf cfg.recommendedJenkinsSettings {
          settings = {
            repositoryCache = "disabled"; # No cache, because renovate runs as ephemeral jenkins job
            branchNameStrict = true; # leads to problems on jenkins otherwise (eg. when names contain dots)
            prHourlyLimit = 0; # hourly limit does not really make sense when using renovate as a periodic job.
          };
        })
        (lib.mkIf cfg.enableErgonMirrors {
          registryUrls = {
            maven = [
              "https://artifacts.ergon.ch/artifactory/proxy-maven-central/"
              "https://artifacts.ergon.ch/artifactory/proxy-gradle-plugins/"
            ];
            npm = [
              "https://npm.ergon.ch"
            ];
            docker = [
              "https://docker-mirror.ergon.ch"
            ];
          };
        })
      ];
      packages = [cfg.package renovatePreview];
      env = {RENOVATE_CONFIG_FILE = configFile;};
    };
}

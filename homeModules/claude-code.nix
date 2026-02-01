# Claude Code plugin management extension for programs.claude-code
# Hashes: nix-prefetch-github owner repo --rev <rev>
#
# THIS MODULE IS UNREVIEWED AI SLOP, BUT IT WORKS
#
{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.programs.claude-code;
  pluginsCfg = cfg.plugins;
  homeDir = config.home.homeDirectory;

  # Process plugins with separate marketplaces
  processedWithMarketplace = map
    (p: rec {
      name = p.repo;
      marketplace = p.marketplace.repo;
      id = "${name}@${marketplace}";
      inherit (p) version rev;
      src = pkgs.fetchFromGitHub {
        inherit (p) owner repo rev hash;
      };
      marketplaceSrc = pkgs.fetchFromGitHub {
        inherit (p.marketplace) owner repo rev hash;
      };
      marketplaceInfo = {
        inherit (p.marketplace) owner repo;
      };
    })
    pluginsCfg.fromGitHub;

  # Process self-contained plugins (repo is both plugin and marketplace)
  processedSelfContained = map
    (p: rec {
      name = p.name or p.repo;
      marketplace = p.repo;
      id = "${name}@${marketplace}";
      inherit (p) version rev;
      pluginSubdir = p.pluginSubdir or null;
      src = pkgs.fetchFromGitHub {
        inherit (p) owner repo rev hash;
      };
      # For self-contained, the repo itself is the marketplace
      marketplaceSrc = src;
      marketplaceInfo = {
        inherit (p) owner repo;
      };
    })
    pluginsCfg.selfContained;

  allPlugins = processedWithMarketplace ++ processedSelfContained;

  # Deduplicate marketplaces
  uniqueMarketplaces = lib.unique (map
    (p: {
      name = p.marketplace;
      src = p.marketplaceSrc;
    })
    allPlugins);

  # Build complete plugins directory
  pluginsDir = pkgs.runCommand "claude-plugins" { } ''
    mkdir -p $out/{cache,marketplaces}

    ${lib.concatMapStringsSep "\n" (m: ''
      mkdir -p $out/marketplaces/${m.name}
      cp -rT ${m.src} $out/marketplaces/${m.name}
    '') uniqueMarketplaces}

    ${lib.concatMapStringsSep "\n" (p: ''
      mkdir -p $out/cache/${p.marketplace}/${p.name}/${p.version}
      ${if p.pluginSubdir or null != null then ''
        cp -rT ${p.src}/${p.pluginSubdir} $out/cache/${p.marketplace}/${p.name}/${p.version}
      '' else ''
        cp -rT ${p.src} $out/cache/${p.marketplace}/${p.name}/${p.version}
      ''}
    '') allPlugins}

    # Registry: known_marketplaces.json
    cat > $out/known_marketplaces.json << 'EOF'
    ${builtins.toJSON (lib.listToAttrs (
      map
        (p: lib.nameValuePair p.marketplace {
          source = {
            source = "github";
            repo = "${p.marketplaceInfo.owner}/${p.marketplaceInfo.repo}";
          };
          installLocation = "${homeDir}/.claude/plugins/marketplaces/${p.marketplace}";
          lastUpdated = "2025-01-01T00:00:00.000Z";
        })
        allPlugins
    ))}
    EOF

    # Registry: installed_plugins.json
    cat > $out/installed_plugins.json << 'EOF'
    ${builtins.toJSON {
      version = 2;
      plugins = lib.listToAttrs (
        map
          (p: lib.nameValuePair p.id [{
            scope = "user";
            installPath = "${homeDir}/.claude/plugins/cache/${p.marketplace}/${p.name}/${p.version}";
            inherit (p) version rev;
            installedAt = "2025-01-01T00:00:00.000Z";
            lastUpdated = "2025-01-01T00:00:00.000Z";
            gitCommitSha = p.rev;
            isLocal = false;
          }])
          allPlugins
      );
    }}
    EOF
  '';

in
{
  options.programs.claude-code.plugins = {
    fromGitHub = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          owner = lib.mkOption {
            type = lib.types.str;
            description = "GitHub owner of the plugin repository";
          };
          repo = lib.mkOption {
            type = lib.types.str;
            description = "GitHub repository name (also used as plugin name)";
          };
          version = lib.mkOption {
            type = lib.types.str;
            description = "Plugin version (informational, used in install path)";
          };
          rev = lib.mkOption {
            type = lib.types.str;
            description = "Git commit SHA for the plugin";
          };
          hash = lib.mkOption {
            type = lib.types.str;
            description = "Nix SRI hash";
          };
          marketplace = lib.mkOption {
            type = lib.types.submodule {
              options = {
                owner = lib.mkOption { type = lib.types.str; };
                repo = lib.mkOption { type = lib.types.str; };
                rev = lib.mkOption { type = lib.types.str; };
                hash = lib.mkOption { type = lib.types.str; };
              };
            };
            description = "Separate marketplace repository";
          };
        };
      });
      default = [ ];
      description = "Plugins with separate marketplace repositories";
    };

    selfContained = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          owner = lib.mkOption {
            type = lib.types.str;
            description = "GitHub owner";
          };
          repo = lib.mkOption {
            type = lib.types.str;
            description = "GitHub repository name (also used as marketplace name)";
          };
          name = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Plugin name (defaults to repo name)";
          };
          version = lib.mkOption {
            type = lib.types.str;
            description = "Plugin version";
          };
          rev = lib.mkOption {
            type = lib.types.str;
            description = "Git commit SHA";
          };
          hash = lib.mkOption {
            type = lib.types.str;
            description = "Nix SRI hash";
          };
          pluginSubdir = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Subdirectory containing the plugin (e.g., 'plugin')";
          };
        };
      });
      default = [ ];
      description = "Self-contained plugins where the repo is both plugin and marketplace";
    };
  };

  config = lib.mkIf (cfg.enable && allPlugins != [ ]) {
    programs.claude-code.settings = lib.mkMerge [{
      enabledPlugins = lib.listToAttrs (
        map (p: lib.nameValuePair p.id true) allPlugins
      );
    }];

    home.file.".claude/plugins/installed_plugins.json".source = "${pluginsDir}/installed_plugins.json";
    home.file.".claude/plugins/known_marketplaces.json".source = "${pluginsDir}/known_marketplaces.json";
    home.file.".claude/plugins/cache".source = "${pluginsDir}/cache";
    home.file.".claude/plugins/marketplaces".source = "${pluginsDir}/marketplaces";
  };
}

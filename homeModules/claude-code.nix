# Claude Code plugin management extension for programs.claude-code
# Hashes: nix-prefetch-github owner repo --rev <rev>
{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.programs.claude-code;
  pluginsCfg = cfg.plugins;
  homeDir = config.home.homeDirectory;

  # Transform plugin configs into fetchable sources
  processedPlugins = map
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
    })
    pluginsCfg.fromGitHub;

  # Deduplicate marketplaces shared by multiple plugins
  uniqueMarketplaces = lib.unique (map
    (p: {
      name = p.marketplace;
      src = p.marketplaceSrc;
    })
    processedPlugins);

  # Build complete plugins directory with cache, marketplaces, and registries
  pluginsDir = pkgs.runCommand "claude-plugins" { } ''
    mkdir -p $out/{cache,marketplaces}

    ${lib.concatMapStringsSep "\n" (m: ''
      mkdir -p $out/marketplaces/${m.name}
      cp -rT ${m.src} $out/marketplaces/${m.name}
    '') uniqueMarketplaces}

    ${lib.concatMapStringsSep "\n" (p: ''
      mkdir -p $out/cache/${p.marketplace}/${p.name}/${p.version}
      cp -rT ${p.src} $out/cache/${p.marketplace}/${p.name}/${p.version}
    '') processedPlugins}

    # Registry files (timestamps hardcoded for reproducibility)
    cat > $out/known_marketplaces.json << 'EOF'
    ${builtins.toJSON (lib.listToAttrs (
      lib.unique (map
        (p: lib.nameValuePair p.marketplace.repo {
          source = {
            source = "github";
            repo = "${p.marketplace.owner}/${p.marketplace.repo}";
          };
          installLocation = "${homeDir}/.claude/plugins/marketplaces/${p.marketplace.repo}";
          lastUpdated = "2025-01-01T00:00:00.000Z";
        })
        pluginsCfg.fromGitHub)
    ))}
    EOF

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
          processedPlugins
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
            example = "obra";
            description = "GitHub owner of the plugin repository";
          };
          repo = lib.mkOption {
            type = lib.types.str;
            example = "superpowers";
            description = "GitHub repository name (also used as plugin name)";
          };
          version = lib.mkOption {
            type = lib.types.str;
            example = "4.0.3";
            description = "Plugin version (informational, used in install path)";
          };
          rev = lib.mkOption {
            type = lib.types.str;
            example = "b9e16498b9b6b06defa34cf0d6d345cd2c13ad31";
            description = "Git commit SHA for the plugin";
          };
          hash = lib.mkOption {
            type = lib.types.str;
            example = "sha256-0/biMK5A9DwXI/UeouBX2aopkUslzJPiNi+eZFkkzXI=";
            description = "Nix SRI hash (use nix-prefetch-github to obtain)";
          };
          marketplace = lib.mkOption {
            type = lib.types.submodule {
              options = {
                owner = lib.mkOption {
                  type = lib.types.str;
                  example = "obra";
                  description = "GitHub owner of the marketplace repository";
                };
                repo = lib.mkOption {
                  type = lib.types.str;
                  example = "superpowers-marketplace";
                  description = "GitHub repository name of the marketplace";
                };
                rev = lib.mkOption {
                  type = lib.types.str;
                  example = "d466ee3584579088a4ee9a694f3059fa73c17ff1";
                  description = "Git commit SHA for the marketplace";
                };
                hash = lib.mkOption {
                  type = lib.types.str;
                  example = "sha256-4juZafMOd+JnP5z1r3EyDqyL9PGlPnOCA/e3I/5kfNQ=";
                  description = "Nix SRI hash (use nix-prefetch-github to obtain)";
                };
              };
            };
            description = "Marketplace the plugin belongs to";
          };
        };
      });
      default = [ ];
      description = "Plugins to install from GitHub (requires plugin + marketplace sources)";
    };
  };

  config = lib.mkIf (cfg.enable && pluginsCfg.fromGitHub != [ ]) {
    programs.claude-code.settings = lib.mkMerge [{
      enabledPlugins = lib.listToAttrs (
        map (p: lib.nameValuePair p.id true) processedPlugins
      );
    }];

    home.file.".claude/plugins/installed_plugins.json".source = "${pluginsDir}/installed_plugins.json";
    home.file.".claude/plugins/known_marketplaces.json".source = "${pluginsDir}/known_marketplaces.json";
    home.file.".claude/plugins/cache".source = "${pluginsDir}/cache";
    home.file.".claude/plugins/marketplaces".source = "${pluginsDir}/marketplaces";
  };
}

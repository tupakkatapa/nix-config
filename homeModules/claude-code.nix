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

  # Transform marketplace plugin configs into fetchable sources
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

  # Transform direct plugin configs (no marketplace required)
  processedDirectPlugins = map
    (p: rec {
      inherit (p) name;
      id = "${name}@local";
      inherit (p) version rev;
      src = pkgs.fetchFromGitHub
        {
          inherit (p) owner repo rev hash;
        } + (if p.subdir != null then "/${p.subdir}" else "");
    })
    pluginsCfg.fromGitHubDirect;

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

    # Direct plugins (no marketplace)
    ${lib.concatMapStringsSep "\n" (p: ''
      mkdir -p $out/cache/local/${p.name}/${p.version}
      cp -rT ${p.src} $out/cache/local/${p.name}/${p.version}
    '') processedDirectPlugins}

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
        # Marketplace plugins
        (map
          (p: lib.nameValuePair p.id [{
            scope = "user";
            installPath = "${homeDir}/.claude/plugins/cache/${p.marketplace}/${p.name}/${p.version}";
            inherit (p) version rev;
            installedAt = "2025-01-01T00:00:00.000Z";
            lastUpdated = "2025-01-01T00:00:00.000Z";
            gitCommitSha = p.rev;
            isLocal = false;
          }])
          processedPlugins)
        ++
        # Direct plugins
        (map
          (p: lib.nameValuePair p.id [{
            scope = "user";
            installPath = "${homeDir}/.claude/plugins/cache/local/${p.name}/${p.version}";
            inherit (p) version rev;
            installedAt = "2025-01-01T00:00:00.000Z";
            lastUpdated = "2025-01-01T00:00:00.000Z";
            gitCommitSha = p.rev;
            isLocal = true;
          }])
          processedDirectPlugins)
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

    fromGitHubDirect = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            example = "ralph-wiggum";
            description = "Plugin name (used in install path and ID)";
          };
          owner = lib.mkOption {
            type = lib.types.str;
            example = "anthropics";
            description = "GitHub owner of the repository";
          };
          repo = lib.mkOption {
            type = lib.types.str;
            example = "claude-code";
            description = "GitHub repository name";
          };
          subdir = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "plugins/ralph-wiggum";
            description = "Subdirectory within the repo containing the plugin";
          };
          version = lib.mkOption {
            type = lib.types.str;
            example = "1.0.0";
            description = "Plugin version (informational)";
          };
          rev = lib.mkOption {
            type = lib.types.str;
            example = "abc123...";
            description = "Git commit SHA";
          };
          hash = lib.mkOption {
            type = lib.types.str;
            example = "sha256-...";
            description = "Nix SRI hash";
          };
        };
      });
      default = [ ];
      description = "Plugins to install directly from GitHub (no marketplace required)";
    };
  };

  config = lib.mkIf (cfg.enable && (pluginsCfg.fromGitHub != [ ] || pluginsCfg.fromGitHubDirect != [ ])) {
    programs.claude-code.settings = lib.mkMerge [{
      enabledPlugins = lib.listToAttrs (
        (map (p: lib.nameValuePair p.id true) processedPlugins)
        ++ (map (p: lib.nameValuePair p.id true) processedDirectPlugins)
      );
    }];

    home.file.".claude/plugins/installed_plugins.json".source = "${pluginsDir}/installed_plugins.json";
    home.file.".claude/plugins/known_marketplaces.json".source = "${pluginsDir}/known_marketplaces.json";
    home.file.".claude/plugins/cache".source = "${pluginsDir}/cache";
    home.file.".claude/plugins/marketplaces".source = "${pluginsDir}/marketplaces";
  };
}

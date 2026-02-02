# Claude Code plugin management extension for programs.claude-code
# Hashes: nix-prefetch-github owner repo --rev <rev>
#
{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.programs.claude-code;
  homeDir = config.home.homeDirectory;

  # Process plugins from packages with passthru.claudePlugin metadata
  allPlugins = map
    (p: {
      name = p.passthru.claudePlugin.pname;
      inherit (p.passthru.claudePlugin) version;
      inherit (p.passthru.claudePlugin) rev;
      inherit (p.passthru.claudePlugin) id;
      inherit (p.passthru.claudePlugin) runtimeInputs;
      inherit (p.passthru.claudePlugin) activationScript;
      marketplace = p.passthru.claudePlugin.marketplace.name;
      marketplaceSrc = p.passthru.claudePlugin.marketplace.src;
      marketplaceInfo = {
        inherit (p.passthru.claudePlugin.marketplace) owner;
        inherit (p.passthru.claudePlugin.marketplace) repo;
      };
      pluginSrc = p; # The derivation itself has plugin files
    })
    cfg.plugins;

  # Collect runtime inputs from all plugins
  allRuntimeInputs = lib.unique (lib.flatten (map (p: p.runtimeInputs) allPlugins));

  # Collect activation scripts from all plugins
  allActivationScripts = lib.concatMapStrings
    (p: if p.activationScript != "" then p.activationScript + "\n" else "")
    allPlugins;

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
      cp -rT ${p.pluginSrc} $out/cache/${p.marketplace}/${p.name}/${p.version}
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
  options.programs.claude-code.plugins = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = "List of claude plugin packages (built with mkClaudePlugin)";
  };

  config = lib.mkIf (cfg.enable && allPlugins != [ ]) {
    # Collect runtime inputs from all plugins
    home.packages = allRuntimeInputs;

    programs.claude-code.settings = lib.mkMerge [{
      enabledPlugins = lib.listToAttrs (
        map (p: lib.nameValuePair p.id true) allPlugins
      );
    }];

    # Copy plugin files to writable locations (not symlinks)
    # This allows plugins like claude-mem to write to their directories
    home.activation.claudePlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Remove old symlinks if they exist
      [ -L "${homeDir}/.claude/plugins/cache" ] && rm "${homeDir}/.claude/plugins/cache"
      [ -L "${homeDir}/.claude/plugins/marketplaces" ] && rm "${homeDir}/.claude/plugins/marketplaces"
      [ -L "${homeDir}/.claude/plugins/installed_plugins.json" ] && rm "${homeDir}/.claude/plugins/installed_plugins.json"
      [ -L "${homeDir}/.claude/plugins/known_marketplaces.json" ] && rm "${homeDir}/.claude/plugins/known_marketplaces.json"

      # Create plugins directory
      mkdir -p "${homeDir}/.claude/plugins"

      # Copy with write permissions (rsync preserves structure, --chmod adds write)
      ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${pluginsDir}/cache" "${homeDir}/.claude/plugins/"
      ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${pluginsDir}/marketplaces" "${homeDir}/.claude/plugins/"

      # Copy JSON files (writable so Claude Code can update them)
      cp -f "${pluginsDir}/installed_plugins.json" "${homeDir}/.claude/plugins/"
      cp -f "${pluginsDir}/known_marketplaces.json" "${homeDir}/.claude/plugins/"
      chmod u+w "${homeDir}/.claude/plugins/installed_plugins.json"
      chmod u+w "${homeDir}/.claude/plugins/known_marketplaces.json"

      # Run plugin-specific activation scripts
      ${allActivationScripts}
    '';
  };
}

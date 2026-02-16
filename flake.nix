# https://github.com/Misterio77/nix-config
# https://github.com/jhvst/nix-config
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks.url = "github:cachix/git-hooks.nix";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # Secret management
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";

    # Hyprland
    hyprland-plugins.inputs.nixpkgs.follows = "nixpkgs";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    hyprwm-contrib.inputs.nixpkgs.follows = "nixpkgs";
    hyprwm-contrib.url = "github:hyprwm/contrib";

    # Netboot stuff
    nixie.inputs.nixpkgs.follows = "nixpkgs";
    nixie.url = "github:majbacka-labs/nixie/jesse/dev31"; # https, private
    runtime-modules.inputs.nixpkgs.follows = "nixpkgs";
    runtime-modules.url = "github:tupakkatapa/nixos-runtime-modules";
    sftp-mount.inputs.nixpkgs.follows = "nixpkgs";
    sftp-mount.url = "github:tupakkatapa/nixos-sftp-mount";
    store-remount.inputs.nixpkgs.follows = "nixpkgs";
    store-remount.url = "github:ponkila/nixos-store-remount/fix/boot-ordering";

    # Other
    anytui.inputs.nixpkgs.follows = "nixpkgs";
    anytui.url = "github:tupakkatapa/anytui";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs-unstable";
    llm-agents.url = "github:numtide/llm-agents.nix";
    molesk.inputs.nixpkgs.follows = "nixpkgs";
    molesk.url = "github:tupakkatapa/molesk";
    mozid.inputs.nixpkgs.follows = "nixpkgs";
    mozid.url = "github:tupakkatapa/mozid";
    nix-extras.inputs.nixpkgs.follows = "nixpkgs";
    nix-extras.url = "git+https://git.sr.ht/~dblsaiko/nix-extras";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim/nixos-25.11";
    ping-sweep.inputs.nixpkgs.follows = "nixpkgs";
    ping-sweep.url = "github:tupakkatapa/ping-sweep";
  };

  outputs = { self, ... }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } rec {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.agenix-rekey.flakeModule
        inputs.git-hooks.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        { pkgs
        , config
        , system
        , inputs'
        , ...
        }:
        {
          # Overlays
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
              inputs.anytui.overlays.default
            ];
          };
          overlayAttrs = {
            inherit (config.packages)
              # Custom packages used in configurations
              chroma-mcp
              kb-shortcuts
              monitor-adjust
              # Inputs
              codex
              claude-code
              ping-sweep
              ;
            # Not a single derivation
            claude-plugins = pkgs.callPackage ./packages/claude-plugins { };
          };

          # Nix code formatter -> 'nix fmt'
          treefmt.config = {
            projectRootFile = "flake.nix";
            flakeFormatter = true;
            flakeCheck = true;
            programs = {
              deadnix.enable = true;
              nixpkgs-fmt.enable = true;
              shellcheck.enable = true;
              shfmt.enable = true;
              statix.enable = true;
            };
          };

          # Pre-commit hooks
          pre-commit.check.enable = false;
          pre-commit.settings.hooks.treefmt = {
            enable = true;
            package = config.treefmt.build.wrapper;
          };

          # Development shell -> 'nix develop' or 'direnv allow'
          devShells.default = pkgs.mkShell {
            packages = [
              config.agenix-rekey.package
              pkgs.pre-commit
            ];
            shellHook = config.pre-commit.installationScript;
          };

          # Custom packages and entrypoint aliases -> 'nix run' or 'nix build'
          packages = {
            "2mp3" = pkgs.callPackage ./packages/2mp3 { };
            "chroma-mcp" = pkgs.callPackage ./packages/chroma-mcp { };
            "fat-nix-deps" = pkgs.callPackage ./packages/fat-nix-deps { };
            "kb-shortcuts" = pkgs.callPackage ./packages/kb-shortcuts { };
            "monitor-adjust" = pkgs.callPackage ./packages/monitor-adjust { };
            "pinit" = pkgs.callPackage ./packages/pinit { };
            # Inputs
            inherit (inputs'.nixie.packages) lkddb-filter;
            inherit (inputs'.nixie.packages) pxe-generate;
            inherit (inputs'.nixie.packages) refind-generate;
            inherit (inputs'.ping-sweep.packages) ping-sweep;
            inherit (inputs'.llm-agents.packages) claude-code;
          }
          // (with flake.nixosConfigurations; {
            "bandit" = bandit.config.system.build.kexecTree;
            "torgue" = torgue.config.system.build.kexecTree;
            "vladof" = vladof.config.system.build.kexecTree;
            "maliwan" = maliwan.config.system.build.kexecTree;
            "hyperion" = hyperion.config.system.build.kexecTree;
          });

          # Whitelist hosts using agenix-rekey
          agenix-rekey.nixosConfigurations = {
            inherit (self.nixosConfigurations)
              torgue
              vladof
              maliwan
              hyperion
              ;
          };
        };
      flake =
        let
          inherit (self) outputs;

          # Create lib instance with custom helpers
          customLib = import ./library { inherit (inputs.nixpkgs) lib; };

          # Base configuration applied to all hosts
          withDefaults = config: {
            specialArgs = {
              inherit inputs outputs customLib;
              unstable = import inputs.nixpkgs-unstable {
                system = config.system or "x86_64-linux";
                config.allowUnfree = true;
              };
            };
            system = config.system or "x86_64-linux";
            modules = config.modules or [ ] ++ [
              ./system/base.nix
              ./system/minimal.nix
              ./system/nix-settings.nix
              ./system/openssh.nix
              {
                nixpkgs.overlays = [
                  self.overlays.default
                  inputs.anytui.overlays.default
                ];
                system.stateVersion = "25.11";
              }
            ];
          };

          # Optional additional modules
          withExtra = config: {
            modules = config.modules or [ ] ++ [
              inputs.agenix-rekey.nixosModules.default
              inputs.agenix.nixosModules.default
              inputs.home-manager.nixosModules.home-manager
              inputs.nix-extras.nixosModules.common
              inputs.nixie.nixosModules.refindGenerate
              inputs.runtime-modules.nixosModules.runtimeModules
              inputs.store-remount.nixosModules.storeRemount
              inputs.sftp-mount.nixosModules.sftpClient
              self.nixosModules.monitoring
              self.nixosModules.stateSaver
              ({ config, ... }: {
                home-manager = {
                  sharedModules = [
                    inputs.nixvim.homeModules.nixvim
                    inputs.nix-index-database.homeModules.nix-index
                    self.homeModules.claudeCode
                    {
                      programs.nix-index.enable = true;
                      programs.nix-index-database.comma.enable = true;
                    }
                  ];
                  extraSpecialArgs = {
                    inherit (config.networking) hostName;
                    inherit customLib;
                    inherit (inputs) mozid;
                    unstable = import inputs.nixpkgs-unstable {
                      system = config.system or "x86_64-linux";
                      config.allowUnfree = true;
                    };
                  };
                  useGlobalPkgs = true;
                };
                age.rekey = {
                  masterIdentities = [
                    {
                      identity = ./master.hmac;
                      pubkey = "age19xu98r52uq33f7lu5z6zafysvnx9snq72x3j6gtcvkd0a8ew8q9q34nw3u";
                    }
                    {
                      identity = ./master-2.hmac;
                      pubkey = "age1dsxnrelyffuq2wc8we80z65kfh57nq692f93gz38343ewx43y9fsdm62ay";
                    }
                  ];
                };
              })
            ];
          };

          # Hosts
          torgue = withExtra {
            modules = [
              ./home-manager/users/kari
              ./nixosConfigurations/torgue
              ./system/kexec-tree.nix
            ];
          };

          vladof = withExtra {
            modules = [
              ./home-manager/users/kari/minimal-gui.nix
              ./nixosConfigurations/vladof
              ./system/kexec-tree.nix
              inputs.molesk.nixosModules.default
              inputs.nixie.nixosModules.nixie
              inputs.sftp-mount.nixosModules.sftpServer
            ];
          };

          maliwan = withExtra {
            modules = [
              ./home-manager/users/kari
              ./nixosConfigurations/maliwan
              ./system/kexec-tree.nix
            ];
          };

          hyperion = withExtra {
            modules = [
              ./home-manager/users/core/minimal.nix
              ./nixosConfigurations/hyperion
              ./system/kexec-tree.nix
              inputs.nixie.nixosModules.nixie
            ];
          };

          bandit.modules = [
            ./home-manager/users/core/minimal.nix
            ./nixosConfigurations/bandit
            ./system/kexec-tree.nix
          ];
        in
        {
          # NixOS configuration entrypoints
          nixosConfigurations = with inputs.nixpkgs.lib;
            {
              "bandit" = nixosSystem (withDefaults bandit);
              "maliwan" = nixosSystem (withDefaults maliwan);
              "torgue" = nixosSystem (withDefaults torgue);
              "vladof" = nixosSystem (withDefaults vladof);
              "hyperion" = nixosSystem (withDefaults hyperion);
            };

          # NixOS modules
          nixosModules = {
            autoScrcpy.imports = [ ./nixosModules/auto-scrcpy.nix ];
            monitoring.imports = [ ./nixosModules/monitoring ];
            stateSaver.imports = [ ./nixosModules/state-saver.nix ];
          };

          # Home-manager modules
          homeModules = {
            claudeCode.imports = [ ./homeModules/claude-code.nix ];
          };
        };
    };
}

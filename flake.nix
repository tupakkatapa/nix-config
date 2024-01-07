# https://github.com/Misterio77/nix-config
# https://github.com/jhvst/nix-config
{
  description = "Tupakkatapa's flake";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "http://192.168.1.127:5000"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "torque.coditon.com:deBXOnPXp2vEHu4BAvh7TY2aUIOhT481ohsECftxO0E="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:mic92/sops-nix";
    nixvim.url = "github:nix-community/nixvim";
    coditon-blog.url = "github:tupakkatapa/blog.coditon.com";

    # Genshin Impact
    aagl.inputs.nixpkgs.follows = "nixpkgs";
    aagl.url = "github:ezKEa/aagl-gtk-on-nix";

    # Netboot stuff
    nixpkgs-patched.url = "github:majbacka-labs/nixpkgs/patch-init1sh"; # stable
    nix-pxe.url = "git+ssh://git@github.com/majbacka-labs/Nix-PXE";
    nixobolus.url = "github:ponkila/nixobolus";
  };

  # Add the inputs declared above to the argument attribute set
  outputs = {
    self,
    aagl,
    coditon-blog,
    flake-parts,
    home-manager,
    nix-pxe,
    nixobolus,
    nixpkgs,
    nixpkgs-patched,
    sops-nix,
    nixvim,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
    systems = ["x86_64-linux" "aarch64-linux"];
    forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs systems (system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });

    specialArgs = {inherit inputs outputs;};

    defaultModules = [
      sops-nix.nixosModules.sops
      home-manager.nixosModules.home-manager
      {
        home-manager.sharedModules = [
          nixvim.homeManagerModules.nixvim
        ];
        nixpkgs.overlays = builtins.attrValues outputs.overlays;
        system.stateVersion = "23.11";
      }
      ./system
    ];

    torque = {
      inherit specialArgs;
      system = "x86_64-linux";
      modules =
        [
          ./home-manager/users/kari
          ./nixosConfigurations/torque
          aagl.nixosModules.default
        ]
        ++ defaultModules;
    };

    vladof = {
      inherit specialArgs;
      system = "x86_64-linux";
      modules =
        [
          ./home-manager/users/kari/minimal-gui.nix
          ./nixosConfigurations/vladof
          nix-pxe.nixosModules.squashfs
          coditon-blog.nixosModules.default
        ]
        ++ defaultModules;
    };

    maliwan = {
      inherit specialArgs;
      system = "x86_64-linux";
      modules =
        [
          ./home-manager/users/kari
          ./nixosConfigurations/maliwan
          aagl.nixosModules.default
        ]
        ++ defaultModules;
    };

    bandit = {
      inherit specialArgs;
      system = "x86_64-linux";
      modules =
        [
          ./home-manager/users/kari/minimal.nix
          ./nixosConfigurations/bandit
          nixobolus.nixosModules.kexecTree
        ]
        ++ defaultModules;
    };

    jakobs = {
      inherit specialArgs;
      system = "aarch64-linux";
      modules =
        [
          ./home-manager/users/kari/minimal.nix
          ./nixosConfigurations/jakobs
          nixobolus.nixosModules.kexecTree
        ]
        ++ defaultModules;
    };
  in {
    # Overlays for modifying or extending packages
    overlays = import ./overlays.nix {inherit inputs outputs;};

    # Nix code formatter, accessible through 'nix fmt'
    formatter = forEachSystem (pkgs: pkgs.alejandra);

    # Development shell, accessible trough 'nix develop' or 'direnv allow'
    devShells = forEachSystem (pkgs: import ./shell.nix {inherit inputs pkgs;});

    # Custom packages and aliases for building hosts
    # Accessible through 'nix build', 'nix run', etc
    packages = forEachSystem (pkgs:
      (import ./packages {inherit pkgs;})
      // {
        "bandit" = self.nixosConfigurations.bandit.config.system.build.kexecTree;
        "jakobs" = self.nixosConfigurations.jakobs.config.system.build.kexecTree;
        "vladof" = self.nixosConfigurations.vladof.config.system.build.squashfs;
      });

    # NixOS configuration entrypoints
    nixosConfigurations = with lib;
      {
        "bandit" = nixosSystem bandit;
        "jakobs" = nixosSystem jakobs;
        "maliwan" = nixosSystem maliwan;
        "torque" = nixosSystem torque;
      }
      // (with nixpkgs-patched.lib; {
        "vladof" = nixosSystem vladof;
      });
  };
}

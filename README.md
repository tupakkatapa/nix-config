# My NixOS Configurations

| Hostname | Architecture | Deploy | Users | Details
| :-:       |  :-:    | :-:          | :-:   | :-
[maliwan](nixosConfigurations/maliwan/default.nix) | x86_64  | refind     | [kari](home-manager/users/kari/default.nix)                    | AMD Laptop, Hyprland
[vladof](nixosConfigurations/vladof/default.nix)   | "       | "          | [kari (minimal-gui)](home-manager/users/kari/minimal-gui.nix)  | Homelab, Firefox kiosk + Netboot Server ([Nixie](https://github.com/majbacka-labs/nixos.fi))
[torgue](nixosConfigurations/torgue/default.nix)   | "       | netboot    | [kari](home-manager/users/kari/default.nix)                    | AMD Desktop, Hyprland, [screenshot](https://raw.githubusercontent.com/tupakkatapa/nix-config/main/nixosConfigurations/torgue/screenshot.png)
[bandit](nixosConfigurations/bandit/default.nix)   | "       | "          | [core (minimal)](home-manager/users/core/minimal.nix)          | Minimal for headless

These hosts are **truly declarative** by being **ephemeral** - [majbacka-labs/nixos.fi](https://github.com/majbacka-labs/nixos.fi).

## Structure

- **./flake.nix**

  Entry point for host configurations. These host configurations are initialized with `withDefaults` or `withExtra`. These provide basic configurations that are almost always wanted. Additional modules, main configuration, host format, and users are imported to each host individually.

- **./nixosConfigurations**

  This directory contains the host-specific configurations, mainly focused on hardware-dependent settings and enabling programs.

- **./home-manager**

  User and host-spesific configurations for Home Manager. Additionally, contains user configurations even without home-manager enabled.

  <details> <summary>View details</summary>
    &nbsp;

    Configurations under `home-manager/users/<username>` are layered, extending each other incrementally. This approach allows for selecting the appropriate configuration complexity per host. If a user has a home-manager configuration, it conditionally imports host-specific settings from `home-manager/hosts/<hostname>` if it exists.

    The conditional import looks something like this:

    ```nix
    home-manager.users."${user}" = let
      optionalPaths = paths: builtins.filter (path: builtins.pathExists path) paths;
    in {
      imports = [ ... ] ++ optionalPaths [ ../../hosts/${config.networking.hostName}/default.nix ];
    };
    ```

    Host-specific home-manager configurations involve enabling certain graphical applications, making the graphical environment more user-friendly. Additionally, a separate graphical layout, or "rice", is imported into the host-specific home-manager configurations from `home-manager/hosts/.config`. These configurations are designed to be modular, allowing them to be enabled on any host for any user, provided the user has home-manager installed. Users can specify environmental variables via `home.sessionVariables` to change the color theme and default apps, such as `THEME`, `BROWSER`, `TERMINAL`, and `FILEMANAGER`. The rice will adapt to these values.

  </details>

- **./nixosModules**

  Here are my custom modules. You can use them by adding my flake as an input, and importing the spesific module in your host configuration.

  <details> <summary>Example usage</summary>
    &nbsp;

    You can find all the modules and their respective names in my `flake.nix`.

    ```nix
    {
      inputs = {
        tupakkatapa.url = "github:tupakkatapa/nix-config";
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      };

      outputs = { self, ... }@inputs: {
        nixosConfigurations = {
          yourhostname = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./configuration.nix
              inputs.tupakkatapa.nixosModules.<name>
              {
                <name> = { ... };
              }
            ];
          };
        };
      };
    }
    ```

  </details>

- **./packages**

  My custom packages, these can be accessed similarly to the modules. Add my flake as an input and reference the package in your configuration.

  <details> <summary>Example usage</summary>
    &nbsp;

    You can find all the packages and their respective names in my `flake.nix`.

    ```nix
    {
      inputs = {
        tupakkatapa.url = "github:tupakkatapa/nix-config";
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      };

      outputs = { self, ... }@inputs: {
        nixosConfigurations = {
          yourhostname = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./configuration.nix
              {
                environment.systemPackages = [
                  inputs.tupakkatapa.packages.<name>
                ];
              }
            ];
          };
        };
      };
    }
    ```

- **./library**

  A centralized library of helper functions that are injected as `customLib` via specialArgs to all configurations.

- **./system**

  This directory contains the very common configurations, such as settings in `withDefaults` and host formats, which are all imported at the flake level.

You may also find `.config` directories in various locations. These store shared configurations, which are used in context defined by their location.

## Resources

Here are some useful resources to learn about Nix and NixOS:

- [No Broilerplate - NixOS: Everything Everywhere All At Once](https://www.youtube.com/watch?v=CwfKlX3rA6E)
- [Zero to Nix - Declarative programming](https://zero-to-nix.com/concepts/declarative)

And about Flakes:

- [Zero to Nix - Nix Flakes](https://zero-to-nix.com/concepts/flakes/)
- [Misterio77 - Nix Starter Config](https://github.com/Misterio77/nix-starter-configs)

And some:

- [Shell Scripts with Nix](https://ertt.ca/nix/shell-scripts/)
- [Paranoid NixOS Setup](https://xeiaso.net/blog/paranoid-nixos-2021-07-18/)
- [NixOS is a good server OS, except when it isn’t](https://sidhion.com/blog/nixos_server_issues/)

## License

This repository is licensed under the GNU General Public License v3.0, **except for the blog content hosted under `nixosConfigurations/vladof/services/blog-contents`, which is all rights reserved.**

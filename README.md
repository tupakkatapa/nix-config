## My NixOS Configurations
| Hostname | Architecture | Format       | Users | Details
| :-:       |  :-:    | :-:          | :-:   | :-
[torque](nixosConfigurations/torque/default.nix)  | x86_64  | persistent   | [kari](home-manager/users/kari/default.nix)  | AMD Desktop, Hyprland, [screenshot.png](https://raw.githubusercontent.com/tupakkatapa/nix-config/main/nixosConfigurations/torque/screenshot.png) &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;
[maliwan](nixosConfigurations/maliwan/default.nix) | x86_64  | persistent   | [kari](home-manager/users/kari/default.nix)  | Intel Laptop, Hyprland
[hyperion](nixosConfigurations/hyperion/default.nix) | aarch64  | nix-darwin | [kari (darwin)](home-manager/users/kari/darwin.nix)  | M2 Laptop, macOS Ventura (**retired**)
[jakobs](nixosConfigurations/jakobs/default.nix) | aarch64  | netboot | [kari (minimal)](home-manager/users/kari/minimal.nix)  | Rasberry Pi 4 Model B
[bandit](nixosConfigurations/bandit/default.nix) | x86_64  | netboot | [kari (minimal)](home-manager/users/kari/minimal.nix)  | Minimal Configuration
[vladof](nixosConfigurations/vladof/default.nix) | x86_64  | persistent | [kari (minimal)](home-manager/users/kari/minimal.nix)  | Home Lab (**TODO**)

## Resources
Here are some useful resources to learn about Nix and NixOS:

- [Nix Pills - Why You Should Give it a Try](https://nixos.org/guides/nix-pills/why-you-should-give-it-a-try.html)
- [Zero to Nix - Declarative programming](https://zero-to-nix.com/concepts/declarative)
- [NixOS Manual - Manual Installation](https://nixos.org/manual/nixos/stable/index.html#sec-installation-manual)
- [Misterio77 - Nix Starter Config](https://github.com/Misterio77/nix-starter-configs)

God tier blog posts:

- [Shell Scripts with Nix](https://ertt.ca/nix/shell-scripts/)
- [Paranoid NixOS Setup](https://xeiaso.net/blog/paranoid-nixos-2021-07-18/)
- [Using NixOS as a router](https://francis.begyn.be/blog/nixos-home-router)
- [HomestakerOS - The Workflow](https://github.com/ponkila/HomestakerOS/blob/main/docs/workflow.md)
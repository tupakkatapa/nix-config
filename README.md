## My NixOS Configurations
| Hostname | Architecture | Format       | Users | Details
| :-:       |  :-:    | :-:          | :-:   | :-
[torque](nixosConfigurations/torque/default.nix)   | x86_64  | persistent | [kari](home-manager/users/kari/default.nix)              | AMD Desktop, Hyprland, [screenshot](https://raw.githubusercontent.com/tupakkatapa/nix-config/main/nixosConfigurations/torque/screenshot.png)
[maliwan](nixosConfigurations/maliwan/default.nix) | "       | "          | "                                                        | Intel Laptop, Hyprland
[vladof](nixosConfigurations/vladof/default.nix)   | "       | netboot    | [kari(minimal-gui)](home-manager/users/kari/minimal.nix) | Homelab, Firefox kiosk
[bandit](nixosConfigurations/bandit/default.nix)   | "       | "          | core                                                     | Minimal Configuration
[jakobs](nixosConfigurations/jakobs/default.nix)   | aarch64 | "          | [kari (minimal)](home-manager/users/kari/minimal.nix)    | Rasberry Pi 4 Model B


## Resources
Here are some useful resources to learn about Nix and NixOS:

- [NixOS - Everything Everywhere All At Once](https://www.youtube.com/watch?v=CwfKlX3rA6E)
- [Nix Pills - Why You Should Give it a Try](https://nixos.org/guides/nix-pills/why-you-should-give-it-a-try.html)
- [Zero to Nix - Declarative programming](https://zero-to-nix.com/concepts/declarative)
- [NixOS Wiki - Btrfs Installation](https://nixos.wiki/wiki/Btrfs)
- [Misterio77 - Nix Starter Config](https://github.com/Misterio77/nix-starter-configs)

Must-read blog posts:

- [Shell Scripts with Nix](https://ertt.ca/nix/shell-scripts/)
- [Paranoid NixOS Setup](https://xeiaso.net/blog/paranoid-nixos-2021-07-18/)
- [Using NixOS as a router](https://francis.begyn.be/blog/nixos-home-router)
- [NixOS Wireguard VPN setup](https://alberand.com/nixos-wireguard-vpn.html)


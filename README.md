## My NixOS Configurations

| Hostname | Architecture | Format       | Users | Details
| :-:       |  :-:    | :-:          | :-:   | :-
[torgue](nixosConfigurations/torgue/default.nix)   | x86_64  | persistent | [kari](home-manager/users/kari/default.nix)               | AMD Desktop, Hyprland, [screenshot](https://raw.githubusercontent.com/tupakkatapa/nix-config/main/nixosConfigurations/torgue/screenshot.png)
[maliwan](nixosConfigurations/maliwan/default.nix) | "       | "          | "                                                         | Intel Laptop, Hyprland
[vladof](nixosConfigurations/vladof/default.nix)   | "       | netboot    | [kari (minimal-gui)](home-manager/users/kari/minimal.nix) | Homelab, Firefox kiosk
[bandit](nixosConfigurations/bandit/default.nix)   | "       | "          | core                                                      | Minimal headless
[gearbox](nixosConfigurations/eridian/default.nix) | "       | "          | "                                                         | Minimal GUI
[eridian](nixosConfigurations/eridian/default.nix) | "       | "          | [kari (minimal)](home-manager/users/kari/minimal.nix)     | Netboot Server ([Nixie](https://github.com/majbacka-labs/nixos.fi))
[jakobs](nixosConfigurations/jakobs/default.nix)   | aarch64 | "          | "                                                         | Rasberry Pi 4 Model B

Most of the hosts here are **truly declarative** by being **ephemeral**. Read more about netbooting NixOS at [my blog post](https://blog.coditon.com/content/posts/Netbooting%20NixOS.md) or documentation of [majbacka-labs/nixos.fi](https://github.com/majbacka-labs/nixos.fi).

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


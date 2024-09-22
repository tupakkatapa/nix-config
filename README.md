# My NixOS Configurations

| Hostname | Architecture | Format       | Users | Details
| :-:       |  :-:    | :-:          | :-:   | :-
[maliwan](nixosConfigurations/maliwan/default.nix) | x86_64  | persistent | [kari](home-manager/users/kari/default.nix)               | Intel Laptop, Hyprland
[torgue](nixosConfigurations/torgue/default.nix)   | "       | netboot    | "                                                         | AMD Desktop, Hyprland, [screenshot](https://raw.githubusercontent.com/tupakkatapa/nix-config/main/nixosConfigurations/torgue/screenshot.png)
[vladof](nixosConfigurations/vladof/default.nix)   | "       | "          | [kari (minimal-gui)](home-manager/users/kari/minimal.nix) | Homelab, Firefox kiosk
[bandit](nixosConfigurations/bandit/default.nix)   | "       | "          | [core](home-manager/users/core/default.nix)               | Minimal for headless
[gearbox](nixosConfigurations/eridian/default.nix) | "       | "          | "                                                         | Minimal for graphical
[eridian](nixosConfigurations/eridian/default.nix) | "       | "          | [kari (minimal)](home-manager/users/kari/minimal.nix)     | Netboot Server ([Nixie](https://github.com/majbacka-labs/nixos.fi))
[jakobs](nixosConfigurations/jakobs/default.nix)   | aarch64 | "          | "                                                         | Rasberry Pi 4 Model B

Most of the hosts here are **truly declarative** by being **ephemeral**. Read more about netbooting NixOS at [my blog post](https://blog.coditon.com/content/posts/Netbooting%20NixOS.md) or documentation of [majbacka-labs/nixos.fi](https://github.com/majbacka-labs/nixos.fi).

## Structure

- **flake.nix**: Entrypoint for hosts configurations.
- **home-manager**: User and host-specific configurations done via home-manager.
- **nixosConfigurations**: Host configurations.
- **nixosModules**: My custom modules.
- **packages**: My custom packages.
- **system**: Very common configurations.

You may also find `.config` directories in various places; these are used for storing shared configurations in the context indicated by the location.

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

## License

This repository is licensed under the GNU General Public License v3.0, **except for the blog content hosted under `nixosConfigurations/vladof/services/blog-contents`, which is all rights reserved.**


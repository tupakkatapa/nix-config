## My NixOS Configurations
| Hostname | System  | Format       | Users | Info                    
| :-:       |  :-:    | :-:          | :-:   | :-:
[torque](nixosConfigurations/torque/default.nix)  | x86_64  | persistent   | [kari](home-manager/kari/default.nix)  | AMD Desktop, Hyprland
[maliwan](nixosConfigurations/maliwan/default.nix) | x86_64  | persistent   | [kari](home-manager/kari/default.nix)  | Intel Laptop, Hyprland
[hyperion](nixosConfigurations/hyperion/default.nix) | aarch64  | nix-darwin | [kari (darwin)](home-manager/kari/darwin.nix)  | M2 Laptop, macOS Ventura
[jakobs](nixosConfigurations/jakobs/default.nix) | aarch64  | netboot | [kari (minimal)](home-manager/kari/minimal.nix)  | Rasberry Pi 4 Model B

## Resources
Here are some useful resources to learn about Nix and NixOS:

- [Nix Pills - Why You Should Give it a Try](https://nixos.org/guides/nix-pills/why-you-should-give-it-a-try.html)
- [Zero to Nix - Declarative programming](https://zero-to-nix.com/concepts/declarative)
- [NixOS Manual - Manual Installation](https://nixos.org/manual/nixos/stable/index.html#sec-installation-manual)
- [Misterio77 - Nix Starter Config](https://github.com/Misterio77/nix-starter-configs)
# Remote SSH, sudo and git signing with a local YubiKey

One `ssh-agent` on the desktop holds the key handle and gets forwarded to servers. Remote login, `sudo` and git signing all end up as PIN + touch on the key plugged into the desktop.

```
remote ssh / sudo / git sign  ->  forwarded socket  ->  local ssh-agent  ->  popup  ->  PIN + touch
```

## 1) Key

Create an `ed25519-sk` key with `-O verify-required`, see [setup-new-yubikey.md](setup-new-yubikey.md). `verify-required` is what makes every signature ask for the PIN.

## 2) Desktop (home-manager)

```nix
{ pkgs, ... }: {
  services.ssh-agent.enable = true;

  # Forwarded requests have no tty, so the agent prompts with a popup.
  # It starts before the compositor exports its display, hence the lookup.
  systemd.user.services.ssh-agent.Service.Environment = [
    "SSH_ASKPASS=${pkgs.writeShellScript "ssh-askpass-session" ''
      while IFS= read -r var; do export "$var"; done < <(
        ${pkgs.systemd}/bin/systemctl --user show-environment | ${pkgs.gnugrep}/bin/grep -E '^(WAYLAND_DISPLAY|DISPLAY)='
      )
      exec ${pkgs.lxqt.lxqt-openssh-askpass}/bin/lxqt-openssh-askpass "$@"
    ''}"
    "SSH_ASKPASS_REQUIRE=force"
  ];

  programs.ssh = {
    enable = true;
    settings = {
      "*" = {
        IdentityFile = [ "~/.ssh/id_ed25519_sk" ];
        AddKeysToAgent = "yes";
      };
      "<server>".ForwardAgent = true;
    };
  };

  programs.git.signing = {
    format = "ssh";
    key = "/home/<user>/.ssh/id_ed25519_sk";
    signByDefault = true;
  };
}
```

- `AddKeysToAgent`: the first `ssh` loads whichever key it used, before the remote shell exists, so the first session already forwards it
- Git signs through the agent when the key is loaded, otherwise straight from the key file

## 3) Server (NixOS)

```nix
{
  users.users.<user>.openssh.authorizedKeys.keys = [ "sk-ssh-ed25519@openssh.com AAAA... <comment>" ];

  security.pam.rssh = {
    enable = true;
    settings.auth_key_file = "/etc/ssh/authorized_keys.d/\${user}";
  };
  security.pam.services.sudo.rssh = true;

  # Commands under sudo keep the agent
  security.sudo.extraConfig = ''
    Defaults env_keep += "SSH_AUTH_SOCK"
  '';
}
```

- Same `authorized_keys` gates both login and sudo
- No `wheelNeedsPassword = false`, or sudo never asks
- Only `sk` keys in `authorized_keys`; a plain key passes sudo without a touch. Otherwise point `auth_key_file` at an sk-only file
- Git signing: no key file here, so use the public key and let the forwarded agent sign: `signing.key = "key::sk-ssh-ed25519@openssh.com AAAA..."`
- sshd forwards agents by default

## 4) Verify

```bash
ssh-add -D                   # start empty
ssh -O exit <server>         # drop a reused connection, else nothing gets loaded
ssh <server>                 # tty PIN + touch, key gets loaded
ssh-add -l                   # (server) forwarded key listed
sudo -k && sudo true         # (server) popup + touch
```

Signing: commit in a scratch repo on both ends, check with `git log --show-signature`.

Which PAM module let sudo in:
```bash
journalctl -g 'op=PAM:authentication' --since today
```
`grantors=libpam_rssh` = agent, `pam_u2f` = key in the local USB port, `pam_unix` = password.

---

## Prompts

| Situation | Prompt |
|---|---|
| Key not in agent yet (first local `ssh` or git sign) | PIN on the tty |
| Key in agent, local or remote | PIN in the popup |

## Gotchas

- **No display, no popup.** From a bare tty the agent can't prompt. Bypass it: `ssh -o IdentityAgent=none <host>` (no forwarding, remote sudo falls back to the password).
- **Agent fills on first `ssh`.** Tools that only talk to the agent (not `ssh`) see no key until then; `ssh-add` loads it by hand.
- **Forward only to hosts you trust.** Root there can use the socket; each signature still needs a touch, but the popup is the only warning.
- **Password still works** as the sudo fallback; keep it for when the key or agent is missing.

## In this repo

- Desktop: [`home-manager/users/kari/default.nix`](../home-manager/users/kari/default.nix); `ForwardAgent` per fleet host and `ControlPersist 10m` in [`minimal-dev.nix`](../home-manager/users/kari/minimal-dev.nix)
- Server: `pam_rssh` and `env_keep` in [`yubikey.nix`](../nixosConfigurations/.config/hw/yubikey.nix), every host
- `authorized_keys` still has the plain phone and 3ds keys, so those pass sudo without a touch

## References
- pam_rssh: https://github.com/z4yx/pam_rssh
- OpenSSH FIDO keys: https://man.openbsd.org/ssh-keygen#FIDO_AUTHENTICATOR
- Git SSH signing: https://git-scm.com/docs/git-config#Documentation/git-config.txt-gpgformat

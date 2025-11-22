
# Set up a new YubiKey for SSH + FIDO2 (age/agenix)

Quick shell with needed tools:

```bash
nix-shell -p yubikey-manager openssh age-plugin-fido2-hmac
```

## 1) Set/Change FIDO2 PIN on the YubiKey
```bash
ykman fido access change-pin --new-pin '<PIN>'
```

## 2) Create discoverable SSH keys (resident)
```bash
ssh-keygen -t ed25519-sk -O resident -O application=ssh:<hostname> -O verify-required
```
This writes `~/.ssh/id_ed25519_sk` and `~/.ssh/id_ed25519_sk.pub`; the private file references the secret on the YubiKey, the public file is the actual SSH public key.

## 3) Generate FIDO2 creds for agenix-rekey
```bash
age-plugin-fido2-hmac -g > ./master.hmac
```

---

## Recovery: re-extract resident SSH keys
```bash
ssh-keygen -K
```

## Change FIDO2 PIN (with current PIN)
```bash
ykman fido access change-pin --pin <current> --new-pin <new>
```

## References
- Discoverable SSH keys with YubiKey: https://feldspaten.org/2024/02/03/ssh-authentication-via-Yubikeys/#create-discoverable-keys
- FIDO2 age plugin: https://github.com/olastor/age-plugin-fido2-hmac

# tpm-host-key: one ed25519 host key derived at boot, sshd host key and agenix identity.
# Nothing secret is stored; the public key is committed as `age.rekey.hostPubkey`.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.tpmHostKey;
in
{
  options.services.tpmHostKey = {
    enable = lib.mkEnableOption "a host key derived from the TPM";
    package = lib.mkPackageOption pkgs "tpm-host-key" { };
    keyPath = lib.mkOption {
      type = lib.types.str;
      default = "/run/tpm-host-key/ssh_host_ed25519_key";
      description = "Where the derived private key is written at activation.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    system.activationScripts.tpmHostKey = {
      deps = [ "specialfs" ];
      text = ''
        if [ ! -e ${cfg.keyPath} ]; then
          install -d -m 700 ${dirOf cfg.keyPath}
          if (umask 077; ${lib.getExe cfg.package} ${cfg.keyPath}); then
            echo derived > /run/host-key-source
          else
            rm -f ${cfg.keyPath} ${cfg.keyPath}.pub
            echo "host key: derivation failed" >&2
            echo none > /run/host-key-source
          fi
        fi
      '';
    };
    system.activationScripts.agenixInstall.deps = [ "tpmHostKey" ];

    # Not in hostKeys: sshd's pre-start would generate a random key when derivation failed
    services.openssh = {
      hostKeys = [ ];
      extraConfig = "HostKey ${cfg.keyPath}";
    };
    age.identityPaths = [ cfg.keyPath ];
  };
}

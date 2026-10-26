# tpm-host-key: one ed25519 key derived from the TPM at every boot, serving as
# the sshd host key, the agenix identity and the remote-builder key. Nothing
# secret is stored; the public key is committed as `age.rekey.hostPubkey`.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.tpmHostKey;
  key = lib.escapeShellArg cfg.keyPath;
  status = "/run/tpm-host-key.status";
in
{
  options.services.tpmHostKey = {
    enable = lib.mkEnableOption "a host key derived from the TPM";
    package = lib.mkPackageOption pkgs "tpm-host-key" { };
    keyPath = lib.mkOption {
      type = lib.types.str;
      default = "/run/tpm-host-key/ssh_host_ed25519_key";
      description = "Where the private key is written at activation; the public key goes next to it with a .pub suffix.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Before agenix, which decrypts with this key
    system.activationScripts.tpmHostKey = {
      deps = [ "specialfs" ];
      text = ''
        if [[ ! -e ${key} ]]; then
          install -d -m 700 "$(dirname ${key})"
          # Runs before systemd; a wedged TPM must not hold the boot
          if output=$( (umask 077 && timeout 60 ${lib.getExe cfg.package} --verbose ${key}) 2>&1); then
            echo derived >${status}
          else
            printf 'failed, exit %s\n%s\n' "$?" "$output" >${status}
            rm -f ${key} ${key}.pub
          fi
        fi
      '';
    };
    system.activationScripts.agenixInstall.deps = [ "tpmHostKey" ];

    # Activation runs in the initrd, whose journal does not always survive
    # switch-root; /run does, so the outcome is replayed into the journal
    systemd.services.tpm-host-key-status = {
      description = "Report the TPM host key derivation";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${lib.getExe' pkgs.coreutils "cat"} ${status}";
      };
    };

    # Not in hostKeys: sshd's pre-start would generate a random key in place of
    # a failed derivation
    services.openssh = {
      hostKeys = [ ];
      extraConfig = "HostKey ${cfg.keyPath}";
    };
    age.identityPaths = [ cfg.keyPath ];
  };
}

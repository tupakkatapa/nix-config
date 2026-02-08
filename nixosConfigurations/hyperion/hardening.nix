{ lib, ... }:
{
  boot.kernel.sysctl = {
    # Kernel hardening
    "kernel.dmesg_restrict" = 1;
    "kernel.sysrq" = 0;
    "kernel.yama.ptrace_scope" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.perf_event_paranoid" = 2;
    "kernel.kexec_load_disabled" = 1;
    "dev.tty.ldisc_autoload" = 0;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;

    # Network hardening
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

    # IPv6 privacy
    "net.ipv6.conf.all.use_tempaddr" = lib.mkForce 2;
    "net.ipv6.conf.default.use_tempaddr" = lib.mkForce 2;
    "net.ipv6.conf.all.addr_gen_mode" = 3;
    "net.ipv6.conf.default.addr_gen_mode" = 3;

    # Fingerprinting protection
    "net.ipv4.tcp_timestamps" = 0;
    "net.ipv4.icmp_ratelimit" = 100;
    "net.ipv4.icmp_ratemask" = 6168;
  };

  # Disable core dumps
  systemd.coredump.enable = false;
  security.pam.loginLimits = [
    { domain = "*"; type = "hard"; item = "core"; value = "0"; }
  ];

  # SSH: don't auto-open port 22 globally; managed per-interface in firewall.nix
  services.openssh.openFirewall = false;

  # Blacklist uncommon network protocols (attack surface reduction)
  boot.blacklistedKernelModules = [ "dccp" "sctp" "rds" "tipc" ];
}

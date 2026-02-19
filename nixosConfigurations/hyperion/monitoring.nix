_: {
  services.monitoring = {
    enable = true;
  };

  # vnStat - monitors bandwidth usage
  services.vnstat.enable = true;

  # Static UID/GID for persistent storage
  users.users.vnstatd.uid = 993;
  users.groups.vnstatd.gid = 991;
}

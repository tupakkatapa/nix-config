_:
{
  # fail2ban configuration for SSH brute force protection
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "24h";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "10w";
      overalljails = true;
    };
  };
}

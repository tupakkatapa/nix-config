{
  pkgs,
  config,
  lib,
  ...
}: {
  # Message of the day
  programs.rust-motd = {
    enable = true;
    enableMotdInSSHD = true;
    settings = {
      banner = {
        color = "yellow";
        command = ''
          ${pkgs.inetutils}/bin/hostname | tr 'a-z' 'A-Z' | ${pkgs.figlet}/bin/figlet -f rectangles
          systemctl --failed --quiet
        '';
      };
      uptime.prefix = "Uptime:";
      last_login = builtins.listToAttrs (map (user: {
        name = user;
        value = 2;
      }) (builtins.attrNames config.home-manager.users));
    };
  };
}

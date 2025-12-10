{ pkgs, config, ... }:
let
  user = "core";
  optionalGroups = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  users.users."${user}" = {
    isNormalUser = true;
    group = user;
    extraGroups = optionalGroups [
      "audio"
      "users"
      "video"
      "wheel"
      "podman"
    ];
    openssh.authorizedKeys.keys = [
      # kari@phone (preferably removed, keep until YubiKey NFC for SSH is possible)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFKfmSYqFE+hXp/P1X8oqcpnUG9cx9ILzk4dqQzlEOC kari@phone"

      # kari@trezor
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPSvwAIfx+2EYVbr9eC2imb5NJgpn36v6XAeofQjg5BEAAAABHNzaDo= kari@trezor"

      # kari@yubikey
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOdsfK46X5IhxxEy81am6A8YnHo2rcF2qZ75cHOKG7ToAAAACHNzaDprYXJp ssh:kari"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOcS3prYIi5uC9LxscaKSYzyuF2Sh7f3I5V9s1sCWSc1AAAACXNzaDprYXJpMg== ssh:kari2"
    ];
    shell = pkgs.fish;
  };
  users.groups."${user}" = { };
  environment.shells = [ pkgs.fish ];
  programs.fish = {
    enable = true;
    shellAbbrs = {
      q = "exit";
      c = "clear";
      ka = "pkill";

      # Powerstate
      bios = "systemctl reboot --firmware-setup";
      sdn = "systemctl poweroff";
      rbt = "systemctl reboot";

      # Changing 'ls' to 'eza'
      ls = "eza -agl --color=always --group-directories-first";
      tree = "eza --git-ignore -T";

      # Rsync
      rcp = "rsync -PaL";
      rmv = "rsync -PaL --remove-source-files";

      # Adding flags
      df = "df -h";
      du = "du -h";
      mv = "mv -i";
      cp = "cp -ia";
      free = "free -h";
      grep = "grep --color=auto";
      jctl = "journalctl -p 3 -xb";

      # Nix
      nfc = "nix flake check --impure";
      gc = "nix-collect-garbage -d";

      # Misc
      vim = "nvim";
      lsd = "sudo du -Lhc --max-depth=0 *";
      rpg = "shuf -i 1024-65535 -n 1";
    };
  };

  # Autologin
  services.getty.autologinUser = "core";

  # Passwordless sudo
  security.sudo.extraRules = [{
    users = [ "core" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  # Install some packages
  environment.systemPackages = with pkgs; [
    btrfs-progs
    curl
    dhcpdump
    eza
    git
    inetutils
    jq
    kexec-tools
    lm_sensors
    lshw
    neovim
    parted
    pciutils
    rsync
    socat
    tmux
    wget
  ];
}

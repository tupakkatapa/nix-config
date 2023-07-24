{ pkgs, config, inputs, lib, ... }: with lib; {

  networking.hostName = "torque";
  networking.firewall.enable = false;
  time.timeZone = "Europe/Helsinki";
  system.stateVersion = "23.11";

  # AMD GPU
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

  # Use stable kernel
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  # Sound
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Connectivity
  hardware.bluetooth.enable = true;

  # Window manager
  home-manager.sharedModules = [
    inputs.hyprland.homeManagerModules.default
  ];

  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };
    waybar = {
      enable = true;
      package = pkgs.waybar.overrideAttrs (oa: {
        mesonFlags = (oa.mesonFlags or  [ ]) ++ [ "-Dexperimental=true" ];
      });
    };
    fish.loginShellInit = ''
      if test (tty) = "/dev/tty1"
        exec Hyprland &> /dev/null
      end
    '';
  };
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    LIBSEAT_BACKEND = "logind";
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";

    BROWSER = "librewolf";
    TERMINAL = "alacritty";
    EDITOR = "nvim";
  };

  # Firmware blobs
  hardware.enableRedistributableFirmware = true;
}

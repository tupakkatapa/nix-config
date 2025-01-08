# https://archive.org/details/retro-roms-best-set
{ pkgs, ... }:
let
  dataDir = "/mnt/sftp/games/Retroarch";

  myCores = libretro: with pkgs.libretro; [
    fbneo # SNK Neo Geo / Arcade
    dosbox # DOS
    mame2003-plus # Arcade
    stella # Atari 2600
    prosystem # Atari 7800
    genesis-plus-gx # Sega Genesis
    fceumm # NES
    snes9x # SNES
    mupen64plus # N64
    dolphin # GameCube / Wii
    gambatte # GB / GBC
    beetle-gba # GBA
    desmume # NDS
    beetle-pce-fast # NEC systems (TurboGrafx-16, PC Engine)
    pcsx2 # PS2
    beetle-psx-hw # PS1
    ppsspp # PSP
  ];
in
{
  environment.etc."retroarch.cfg".text = ''
    menu_driver = "xmb"
    xmb_menu_color_theme = "15"

    # Paths
    assets_directory = "${pkgs.retroarch-assets}/share/retroarch/assets"
    content_favorites_directory = "${dataDir}/playlists"
    content_favorites_path = "${dataDir}/playlists/content_favorites.lpl"
    playlist_directory = "${dataDir}/playlists"
    rgui_browser_directory = "${dataDir}/roms"
    savefile_directory = "${dataDir}/saves"
    savestate_directory = "${dataDir}/states"
    screenshot_directory = "${dataDir}/screenshots"
    system_directory = "${dataDir}/bios"
    thumbnails_directory = "${dataDir}/thumbnails"

    # Input settings
    # Xbox controllers have a remapping issue with the left analog stick; I have found this to be the case with Dolphin and PCSX2 emulators.
    # Try switching in "Settings" > "Input" > "Port 1 Controls" > "Analog to Digital Type" to either "None" or "Left Analog (forced)".
    # More info: https://www.reddit.com/r/retroid/comments/j64jru/left_joystick_not_working_within_games_on/
    auto_overrides_enable = "true"
    auto_remaps_enable = "true"
    enable_device_vibration = "true"
    input_autodetect_enable = "true"
    input_duty_cycle = "3"
    input_joypad_driver = "udev"
    input_max_users = "16"
    input_menu_toggle_gamepad_combo = "7" # hold start for quick menu
    menu_swap_ok_cancel_buttons = "true"

    playlist_entry_remove_enable = "0"
    playlist_entry_rename = "false"
  '';

  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "retroarch-with-cores-and-config";
      paths = [ (pkgs.retroarch.withCores myCores) ];
      nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
      postBuild = ''
        wrapProgram $out/bin/retroarch --add-flags "--appendconfig=/etc/retroarch.cfg"
      '';
    })
  ];
}

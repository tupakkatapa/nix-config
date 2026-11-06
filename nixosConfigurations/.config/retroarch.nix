# https://archive.org/details/retro-roms-best-set
# https://myrient.erista.me/files/No-Intro/
{ pkgs, share, ... }:
let
  cores = with pkgs.libretro; [
    mame # Arcade
    stella # Atari 2600
    dosbox # MS-DOS
    beetle-pce-fast # NEC PC Engine CD
    beetle-supergrafx # NEC TurboGrafx-16 (CD)
    beetle-pcfx # NEC PC-FX

    citra # 3DS
    melonds # NDS
    sameboy # GB / GBC
    mgba # GBA
    dolphin # GameCube / Wii
    mupen64plus # N64
    mesen # NES - Famicom
    bsnes # SNES

    flycast # Dreamcast
    genesis-plus-gx # Game Gear / Genesis / Master System / Sega CD
    beetle-saturn # Saturn

    swanstation # PS1
    pcsx2 # PS2
    ppsspp # PSP
  ];

  # Appended on top of the user config at every launch, so these always win
  settings = {
    menu_driver = "xmb";
    xmb_menu_color_theme = "15";

    # Paths
    assets_directory = "${pkgs.retroarch-assets}/share/retroarch/assets";
    rgui_browser_directory = "${share}/roms";
    rgui_config_directory = "${share}/config";
    input_remapping_directory = "${share}/config/remaps";
    system_directory = "${share}/bios";
    savefile_directory = "${share}/saves";
    savestate_directory = "${share}/states";
    screenshot_directory = "${share}/screenshots";
    playlist_directory = "${share}/playlists";
    thumbnails_directory = "${share}/thumbnails";
    cheat_database_path = "${share}/cheats";
    # SRAM is otherwise written on a clean exit only
    autosave_interval = "30";

    # Input settings
    # Xbox controllers have a remapping issue with the left analog stick; I have found this to be the case with Dolphin and PCSX2 emulators.
    # Try switching in "Settings" > "Input" > "Port 1 Controls" > "Analog to Digital Type" to either "None" or "Left Analog (forced)".
    # More info: https://www.reddit.com/r/retroid/comments/j64jru/left_joystick_not_working_within_games_on/
    auto_overrides_enable = "true";
    auto_remaps_enable = "true";
    enable_device_vibration = "true";
    input_autodetect_enable = "true";
    input_duty_cycle = "3";
    input_joypad_driver = "udev";
    input_max_users = "16";
    input_menu_toggle_gamepad_combo = "7"; # hold start for quick menu
    menu_swap_ok_cancel_buttons = "true";

    playlist_entry_remove_enable = "0";
    playlist_entry_rename = "false";
  };
in
{
  environment.systemPackages = [
    (pkgs.retroarch-bare.wrapper { inherit cores settings; })
  ];
}

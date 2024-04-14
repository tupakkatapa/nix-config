# https://archive.org/details/retro-roms-best-set
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (retroarch.override {
      cores = with libretro; [
        fbneo # SNK Neo Geo
        dosbox # DOS
        mame2003-plus # Arcade
        stella # Atari 2600
        prosystem # Atari 7800
        genesis-plus-gx # Sega

        fceumm # NES
        snes9x # SNES
        mupen64plus # N64
        dolphin # GameCube / Wii
        gambatte # GB / GBC
        beetle-gba # GBA
        desmume # NDS
        beetle-pce # NEC

        pcsx2 # PS2
        beetle-psx-hw # PS1
        ppsspp # PSP
      ];
      # settings = {
      #   menu_driver = "xmb";
      #   xmb_menu_color_theme = "15"; # cube purple
      #   assets_directory = "${super.retroarch-assets}/share/retroarch/assets";
      #   savefile_directory = "~/sync/games/saves";
      #   savestate_directory = "~/sync/games/states";
      #   screenshot_directory = "~/sync/games/screenshots";
      #   playlist_directory = "~/sync/games/playlists";
      #   thumbnails_directory = "~/sync/games/thumbnails";
      #   content_favorites_path = "~/sync/games/content_favorites.lpl";
      #   playlist_entry_remove_enable = "0";
      #   playlist_entry_rename = "false";
      #   input_menu_toggle_gamepad_combo = "7"; # hold start for quick menu
      #   menu_swap_ok_cancel_buttons = "true";
      #   auto_overrides_enable = "true"; # Auto setup controllers
      #   auto_remaps_enable = "true"; # Auto load past remaps
      # };
    })
  ];
}

---
date: "2025-05-04"
---

# I Hacked My 3DS

I've never owned the latest consoles, including all the Nintendo devices, apart from the GameBoy Advance, which I still have; I played the shit out of Pokémon Crystal with it back in the day. I've recently gotten back into retro gaming and started a quest to play all the older **Pokémon** games in 2025. I already finished **FireRed**, which I played on the **Lemuroid** emulator on my phone, which is a great emulator, by the way.

The plan was to play the rest of the games in this order: **Emerald**, **HeartGold**, and **Platinum**. At least those, and then the "newer ones": **White**, **White 2**, **Y**, and **UltraSun**, if I really got into it. In the middle of my Emerald playthrough, though, I began to wonder whether the next game, released for the DS, would be enjoyable on a phone. I tested it, and it really wasn't. The design of two screens crammed onto my phone screen, in addition to the buttons, is not the optimal way to enjoy those games. I immediately looked for an alternative and concluded that some version of the 3DS was the best way to go.

I casually asked a friend if he had a 3DS lying around. Fortunately for me, he actually did; an Original 3DS in Cosmic Black. But it was dead, so I had to fix it first. When plugged in, there were no lights or any signs of life. I suspected a faulty charger or power connector, but after opening up the device, checking voltages and fuses, everything looked fine. A bit of research revealed that the 3DS won't power on if the battery is completely dead, even while charging. I ordered a new battery for €20, installed it, and luckily it worked. Time to mod it.

iFixit has some great guides on taking the thing apart [https://www.ifixit.com/Device/Nintendo\_3DS](https://www.ifixit.com/Device/Nintendo_3DS)

## Modding the 3DS

I basically just followed the guide at [https://3ds.hacks.guide/](https://3ds.hacks.guide/) to the letter, which is a great resource, but I couldn't get it working on Linux. After a few hours, I gave up and gave in to the burden of installing Windows (Tiny11) on my laptop, since I don't have a single machine with Windows in my household. From then on, everything worked like a charm:

1. **Format the SD card**: [Formatting SD (Windows)](https://3ds.hacks.guide/formatting-sd-%28windows%29.html) as FAT32 with a 32 KB cluster size.

  > Note: Changed to bigger SD card later, formatted with Linux: `sudo mkfs.fat /dev/sdX -s 64 -F 32 -I`

2. **Flash the firmware**: [Installing boot9strap (MSET9 CLI)](https://3ds.hacks.guide/installing-boot9strap-%28mset9-cli%29.html).

3. **Installing core apps**: [Finalizing Setup](https://3ds.hacks.guide/finalizing-setup.html)

   - **GodMode9**: full‑access file browser (hold **Start** while powering on)
   - **Universal-Updater**: "store" for homebrew applications
   - **Checkpoint**: save-game manager, with cheats
   - **ftpd**: slow as fuck (~450 KB/s) FTP server for transferring files without removing the SD card
   - **Anemone3DS**: theming manager
   - **Homebrew Launcher**: lists and launches homebrew applications
   - **FBI**: installs and manages CIA packages

   The guide provides all of these in just a couple of files, which is pretty awesome.

4. **Install additional apps**

   *Via Universal-Updater*

   - **TWiLight Menu++**: emulator, runs original DS games and whatnot
   - **ndsForwarder**: creates Home Menu shortcuts for DS games stored in TWiLight Menu++ (appears under Homebrew Launcher)
   - **open\_agb\_firm**: much better, native way to play GBA games (accessible through GodMode9)
   - **wumiibo**: amiibo emulation (haven't tried it yet)

   *Via FBI (scan the QR)*

   - **hShop**: totally legal game store: [https://hshop.erista.me/3hs](https://hshop.erista.me/3hs)

   At this point, make a backup. A lightweight copy you can restore later. Since a modded 3DS is mostly reproducible (apart from the initial firmware flash), switching to a bigger SD card is as simple as formatting it and copying the files over.

5. **Ricing**

   - **Themes**: Open Anemone3DS on your 3DS and browse [Theme Plaza](https://themeplaza.art/themes) on another device. Scan the QR code of the theme you want to install.
   - **Splash screens**: images shown on the screens during startup; install them the same way as themes.
   - **Badges**: PNGs that can be attached to folders or placed on the HOME Menu grid. Download a badge pack from Theme Plaza, extract it, delete any preview files, copy the folder to `/Badges` on the SD card, then install via Anemone3DS.

6. **Getting the games**

   You can find them at [Myrient](https://myrient.erista.me/files/No-Intro/) (at your own risk) or install directly via hShop.

   - **3DS games**: copy them to the SD card, install via GodMode9, then delete the originals to free up space. These will be installed encrypted under `/Nintendo 3DS/<ID0>/<ID1>/title`. Ref: https://3dbrew.org/wiki/SD_Filesystem.
   - **GBA games**: store them in `/3ds/open_agb_firm/roms` and launch with open\_agb\_firm via GodMode9.
   - **NDS games**: place them in `/roms/nds` for use with TWiLight Menu++.

## Tips for particular games

### Ace Attorney

The trilogy exists on the original DS, but there's a remake with fixes and better graphics released on the 3DS. If you'd prefer that, grab it instead. It's available on hShop.

### Final Fantasy & Fire Emblem

These series have an overwhelming number of games, and it's hard to grasp where to start.

Quote from: [Final Fantasy - "Where Should I Start?"](https://www.reddit.com/r/FinalFantasy/wiki/wheretostart/) - Reddit Wiki
> Think of Final Fantasy as more of a "collection" of separate stories, and not a "series." Since the main titles are not related to each other, when it comes to the numbered entries, you can start with any game you want.

Quote from: [Fire Emblem - "New to the series, where should I start?"](https://www.reddit.com/r/fireemblem/comments/5s5nh1/new_to_the_series_where_should_i_start_the/) - Reddit Post
> Here is a nice masterlist of every game in the series, separated by world, so you can easily tell which games are connected to each other.

### Pokémon Picross

Great game, but it has a pay-to-play element we need to tackle. The game has these so-called 'Picrites' which you have to grind hard for, or just purchase at the eShop (of course). Since the eShop no longer exists, the pay-to-play aspect is broken, and we can fix this by using cheats. Open Checkpoint, select your game, click on cheats, and enable 'Maximum Picrites'. Then launch the game and press 'L + Down + Select' to open Luma3DS's Rosalina menu and enable cheats. Bon appétit — actually playable now.

By the way, this game is hard to find anywhere other than hShop, so install it from there.

### Games over 4GB

FAT32 has a 4GB file size limit due to its file allocation table structure. Either [convert](https://github.com/ihaveamac/3dsconv) to CIA packages since they are smaller, install remotely from hShop, or trim the ROM using 3DSExplorer.


---

That's it! The 3DS is fantastic, and I've been enjoying mine so far!

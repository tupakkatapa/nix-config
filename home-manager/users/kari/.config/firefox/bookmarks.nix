[{
  name = "toolbar";
  toolbar = true;
  bookmarks = [
    {
      name = "Services";
      bookmarks = [
        {
          name = "Self-Hosted";
          bookmarks = [
            { name = "Hyperion"; url = "https://10.42.0.1"; }
            { name = "Netboot"; url = "http://10.42.0.1:52080/"; }
            { name = "Grafana"; url = "https://grafana.coditon.com"; }
            { name = "Home Assistant"; url = "https://home.coditon.com"; }
            { name = "Radicale"; url = "https://dav.coditon.com/"; }
            { name = "Plex"; url = "https://plex.coditon.com"; }
            { name = "Torrent"; url = "https://torrent.coditon.com"; }
            { name = "Ollama"; url = "https://chat.coditon.com/"; }
            { name = "Blog"; url = "https://blog.coditon.com"; }
            { name = "Index"; url = "https://index.coditon.com"; }
            { name = "Vaultwarden"; url = "https://vault.coditon.com"; }
            { name = "Kavita"; url = "https://lib.coditon.com"; }
            { name = "Search"; url = "https://search.coditon.com"; }
            { name = "Nextcloud"; url = "https://next.coditon.com"; }
            { name = "Cert"; url = "https://cert.coditon.com"; }
            { name = "Claude-Mem"; url = "http://127.0.0.1:37777/"; }
          ];
        }
        {
          name = "Email";
          bookmarks = [
            { name = "Outlook"; url = "https://outlook.live.com/mail"; }
            { name = "Ponkila Mail"; url = "https://mail.ponkila.com/"; }
            { name = "Protonmail"; url = "https://account.proton.me/mail"; }
            { name = "Gmail"; url = "https://mail.google.com/"; }
          ];
        }
        {
          name = "Communication";
          bookmarks = [
            { name = "WhatsApp"; url = "https://web.whatsapp.com/"; }
            { name = "Discord"; url = "https://discord.com/app"; }
            { name = "Telegram"; url = "https://web.telegram.org/"; }
            { name = "Element"; url = "https://app.element.io/"; }
            { name = "Slack"; url = "https://app.slack.com/"; }
          ];
        }
        {
          name = "Social";
          bookmarks = [
            { name = "X"; url = "https://x.com/"; }
          ];
        }
        {
          name = "Cloud & Infrastructure";
          bookmarks = [
            { name = "Cloudflare"; url = "https://dash.cloudflare.com/"; }
            { name = "Hetzner"; url = "https://console.hetzner.cloud"; }
            { name = "Spaceship"; url = "https://www.spaceship.com/"; }
            { name = "Domaincompare"; url = "https://www.domaincompare.io/"; }
            { name = "GoDaddy"; url = "https://www.godaddy.com/"; }
          ];
        }
        {
          name = "Google";
          bookmarks = [
            { name = "Drive"; url = "https://drive.google.com/"; }
            { name = "Calendar"; url = "https://calendar.google.com/"; }
            { name = "Gmail"; url = "https://mail.google.com/"; }
            { name = "Cloud Console"; url = "https://console.cloud.google.com/"; }
            { name = "Admin"; url = "https://admin.google.com/"; }
            { name = "Gemini"; url = "https://gemini.google.com/"; }
          ];
        }
      ];
    }
    {
      name = "Development";
      bookmarks = [
        {
          name = "Git";
          bookmarks = [
            { name = "GitHub"; url = "https://github.com/"; }
            { name = "GitLab"; url = "https://gitlab.com/"; }
          ];
        }
        {
          name = "Nix";
          bookmarks = [
            {
              name = "Nix Reference Manual";
              bookmarks = [
                { name = "Built-in Functions"; url = "https://nixos.org/manual/nix/unstable/language/builtins.html"; }
                { name = "Data Types"; url = "https://nixos.org/manual/nix/unstable/language/values.html"; }
                { name = "Operators"; url = "https://nixos.org/manual/nix/unstable/language/operators.html"; }
              ];
            }
            {
              name = "Nixpkgs Manual";
              bookmarks = [
                { name = "lib.attrsets"; url = "https://nixos.org/manual/nixpkgs/unstable/#sec-functions-library-attrsets"; }
              ];
            }
            { name = "NixOS Search Options"; url = "https://search.nixos.org/options?"; }
            { name = "NixOS Search Packages"; url = "https://search.nixos.org/packages?"; }
            { name = "Nixpkgs Issues"; url = "https://github.com/NixOS/nixpkgs/issues"; }
            { name = "Home Manager Search"; url = "https://home-manager-options.extranix.com/"; }
            { name = "NixOS Wiki"; url = "https://nixos.wiki/"; }
            { name = "Flake Parts"; url = "https://flake.parts/"; }
            { name = "Nixvim docs"; url = "https://nix-community.github.io/nixvim/"; }
            { name = "Nix (builtins) & Nixpkgs (lib) Functions"; url = "https://teu5us.github.io/nix-lib.html"; }
            { name = "Zero to Nix"; url = "https://zero-to-nix.com/"; }
          ];
        }
        {
          name = "Documentation";
          bookmarks = [
            { name = "Kernel Config Search"; url = "https://www.kernelconfig.io/index.html"; }
            { name = "Vimium"; url = "https://vimium.github.io/"; }
            { name = "Vim Cheat Sheet"; url = "https://vim.rtorr.com/"; }
            { name = "Kea DHCP"; url = "https://kea.readthedocs.io/en/kea-2.2.0/arm/dhcp4-srv.html"; }
            { name = "Hyprland"; url = "https://wiki.hyprland.org/"; }
            { name = "Waybar"; url = "https://github.com/Alexays/Waybar/wiki"; }
            { name = "iPXE"; url = "https://ipxe.org/docs"; }
            { name = "Bash Reference Manual"; url = "https://www.gnu.org/software/bash/manual/html_node/index.html#SEC_Contents"; }
            { name = "rEFInd Boot Manager"; url = "http://www.rodsbooks.com/refind/index.html"; }
            { name = "git-send-email.io"; url = "https://git-send-email.io/"; }
            { name = "lore.kernel.org"; url = "https://lore.kernel.org/"; }
            { name = "CommandLineFu"; url = "https://www.commandlinefu.com/"; }
            { name = "ExplainShell"; url = "https://explainshell.com/"; }
          ];
        }
        {
          name = "DevOps";
          bookmarks = [
            { name = "System Initiative"; url = "https://www.systeminit.com/"; }
            { name = "Radicle"; url = "https://radicle.xyz/"; }
            { name = "Oxide Computer"; url = "https://oxide.computer/"; }
            { name = "Netdata"; url = "https://www.netdata.cloud/"; }
            { name = "Pulumi"; url = "https://www.pulumi.com/"; }
            { name = "Doppler"; url = "https://www.doppler.com/"; }
            { name = "n8n"; url = "https://n8n.io/"; }
            { name = "RunPod"; url = "https://www.runpod.io/"; }
            { name = "Sentry"; url = "https://sentry.io/"; }
          ];
        }
        {
          name = "Rust";
          bookmarks = [
            { name = "Crates.io"; url = "https://crates.io/"; }
            { name = "Rust Language Cheat Sheet"; url = "https://cheats.rs/"; }
            { name = "Learn Rust"; url = "https://www.rust-lang.org/learn"; }
          ];
        }
        {
          name = "Security";
          bookmarks = [
            { name = "Exploit-DB"; url = "https://www.exploit-db.com/"; }
            { name = "Have I Been Pwned"; url = "https://haveibeenpwned.com/"; }
          ];
        }
      ];
    }
    {
      name = "Media";
      bookmarks = [
        {
          name = "Torrents";
          bookmarks = [
            { name = "TorrentDay"; url = "https://www.torrentday.com/t"; }
            { name = "Nyaa"; url = "https://nyaa.si/"; }
            { name = "rutracker"; url = "https://rutracker.org/forum/index.php"; }
            { name = "YIFY"; url = "https://yts.mx/"; }
            { name = "FitGirl Repacks"; url = "https://fitgirl-repacks.site"; }
            { name = "1337x"; url = "https://1337x.to/"; }
            { name = "NAPALM FTP Indexer"; url = "https://www.searchftps.net/"; }
            { name = "Mobilism"; url = "https://forum.mobilism.org/"; }
            { name = "Myrient"; url = "https://myrient.erista.me/files/"; }
          ];
        }
        {
          name = "Videos & Streaming";
          bookmarks = [
            { name = "YouTube"; url = "https://www.youtube.com/feed/subscriptions"; }
            { name = "Twitch"; url = "https://www.twitch.tv/"; }
            { name = "Kick"; url = "https://kick.com/"; }
          ];
        }
        {
          name = "Games";
          bookmarks = [
            { name = "G2A"; url = "https://www.g2a.com/"; }
            { name = "Steam"; url = "https://store.steampowered.com/"; }
            { name = "SteamDB"; url = "https://steamdb.info/sales/"; }
            { name = "Zophar"; url = "https://www.zophar.net/"; }
          ];
        }
        {
          name = "Literature";
          bookmarks = [
            { name = "Sci-Hub"; url = "https://sci-hub.se/"; }
            { name = "Anna's Archive"; url = "https://annas-archive.org/"; }
            { name = "Internet Archive"; url = "https://archive.org/"; }
            { name = "ResearchGate"; url = "https://www.researchgate.net/"; }
            { name = "Google Scholar"; url = "https://scholar.google.com/"; }
            { name = "Kansalliskirjasto"; url = "https://digi.kansalliskirjasto.fi/etusivu"; }
          ];
        }
        {
          name = "Anime";
          bookmarks = [
            { name = "MAL"; url = "https://myanimelist.net/"; }
            { name = "EverythingMoe"; url = "https://everythingmoe.com/"; }
          ];
        }
        {
          name = "Fun";
          bookmarks = [
            { name = "xkcd"; url = "https://xkcd.com/"; }
            { name = "Radio Garden"; url = "https://radio.garden/"; }
          ];
        }
      ];
    }
    {
      name = "Tools";
      bookmarks = [
        {
          name = "Collab";
          bookmarks = [
            { name = "Notion"; url = "https://www.notion.com/"; }
            { name = "Miro"; url = "https://miro.com"; }
            { name = "Linear"; url = "https://linear.app/"; }
          ];
        }
        {
          name = "Privacy";
          bookmarks = [
            { name = "Temp-num"; url = "https://quackr.io/temporary-numbers"; }
            { name = "Temp-mail"; url = "https://temp-mail.org/en/"; }
          ];
        }
        {
          name = "Design & Creative";
          bookmarks = [
            { name = "Excalidraw"; url = "https://excalidraw.com/"; }
            { name = "FIGlet"; url = "https://patorjk.com/software/taag"; }
            { name = "Favicon.io"; url = "https://favicon.io/"; }
            { name = "Font Awesome"; url = "https://fontawesome.com/icons"; }
            { name = "Tech Icons"; url = "https://techicons.dev/"; }
            { name = "Nerdfonts Symbols"; url = "https://www.nerdfonts.com/cheat-sheet"; }
          ];
        }
        {
          name = "Music";
          bookmarks = [
            {
              name = "Tools";
              bookmarks = [
                { name = "Metronome"; url = "https://metronom.us/en/"; }
                { name = "Guitar Scale"; url = "https://guitarscale.org/bass/index.html"; }
                { name = "Tap Tempo"; url = "https://taptempo.io/"; }
                { name = "MusMath"; url = "https://www.musmath.com/tools/scale-lookup/bass-guitar"; }
              ];
            }
            {
              name = "Backtracks";
              bookmarks = [
                { name = "Backing Tracks"; url = "https://www.youtube.com/@BackingTracksForBass/videos"; }
                { name = "F# Minor"; url = "https://www.youtube.com/watch?v=hLjhM-S4B3o"; }
                { name = "D Dorian"; url = "https://www.youtube.com/watch?v=z75ZVfpPaZk"; }
                { name = "63 BPM"; url = "https://www.youtube.com/watch?v=GhM_MJEB7e0"; }
                { name = "65 BPM"; url = "https://www.youtube.com/watch?v=RNvxvwc0cWQ"; }
                { name = "75 BPM"; url = "https://www.youtube.com/watch?v=r3xzzBis9RI"; }
                { name = "80 BPM"; url = "https://www.youtube.com/watch?v=2fqzbwsy4nA"; }
                { name = "85 BPM"; url = "https://www.youtube.com/watch?v=yamlK-3d-XM"; }
                { name = "95 BPM"; url = "https://www.youtube.com/watch?v=OK1bcvAad4U"; }
                { name = "105 BPM"; url = "https://www.youtube.com/watch?v=jtRSVeqbOlQ"; }
                { name = "115 BPM"; url = "https://www.youtube.com/watch?v=m4EQFgC3k_M"; }
                { name = "125 BPM"; url = "https://www.youtube.com/watch?v=qO4qlPJi8Ic"; }
                { name = "135 BPM"; url = "https://www.youtube.com/watch?v=2INSl9YzMB4"; }
                { name = "145 BPM"; url = "https://www.youtube.com/watch?v=-2ubWypOT98"; }
                { name = "155 BPM"; url = "https://www.youtube.com/watch?v=qRXkX-fEbEA"; }
                { name = "165 BPM"; url = "https://www.youtube.com/watch?v=5-nrgYle0EY"; }
              ];
            }
          ];
        }
        {
          name = "AI";
          bookmarks = [
            { name = "ChatGPT"; url = "https://chat.openai.com/?model=gpt-4o"; }
            { name = "Claude"; url = "https://claude.ai/"; }
            { name = "Microsoft Copilot"; url = "https://copilot.microsoft.com/"; }
            { name = "Grok"; url = "https://grok.com/"; }
            { name = "HuggingFace"; url = "https://huggingface.co/models"; }
            { name = "Ollama"; url = "https://ollama.com/library"; }
          ];
        }
        {
          name = "Utilities";
          bookmarks = [
            { name = "APKCombo"; url = "https://apkcombo.com/downloader/"; }
            { name = "DocHub"; url = "https://dochub.com/"; }
            { name = "DeepL"; url = "https://www.deepl.com/translator"; }
            { name = "Google Translate"; url = "https://translate.google.com/"; }
            { name = "CroxyProxy"; url = "https://www.croxyproxy.com/"; }
            { name = "MD to PDF Converter"; url = "https://cloudconvert.com/md-to-pdf"; }
            { name = "Downdetector"; url = "https://downdetector.com/"; }
            { name = "MyTime"; url = "https://mytime.io/"; }
            { name = "Word2Markdown"; url = "https://word2md.com/"; }
          ];
        }
        {
          name = "Travel";
          bookmarks = [
            { name = "Skyscanner"; url = "https://www.skyscanner.fi/lennot"; }
          ];
        }
      ];
    }
    {
      name = "Finance";
      bookmarks = [
        {
          name = "Banking & Money";
          bookmarks = [
            { name = "Wise"; url = "https://wise.com/"; }
            { name = "Danske Bank"; url = "https://danskebank.com/"; }
            { name = "OP"; url = "https://www.op.fi/"; }
            { name = "Rotki"; url = "https://rotki.com/"; }
          ];
        }
        {
          name = "Bills & Utilities";
          bookmarks = [
            { name = "DNA"; url = "https://www.dna.fi/"; }
            { name = "Oomi"; url = "https://oomi.fi/"; }
            { name = "Vero"; url = "https://vero.fi"; }
          ];
        }
        {
          name = "Markets";
          bookmarks = [
            { name = "FinViz Map"; url = "https://finviz.com/map.ashx?t=sec"; }
          ];
        }
        {
          name = "Shopping";
          bookmarks = [
            { name = "Amazon"; url = "https://www.amazon.de/"; }
            { name = "Crucial"; url = "https://www.crucial.com/"; }
            { name = "Verkkokauppa"; url = "https://www.verkkokauppa.com/fi/etusivu"; }
            { name = "Jimms"; url = "https://www.jimms.fi/"; }
            { name = "Ebay"; url = "https://www.ebay.com/"; }
            { name = "n-o-d-e"; url = "https://n-o-d-e.shop/"; }
            { name = "Proshop"; url = "https://www.proshop.fi/"; }
            { name = "Zalando"; url = "https://www.zalando.fi/"; }
            { name = "IKEA"; url = "https://www.ikea.com/fi/fi/"; }
            { name = "Wolt"; url = "https://wolt.com/fi/discovery"; }
            { name = "Revolutionrace"; url = "https://www.revolutionrace.eu/"; }
            { name = "Cotopaxi"; url = "https://eu.cotopaxi.com/en"; }
            { name = "Disks & Storage"; url = "https://diskprices.com/?locale=de&condition=new&disk_types=internal_hdd"; }
            { name = "RAM Sticks"; url = "https://ramstickprices.com/"; }
            { name = "Superdry"; url = "https://www.superdry.fi/"; }
            { name = "Kava Europe"; url = "https://kavaeurope.eu/"; }
          ];
        }
        {
          name = "Crypto";
          bookmarks = [
            {
              name = "Exchanges";
              bookmarks = [
                { name = "Binance"; url = "https://www.binance.com/en"; }
                { name = "Coinbase"; url = "https://www.coinbase.com/home"; }
                { name = "CoinMarketCap"; url = "https://coinmarketcap.com/"; }
              ];
            }
            {
              name = "Block Explorers";
              bookmarks = [
                { name = "BscScan"; url = "https://bscscan.com/"; }
                { name = "BtcScan"; url = "https://btcscan.org/"; }
                { name = "EtherScan"; url = "https://etherscan.io/"; }
              ];
            }
            {
              name = "Ethereum";
              bookmarks = [
                { name = "Client Diversity"; url = "https://clientdiversity.org/"; }
                {
                  name = "Clients";
                  bookmarks = [
                    { name = "Prysm CLI"; url = "https://docs.prylabs.network/docs/prysm-usage/parameters"; }
                    { name = "Reth CLI"; url = "https://reth.rs/cli/reth/node.html"; }
                    { name = "Nimbus CLI"; url = "https://nimbus.guide/options.html"; }
                    { name = "Teku CLI"; url = "https://docs.teku.consensys.io/reference/cli"; }
                    { name = "Lighthouse CLI"; url = "https://lighthouse-book.sigmaprime.io/help_bn.html"; }
                    { name = "MEV-Boost CLI"; url = "https://github.com/flashbots/mev-boost#mev-boost-cli-arguments"; }
                    { name = "Besu CLI"; url = "https://besu.hyperledger.org/stable/public-networks/reference/cli/options"; }
                    { name = "Nethermind CLI"; url = "https://docs.nethermind.io/fundamentals/configuration#basic-command-line-options"; }
                    { name = "Geth CLI"; url = "https://geth.ethereum.org/docs/fundamentals/command-line-options"; }
                    { name = "Erigon CLI"; url = "https://erigon.gitbook.io/erigon/advanced-usage/options"; }
                    { name = "SSV node"; url = "https://docs.ssv.network/run-a-node/operator-node/installation#create-configuration-file"; }
                  ];
                }
              ];
            }
          ];
        }
      ];
    }
    {
      name = "Information";
      bookmarks = [
        {
          name = "News";
          bookmarks = [
            { name = "Media Bias Chart"; url = "https://app.adfontesmedia.com/chart/interactive"; }
            { name = "Reuters"; url = "https://www.reuters.com/"; }
            { name = "AP"; url = "https://apnews.com/"; }
            { name = "WSJ"; url = "https://www.wsj.com/"; }
            { name = "BBC"; url = "https://www.bbc.com/"; }
          ];
        }
        {
          name = "Forums";
          bookmarks = [
            { name = "Hacker News"; url = "https://news.ycombinator.com/news"; }
            { name = "Lobsters"; url = "https://lobste.rs/"; }
            { name = "Ylilauta"; url = "https://ylilauta.org/thread/"; }
            { name = "4chan"; url = "https://www.4chan.org/"; }
            { name = "2ch"; url = "https://2ch.hk/"; }
          ];
        }
        {
          name = "Reference";
          bookmarks = [
            { name = "Cambridge Dictionary"; url = "https://dictionary.cambridge.org/dictionary/"; }
          ];
        }
        {
          name = "Space Weather";
          bookmarks = [
            { name = "SpaceWeatherLive"; url = "https://www.spaceweatherlive.com/"; }
            { name = "WSA-Enlil"; url = "https://www.swpc.noaa.gov/products/wsa-enlil-solar-wind-prediction"; }
            { name = "SDO"; url = "https://sdo.gsfc.nasa.gov/data/"; }
            { name = "Downdetector"; url = "https://downdetector.com/"; }
          ];
        }
        {
          name = "Weather";
          bookmarks = [
            { name = "Foreca"; url = "https://www.foreca.fi/Finland/Oulu"; }
          ];
        }
        {
          name = "Search";
          bookmarks = [
            { name = "Qwant"; url = "https://www.qwant.com/"; }
          ];
        }
      ];
    }
  ];
}]

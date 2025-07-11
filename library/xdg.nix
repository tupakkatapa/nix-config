{ lib, ... }:

let
  # Embedded MIME type definitions
  mimes = {
    audio = [
      "audio/aac"
      "audio/flac"
      "audio/mp3"
      "audio/mpeg"
      "audio/ogg"
      "audio/opus"
      "audio/wav"
      "audio/webm"
      "audio/x-matroska"
    ];
    archive = [
      "application/bzip2"
      "application/gzip"
      "application/vnd.rar"
      "application/x-7z-compressed"
      "application/x-7z-compressed-tar"
      "application/x-bzip"
      "application/x-bzip-compressed-tar"
      "application/x-compress"
      "application/x-compressed-tar"
      "application/x-cpio"
      "application/x-gzip"
      "application/x-lha"
      "application/x-lzip"
      "application/x-lzip-compressed-tar"
      "application/x-lzma"
      "application/x-lzma-compressed-tar"
      "application/x-tar"
      "application/x-tarz"
      "application/x-xar"
      "application/x-xz"
      "application/x-xz-compressed-tar"
      "application/zip"
    ];
    browser = [
      "text/html"
      "x-scheme-handler/about"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/unknown"
    ];
    calendar = [
      "text/calendar"
      "x-scheme-handler/webcal"
    ];
    directory = [
      "inode/directory"
    ];
    image = [
      "image/bmp"
      "image/gif"
      "image/heic"
      "image/heif"
      "image/jpeg"
      "image/jpg"
      "image/png"
      "image/svg+xml"
      "image/tiff"
      "image/vnd.microsoft.icon"
      "image/webp"
    ];
    magnet = [
      "x-scheme-handler/magnet"
    ];
    mail = [
      "x-scheme-handler/mailto"
    ];
    markdown = [
      "text/markdown"
    ];
    office = {
      spreadsheet = [
        "application/vnd.ms-excel"
        "application/vnd.oasis.opendocument.spreadsheet"
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        "text/csv"
      ];
      presentation = [
        "application/vnd.ms-powerpoint"
        "application/vnd.oasis.opendocument.presentation"
        "application/vnd.openxmlformats-officedocument.presentationml.presentation"
      ];
      text = [
        "application/msword"
        "application/vnd.oasis.opendocument.text"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      ];
    };
    pdf = [
      "application/pdf"
      "application/x-pdf"
    ];
    ebook = [
      "application/epub+zip"
      "application/vnd.amazon.ebook"
    ];
    comic = [
      "application/vnd.comicbook+rar"
      "application/vnd.comicbook+zip"
      "application/x-cbr"
      "application/x-cbz"
    ];
    text = [
      "text/plain"
    ];
    video = [
      "video/mp2t"
      "video/mp4"
      "video/mpeg"
      "video/ogg"
      "video/quicktime"
      "video/webm"
      "video/x-flv"
      "video/x-matroska"
      "video/x-ms-wmv"
      "video/x-msvideo"
    ];
  };
in
{
  # Function to create MIME associations
  createMimes = optionRaw:
    let
      # Internal helper to flatten nested attrsets like { office.text = [ … ] }
      flattenAttrs =
        let
          flatten' = prefix: attrs:
            lib.concatMapAttrs
              (k: v:
                if lib.isAttrs v then
                  flatten' (prefix ++ [ k ]) v
                else
                  { "${lib.concatStringsSep "." (prefix ++ [k])}" = v; }
              )
              attrs;
        in
        flatten' [ ];

      # Flattened option attrset (e.g. { "office.text" = [ … ] })
      option = flattenAttrs optionRaw;
    in
    # Construct the final MIME type -> application map
    lib.listToAttrs (lib.flatten (lib.mapAttrsToList
      (name: types:
        if lib.hasAttr name option then
          map (type: lib.nameValuePair type option.${name}) types
        else
          [ ]
      )
      mimes));
}

---
name: yt-clip
description: Extract a short clip from a YouTube video. Invoke when the user wants a clip pulled out of a YouTube URL — they may supply a rough timestamp, a quoted line, or both, and the inputs may be inexact. Locates the target via subtitle search, confirms the range, then downloads and transcodes to mp4.
---

# YouTube Clip Extraction

## Overview

User provides a YouTube URL plus *hints* about which part to clip. Hints come in three shapes:

1. **Timestamp** (e.g. `t=1807s`, "around 30:00", or implicit via `?t=` in the URL). Often inaccurate; the user may have linked the wrong spot in the video.
2. **Quote / line** (e.g. "the part where he says 'I don't care if you are a dog'"). Often paraphrased; the actual subtitle may differ in punctuation or word order.
3. **Both** — most reliable, but you still need to verify.

The job is to *locate the real range from the actual subtitles*, not trust the hints blindly.

## Tooling

- `yt-dlp` for subtitle fetching + section downloading. Available via `nix run nixpkgs#yt-dlp` if not in PATH.
- `ffmpeg` for transcode to mp4. Available via `nix run nixpkgs#ffmpeg`.
- YouTube often blocks unauthenticated bot traffic — pass `--cookies-from-browser firefox` if the first attempt fails with a "Sign in to confirm you're not a bot" error.

## Procedure

### 1. Parse the URL

Strip tracking params, keep the video ID (`v=...`) and timestamp (`t=...` if present). Note the timestamp as a *hint*, not gospel.

### 2. Fetch subtitles

```bash
nix run nixpkgs#yt-dlp -- \
  --write-auto-subs --skip-download \
  --sub-format vtt --sub-langs en \
  --cookies-from-browser firefox \
  -o "/tmp/%(id)s.%(ext)s" \
  "<URL>"
```

The output is `/tmp/<video-id>.en.vtt`. Skip `--cookies-from-browser` first; add it on retry only if YouTube refuses.

If only non-English subtitles are available, fall back to whatever language ships — the user can usually still recognise the quote if they know the language.

### 3. Locate the target

**If the user gave a quote:**
- Lower-case + strip punctuation from both the query and the subtitle text.
- `grep -B1 -i` against the VTT for distinctive words (pick the most-unique noun or verb — "dog" beats "the"). Multiple hits → show each with timestamp + surrounding context.
- The subtitle text may split words across cues; read the cue *before* and *after* a match to recover the full sentence.

**If the user gave a timestamp:**
- Show the cues in a ±60 s window around the hint. Quote 3–5 of them with timestamps to the user for disambiguation.

**If both:**
- Search the ±2 min window around the hinted timestamp for the quote first; only widen to the whole video if the local window doesn't match. The hint *narrows*; it doesn't *commit*.

**No match anywhere:**
- Tell the user the quote isn't in the auto-subs. Possible causes: paraphrase too loose, captions missing for that segment, wrong video. Ask for a tighter quote or a timestamp.

### 4. Decide the cut range

- Find the *start* of the natural sentence containing the quote — back up to the previous cue boundary or full-stop, whichever is closer.
- Find the *end* of the sentence or thought — the next full-stop, or whatever the user explicitly asked for ("the next sentence too" extends through the following thought).
- Pad: round start down to nearest second, end up to nearest second. Plus an optional ±0.5 s breath each side if the cut feels abrupt (re-encode handles non-keyframe cuts cleanly).

### 5. Confirm the range with the user

Before downloading, show the proposed range and the subtitle text it captures:

> Clipping `00:00:00–00:00:25` covering: *"The important is, is your code good? We care about excellent code. We don't care who you are. Like maybe you're a dog. I don't care, right? …"*

Wait for confirmation or course-correction. Avoid downloading and re-downloading when the user can spot a needed adjustment in five seconds.

### 6. Download the section

```bash
cd ~/Downloads && \
nix run nixpkgs#yt-dlp -- \
  --download-sections "*MM:SS-MM:SS" \
  --force-keyframes-at-cuts \
  --cookies-from-browser firefox \
  -o "<slug>.%(ext)s" \
  --force-overwrites \
  "<URL>"
```

`--force-keyframes-at-cuts` re-encodes to make the cut points frame-accurate. Without it, yt-dlp aligns to the nearest keyframe, which can over- or under-shoot by several seconds.

The output extension depends on the chosen format — usually `.webm` (VP9 + Opus) or `.mp4` (H.264 + AAC). Pick a short, descriptive slug; default to `~/Downloads/<slug>.<ext>`.

### 7. Transcode to mp4 (default)

For maximum portability — H.264 video, AAC audio, in mp4 container:

```bash
nix run nixpkgs#ffmpeg -- \
  -y -i <input>.webm \
  -c:v libx264 -crf 18 -preset medium \
  -c:a aac -b:a 192k \
  <output>.mp4
```

CRF 18 is visually lossless for most content; bump to 23 if size matters more than fidelity. Drop the transcode step entirely (leave as `.webm`) if the user prefers smaller files and a modern player.

### 8. Clean up intermediates

Only the final `.mp4` should remain. Delete the source download and the VTT used for locating:

```bash
rm -f ~/Downloads/<slug>.webm ~/Downloads/<slug>.mkv ~/Downloads/<slug>.m4a
rm -f /tmp/<video-id>.en.vtt /tmp/<video-id>.*.vtt
```

Skip the `rm` of the download if the user opted out of transcode (step 7) — that file *is* the deliverable. Always remove the VTT.

### 9. Report

Confirm output path, duration, size. If the user might want a different range or format, say so explicitly so they know they can ask.

## Common pitfalls

- **Trusting the URL's `t=` parameter.** Users often link a video at the spot they're currently watching, not the spot the quote is at. Always verify against subtitle text.
- **Trusting the user's quote verbatim.** "I don't care if you are a dog" might literally read "Like maybe you're a dog" in the captions. Fuzzy match on the most-distinctive word.
- **Bot detection.** First `yt-dlp` call without cookies often fails. Don't loop forever — retry once with `--cookies-from-browser firefox`, then surface the failure to the user.
- **VTT cue overlap.** Auto-captions emit overlapping cues for animation. The same text appears on consecutive lines with sub-second deltas. Don't double-count when reasoning about timing.
- **Music / non-speech segments.** Auto-subs skip those. If the quote falls in a gap, captions won't help; the user must give the timestamp.
- **Long videos / cookies missing.** Live-streams and unlisted videos sometimes don't have auto-subs. Fall back to asking the user for a specific timestamp range.

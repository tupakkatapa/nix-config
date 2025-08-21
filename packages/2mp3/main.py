#!/usr/bin/env python3

import os
import shutil
import sys
import subprocess

# Supported audio extensions
AUDIO_EXTENSIONS = ["flac", "m4a", "wav"]
# Compression ratio estimates for audio formats when converted to MP3 320k
COMPRESSION_RATIOS = {
    "flac": 0.25,  # FLAC -> MP3 320k typically 25% of original size (4:1 ratio)
    "wav": 0.24,   # WAV -> MP3 320k typically 24% of original size (4.2:1 ratio)
    "m4a": 1.1     # M4A -> MP3 320k typically 110% of original size (MP3 larger)
}
CONVERTED_COUNT = 0
TOTAL_FILES = 0
NON_AUDIO_COUNT = 0
DELETED_FILE_SIZE = 0
ACTUAL_SPACE_SAVED = 0  # Track real space savings during conversion
DRY_RUN = True  # Default to dry-run mode

# Display usage information
def display_usage():
    print("""
Usage: 2mp3 [--execute] [DIRECTORY]

Description:
  Convert audio files in the specified directory to mp3 format.
  Runs in dry-run mode by default.

Arguments:
  DIRECTORY
    the directory containing the audio files.

Options:
  --execute    Actually perform the conversions (default is dry-run)

Examples:
  2mp3.py /path/to/music           # Dry-run mode
  2mp3.py --execute /path/to/music # Actually convert files

""")

# Parse and validate command line arguments
def parse_arguments():
    global DRY_RUN

    args = [arg for arg in sys.argv[1:] if arg not in ['-h', '--help']]

    if len(sys.argv) == 1 or '-h' in sys.argv or '--help' in sys.argv:
        display_usage()
        sys.exit(1)

    if '--execute' in args:
        DRY_RUN = False
        args.remove('--execute')

    if len(args) != 1:
        display_usage()
        sys.exit(1)

    return args[0]

# Create the .original directory while preserving the original folder structure
def move_to_original(directory, file_path, is_audio_file=False, audio_extension=None):
    global DELETED_FILE_SIZE
    relative_path = os.path.relpath(file_path, directory)
    original_dir = os.path.join(directory, ".original", os.path.dirname(relative_path))

    if DRY_RUN:
        file_size = os.path.getsize(file_path) if os.path.exists(file_path) else 0
        if is_audio_file and audio_extension in COMPRESSION_RATIOS:
            # Estimate space saved: original_size - estimated_mp3_size
            estimated_mp3_size = file_size * COMPRESSION_RATIOS[audio_extension]
            space_saved = file_size - estimated_mp3_size
            DELETED_FILE_SIZE += space_saved
        else:
            # Non-audio files would be completely moved to .original
            DELETED_FILE_SIZE += file_size
    else:
        os.makedirs(original_dir, exist_ok=True)
        DELETED_FILE_SIZE += os.path.getsize(file_path)
        shutil.move(file_path, os.path.join(original_dir, os.path.basename(file_path)))

# Convert audio files to MP3 using subprocess to run ffmpeg
def convert_to_mp3(directory, extension):
    global CONVERTED_COUNT, TOTAL_FILES, ACTUAL_SPACE_SAVED
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(extension):
                file_path = os.path.join(root, file)
                mp3_file = file_path.rsplit('.', 1)[0] + ".mp3"
                relative_path = os.path.relpath(file_path, directory)

                if DRY_RUN:
                    print(f"dry-run: converting '{relative_path}'")
                    CONVERTED_COUNT += 1
                    move_to_original(directory, file_path, is_audio_file=True, audio_extension=extension)
                else:
                    print(f"status: converting '{relative_path}'")
                    try:
                        original_size = os.path.getsize(file_path)
                        subprocess.run(
                            ["ffmpeg", "-y", "-i", file_path, "-b:a", "320k", "-map_metadata", "0", "-id3v2_version", "3", mp3_file],
                            check=True,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE
                        )
                        mp3_size = os.path.getsize(mp3_file)
                        space_saved = original_size - mp3_size
                        ACTUAL_SPACE_SAVED += space_saved
                        CONVERTED_COUNT += 1
                        move_to_original(directory, file_path)  # Move original file to .original after conversion
                    except subprocess.CalledProcessError as e:
                        print(f"error: could not convert {relative_path}: {e}")

                TOTAL_FILES += 1

# Move non-audio files to .original directory while preserving structure
def move_non_audio_files(directory):
    global NON_AUDIO_COUNT
    for root, _, files in os.walk(directory):
        for file in files:
            if not any(file.endswith(ext) for ext in AUDIO_EXTENSIONS + ["mp3"]):
                file_path = os.path.join(root, file)
                if DRY_RUN:
                    # Don't add to DELETED_FILE_SIZE here - it's handled in move_to_original
                    pass
                else:
                    move_to_original(directory, file_path)  # Move non-audio file to .original
                NON_AUDIO_COUNT += 1

    if not DRY_RUN:
        print(f"status: found {NON_AUDIO_COUNT} potential non-audio files")

# Convert file size to a human-readable format
def format_size(size_in_bytes):
    if size_in_bytes >= 1 << 30:
        return f"{size_in_bytes / (1 << 30):.2f} GB"
    elif size_in_bytes >= 1 << 20:
        return f"{size_in_bytes / (1 << 20):.2f} MB"
    else:
        return f"{size_in_bytes / (1 << 10):.2f} KB"

# Ask user for cleanup confirmation and delete the original files
def ask_cleanup(directory):
    global DELETED_FILE_SIZE, ACTUAL_SPACE_SAVED

    if DRY_RUN:
        saved_size = format_size(DELETED_FILE_SIZE)
        print(f"dry-run: would move {NON_AUDIO_COUNT} non-audio files to .original/")
        print(f"dry-run: estimated space savings: {saved_size}")
        print("to actually perform operations, run with --execute")
        return

    # Show actual compression savings
    if ACTUAL_SPACE_SAVED >= 0:
        compression_savings = format_size(ACTUAL_SPACE_SAVED)
        print(f"info: audio compression saved {compression_savings}, non-audio files: {format_size(DELETED_FILE_SIZE)}")
    else:
        compression_increase = format_size(abs(ACTUAL_SPACE_SAVED))
        print(f"info: audio conversion increased size by {compression_increase}, non-audio files: {format_size(DELETED_FILE_SIZE)}")
    
    total_savings = ACTUAL_SPACE_SAVED + DELETED_FILE_SIZE
    if total_savings >= 0:
        total_savings_str = format_size(total_savings)
    else:
        total_savings_str = f"-{format_size(abs(total_savings))}"
    print("info: old files have been moved to the .original folder")
    confirm = input("status: do you want to delete these files permanently? (y/n): ").strip().lower()
    if confirm == 'y':
        original_dir = os.path.join(directory, ".original")
        deleted_count = sum(len(files) for _, _, files in os.walk(original_dir))
        shutil.rmtree(original_dir)
        if total_savings >= 0:
            print(f"info: deleted {deleted_count} original files, total space saved: {total_savings_str}")
        else:
            print(f"info: deleted {deleted_count} original files, total space change: {total_savings_str}")
    else:
        print(f"info: cleanup canceled, old files are in {directory}/.original")

# Main function
def main():
    directory = parse_arguments()

    # Convert audio files to MP3 and move originals to .original
    for ext in AUDIO_EXTENSIONS:
        convert_to_mp3(directory, ext)

    # Move non-audio files to .original
    move_non_audio_files(directory)

    print()  # Empty line before summary
    if DRY_RUN:
        print(f"dry-run: would try to convert {CONVERTED_COUNT} audio files")
    else:
        print(f"info: successfully converted {CONVERTED_COUNT}/{TOTAL_FILES} audio files")

    ask_cleanup(directory)

if __name__ == "__main__":
    main()

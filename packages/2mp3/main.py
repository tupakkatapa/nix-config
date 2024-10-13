#!/usr/bin/env python3

import os
import shutil
import sys
import subprocess

# Supported audio extensions
AUDIO_EXTENSIONS = ["flac", "m4a", "wav"]
CONVERTED_COUNT = 0
TOTAL_FILES = 0
NON_AUDIO_COUNT = 0

# Display usage information
def display_usage():
    print("""
Usage: 2mp3.py DIRECTORY

Description:
  convert audio files in the specified directory to mp3 format
  non-mp3 files will be moved to a .original folder, preserving the directory structure, and you'll be asked if they should be deleted after conversion

Arguments:
  DIRECTORY
    the directory containing the audio files

Examples:
  2mp3.py /path/to/music
""")

# Parse and validate command line arguments
def parse_arguments():
    if len(sys.argv) != 2 or sys.argv[1] in ['-h', '--help']:
        display_usage()
        sys.exit(1)
    return sys.argv[1]

# Create the .original directory while preserving the original folder structure
def move_to_original(directory, file_path):
    relative_path = os.path.relpath(file_path, directory)
    original_dir = os.path.join(directory, ".original", os.path.dirname(relative_path))
    os.makedirs(original_dir, exist_ok=True)
    shutil.move(file_path, os.path.join(original_dir, os.path.basename(file_path)))

# Convert audio files to MP3 using subprocess to run ffmpeg
def convert_to_mp3(directory, extension):
    global CONVERTED_COUNT, TOTAL_FILES
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(extension):
                file_path = os.path.join(root, file)
                mp3_file = file_path.rsplit('.', 1)[0] + ".mp3"
                print(f"status: converting {file} to mp3")
                try:
                    subprocess.run(
                        ["ffmpeg", "-y", "-i", file_path, "-b:a", "320k", "-map_metadata", "0", "-id3v2_version", "3", mp3_file],
                        check=True,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE
                    )
                    CONVERTED_COUNT += 1
                    print(f"info: converted {file}")
                    move_to_original(directory, file_path)  # Move original file to .original after conversion
                except subprocess.CalledProcessError as e:
                    print(f"error: could not convert {file}: {e}")
                TOTAL_FILES += 1

# Move non-audio files to .original directory while preserving structure
def move_non_audio_files(directory):
    global NON_AUDIO_COUNT
    for root, _, files in os.walk(directory):
        for file in files:
            if not any(file.endswith(ext) for ext in AUDIO_EXTENSIONS + ["mp3"]):
                file_path = os.path.join(root, file)
                move_to_original(directory, file_path)  # Move non-audio file to .original
                NON_AUDIO_COUNT += 1
    print(f"status: found {NON_AUDIO_COUNT} potential non-audio files")

# Ask user for cleanup confirmation and delete the original files
def ask_cleanup(directory):
    print("info: old files have been moved to the .original folder")
    confirm = input("status: do you want to delete these files permanently? (y/n): ").strip().lower()
    if confirm == 'y':
        original_dir = os.path.join(directory, ".original")
        deleted_count = sum(len(files) for _, _, files in os.walk(original_dir))
        shutil.rmtree(original_dir)
        print(f"info: deleted {deleted_count} original audio files and {NON_AUDIO_COUNT} non-audio files")
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

    print(f"info: successfully converted {CONVERTED_COUNT}/{TOTAL_FILES} audio files")
    ask_cleanup(directory)

if __name__ == "__main__":
    main()

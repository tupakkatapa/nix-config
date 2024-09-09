#!/usr/bin/env python3
# This script generates a random chord progression, written with ChatGPT-4

import random
import re
from urllib.parse import quote

def create_data_structures():
    keys = {
        'C': ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim'],
        'Cm': ['Cm', 'Ddim', 'Eb', 'Fm', 'Gm', 'Ab', 'Bb'],
        'C#': ['C#', 'D#m', 'Fm', 'F#', 'G#', 'A#m', 'Cdim'],
        'C#m': ['C#m', 'D#dim', 'E', 'F#m', 'G#m', 'A', 'B'],
        'D': ['D', 'Em', 'F#m', 'G', 'A', 'Bm', 'C#dim'],
        'Dm': ['Dm', 'Edim', 'F', 'Gm', 'Am', 'Bb', 'C'],
        'Eb': ['Eb', 'Fm', 'Gm', 'Ab', 'Bb', 'Cm', 'Ddim'],
        'Ebm': ['Ebm', 'Fdim', 'Gb', 'Abm', 'Bbm', 'Cb', 'Db'],
        'E': ['E', 'F#m', 'G#m', 'A', 'B', 'C#m', 'D#dim'],
        'Em': ['Em', 'F#dim', 'G', 'Am', 'Bm', 'C', 'D'],
        'F': ['F', 'Gm', 'Am', 'Bb', 'C', 'Dm', 'Edim'],
        'Fm': ['Fm', 'Gdim', 'Ab', 'Bbm', 'Cm', 'Db', 'Eb'],
        'F#': ['F#', 'G#m', 'A#m', 'B', 'C#', 'D#m', 'Fdim'],
        'F#m': ['F#m', 'G#dim', 'A', 'Bm', 'C#m', 'D', 'E'],
        'G': ['G', 'Am', 'Bm', 'C', 'D', 'Em', 'F#dim'],
        'Gm': ['Gm', 'Adim', 'Bb', 'Cm', 'Dm', 'Eb', 'F'],
        'Ab': ['Ab', 'Bbm', 'Cm', 'Db', 'Eb', 'Fm', 'Gdim'],
        'Abm': ['Abm', 'Bbdim', 'Cb', 'Dbm', 'Ebm', 'Fb', 'Gb'],
        'A': ['A', 'Bm', 'C#m', 'D', 'E', 'F#m', 'G#dim'],
        'Am': ['Am', 'Bdim', 'C', 'Dm', 'Em', 'F', 'G'],
        'Bb': ['Bb', 'Cm', 'Dm', 'Eb', 'F', 'Gm', 'Adim'],
        'Bbm': ['Bbm', 'Cdim', 'Db', 'Ebm', 'Fm', 'Gb', 'Ab'],
        'B': ['B', 'C#m', 'D#m', 'E', 'F#', 'G#m', 'A#dim'],
        'Bm': ['Bm', 'C#dim', 'D', 'Em', 'F#m', 'G', 'A']
    }

    scales = {
        'Major': [('Ionian', 'I'), ('Lydian', 'IV'), ('Mixolydian', 'V')],
        'Minor': [('Dorian', 'II'), ('Phrygian', 'III'), ('Aeolian', 'VI')],
        'Diminished': [('Locrian', 'VII')],
    }

    tuning = ['E', 'A', 'D', 'G']
    note_to_frets = {
        'C':  [8, 3, 10, 5], 'C#': [9, 4, 11, 6], 'Db': [9, 4, 11, 6], 'D':  [10, 5, 0, 7],
        'D#': [11, 6, 1, 8], 'Eb': [11, 6, 1, 8], 'E':  [0, 7, 2, 9], 'F':  [1, 8, 3, 10],
        'F#': [2, 9, 4, 11], 'Gb': [2, 9, 4, 11], 'G':  [3, 10, 5, 0], 'G#': [4, 11, 6, 1],
        'Ab': [4, 11, 6, 1], 'A':  [5, 0, 7, 2], 'A#': [6, 1, 8, 3], 'Bb': [6, 1, 8, 3], 'B':  [7, 2, 9, 4]
    }
    return keys, scales, tuning, note_to_frets

def main():
    keys, scales, tuning, note_to_frets = create_data_structures()

    def find_tabs(note):
        clean_note = re.sub(r'(m|dim)$', '', note)
        clean_note = {**dict(zip('C# D# F# G# A# Db Eb Gb Ab Bb'.split(), 'C# D# F# G# A# C# D# F# G# A#'.split())),
                      **dict(zip('C D E F G A B'.split(), 'C D E F G A B'.split())),
                      'Cb': 'B'}[clean_note]
        frets = note_to_frets[clean_note]
        return ', '.join(f"{string}{fret}" for string, fret in zip(tuning, frets))

    def generate_scale_url(chord, scale):
        root = re.sub(r'(m|dim)$', '', chord)
        root = root.replace('#', '-sharp').replace('b', '-flat').lower()
        scale_name = scale.replace(' ', '-').lower()
        return f"https://guitarscale.org/bass/{quote(root)}-{scale_name}.html"

    def choose_key():
        key = random.choice(list(keys.keys()))
        return key, keys[key]

    def choose_chord_progression(chords, length=4, ban_diminished=True):
        if ban_diminished:
            chords = [chord for chord in chords if 'dim' not in chord]
        return random.sample(chords, min(length, len(chords)))

    def assign_scales_to_chords(chords):
        headers = "Chord", "Scale (Mode)", "Scale URL", "Root Notes"
        column_widths = [6, 15, 53, 30]  # Adjust these values as needed
        header_line = '|'.join(f" {header: <{width}}" for header, width in zip(headers, column_widths))
        print(header_line)
        print('-' * (sum(column_widths) + len(headers) - 1))  # Corrected line: Ensure the expression evaluates to a string
        for chord in chords:
            quality = 'Major' if 'm' not in chord and 'dim' not in chord else ('Minor' if 'm' in chord else 'Diminished')
            scale, num = random.choice(scales[quality])
            url = generate_scale_url(chord, scale)
            tabs = find_tabs(chord.rstrip('m').rstrip('dim'))
            row = '|'.join(f" {data: <{width}}" for data, width in zip((chord, f"{scale} ({num})", url, tabs), column_widths))
            print(row)

    key, chord_options = choose_key()
    progression = choose_chord_progression(chord_options)
    assign_scales_to_chords(progression)
    print('-' * 108)
    print(f"Key Selected: {key} | Available Chords: {', '.join(chord_options)} | Chord Progression: {', '.join(progression)}")

if __name__ == "__main__":
    main()

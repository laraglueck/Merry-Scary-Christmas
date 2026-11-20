# Makes music_merry.mp3 (spec 29): "Silent Night" (Franz Xaver Gruber, 1818, public domain)
# played softly as a music box, for the Merry Christmas ending. Own work: every note is
# synthesised here from sine waves. 5 s of silence first, so the win fanfare can ring out.
# Needs python3 with numpy and the program ffmpeg. Start from the repo folder:
#   python3 godot/tools/make_music_merry.py
import os
import subprocess
import wave

import numpy as np

RATE = 44100
BEAT = 60 / 66          # quarter note at 66 beats per minute: calm
LEAD_IN = 5.0           # seconds of silence before the first note
NOTE = {"C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00, "A4": 440.00,
        "B4": 493.88, "C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46, "G3": 196.00,
        "C3": 130.81, "F3": 174.61, "G2": 98.00}

# The melody in 3/4 time: (note, length in quarter notes), one line per bar.
MELODY = [
    [("G4", 1.5), ("A4", 0.5), ("G4", 1), ("E4", 3)],
    [("G4", 1.5), ("A4", 0.5), ("G4", 1), ("E4", 3)],
    [("D5", 2), ("D5", 1), ("B4", 3)],
    [("C5", 2), ("C5", 1), ("G4", 3)],
    [("A4", 2), ("A4", 1), ("C5", 1.5), ("B4", 0.5), ("A4", 1)],
    [("G4", 1.5), ("A4", 0.5), ("G4", 1), ("E4", 3)],
    [("A4", 2), ("A4", 1), ("C5", 1.5), ("B4", 0.5), ("A4", 1)],
    [("G4", 1.5), ("A4", 0.5), ("G4", 1), ("E4", 3)],
    [("D5", 2), ("D5", 1), ("F5", 1.5), ("D5", 0.5), ("B4", 1)],
    [("C5", 3), ("E5", 3)],
    [("C5", 1), ("G4", 1), ("E4", 1), ("G4", 1.5), ("F4", 0.5), ("D4", 1)],
    [("C4", 6)],
]
# One soft low note at the start of every two bars (the harmony): C, C, G, C, F, C, F, C, G, C, C, C.
BASS = ["C3", "C3", "G2", "C3", "F3", "C3", "F3", "C3", "G2", "C3", "C3", "C3"]


def music_box_note(frequency, seconds, loudness):
    t = np.arange(int(RATE * seconds)) / RATE
    decay = np.exp(-t / 0.9)                      # a plucked metal comb fades away
    attack = np.minimum(1.0, t / 0.004)
    tone = (np.sin(2 * np.pi * frequency * t)
            + 0.35 * np.sin(2 * np.pi * 2 * frequency * t) * np.exp(-t / 0.3)
            + 0.12 * np.sin(2 * np.pi * 4.2 * frequency * t) * np.exp(-t / 0.15))
    return loudness * tone * decay * attack


def main():
    beats = sum(length for notes in MELODY for _, length in notes)
    total = LEAD_IN + beats * BEAT + 5.0          # room for the last note to ring out
    song = np.zeros(int(RATE * total))
    time = LEAD_IN
    for bar, notes in enumerate(MELODY):
        start = int(RATE * time)
        low = music_box_note(NOTE[BASS[bar]], 3.5, 0.18)
        song[start:start + len(low)] += low[: len(song) - start]
        for name, beats in notes:
            begin = int(RATE * time)
            sound = music_box_note(NOTE[name], max(beats * BEAT, 1.2) + 1.5, 0.5)
            song[begin:begin + len(sound)] += sound[: len(song) - begin]
            time += beats * BEAT
    song = song / np.max(np.abs(song)) * 0.8      # soft, after the echo about -8 dB
    here = os.path.dirname(os.path.abspath(__file__))
    raw = os.path.join(here, "music_merry_raw.wav")
    with wave.open(raw, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes((song * 32767).astype(np.int16).tobytes())
    target = os.path.join(here, "..", "assets", "sounds", "music_merry.mp3")
    # A little room around the music box (echo), then MP3.
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", raw, "-af", "aecho=0.8:0.6:120|260:0.25|0.15",
                    "-ac", "1", "-b:a", "128k", target], check=True)
    os.remove(raw)
    print("saved music_merry.mp3")


if __name__ == "__main__":  # make_music_scary.py borrows the melody without making this file
    main()

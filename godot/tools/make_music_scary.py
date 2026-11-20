# Makes music_scary.mp3 (spec 29): the same "Silent Night" (Gruber, 1818, public domain) as in
# make_music_merry.py, but as a broken music box for the Scary Christmas ending: in a minor key,
# out of tune, wobbling, one note hangs, and it slows down and sags like a spring running out.
# Own work: every note is synthesised here. 5 s of silence first, for the win fanfare.
# Needs python3 with numpy and the program ffmpeg. Start from the repo folder:
#   python3 godot/tools/make_music_scary.py
import os
import random
import subprocess
import wave

import numpy as np

from make_music_merry import BASS, MELODY, NOTE, RATE

LEAD_IN = 5.0
BEAT = 60 / 52           # slower than the Merry version (66)
SLOW_DOWN = 0.7          # at the end each beat is 70 % longer: the spring runs out
SAG = 0.05               # and the pitch sinks by up to 5 %
# Major to minor: E becomes E flat, A becomes A flat (C minor, the B stays: it sounds strange).
MINOR = {"E4": 311.13, "E5": 622.25, "A4": 415.30}


def frequency(name):
    return MINOR.get(name, NOTE[name])


def broken_note(frequency, seconds, loudness, start_time):
    t = np.arange(int(RATE * seconds)) / RATE
    # A warped comb: the pitch wobbles slowly, as if the drum turned unevenly.
    wobble = 1 + 0.012 * np.sin(2 * np.pi * 0.55 * (start_time + t))
    phase = 2 * np.pi * np.cumsum(frequency * wobble) / RATE
    decay = np.exp(-t / 1.3)
    attack = np.minimum(1.0, t / 0.004)
    tone = (np.sin(phase) + 0.25 * np.sin(2 * phase) * np.exp(-t / 0.25)
            + 0.18 * np.sin(2.97 * phase) * np.exp(-t / 0.4))   # a slightly wrong overtone: tinny
    return loudness * tone * decay * attack


def main():
    random.seed(29)  # the same "mistakes" every time the file is made
    notes = [(bar, name, beats) for bar, line in enumerate(MELODY) for name, beats in line]
    total_beats = sum(beats for _, _, beats in notes)
    song = np.zeros(int(RATE * (LEAD_IN + total_beats * BEAT * (1 + SLOW_DOWN) + 8)))
    time = LEAD_IN
    done = 0.0
    last_bar = -1
    for bar, name, beats in notes:
        progress = done / total_beats
        beat = BEAT * (1 + SLOW_DOWN * progress ** 2)
        pitch = (1 - SAG * progress ** 3) * random.uniform(0.985, 1.015)  # out of tune
        begin = int(RATE * time)
        if bar != last_bar:
            low = broken_note(frequency(BASS[bar]) * pitch, 4.0, 0.16, time)
            song[begin:begin + len(low)] += low[: len(song) - begin]
            last_bar = bar
        sound = broken_note(frequency(name) * pitch, max(beats * beat, 1.2) + 2.0, 0.5, time)
        song[begin:begin + len(sound)] += sound[: len(song) - begin]
        if bar == 4 and name == "C5":   # the comb hangs: the same note once more, too soon
            again = int(RATE * (time + 0.18))
            song[again:again + len(sound)] += 0.6 * sound[: len(song) - again]
        time += beats * beat
        done += beats
    # A low, uneasy hum under everything: two tones that rub against each other.
    t = np.arange(len(song)) / RATE
    hum = 0.05 * (np.sin(2 * np.pi * 65.4 * t) + np.sin(2 * np.pi * 66.1 * t))
    hum *= np.clip((t - LEAD_IN) / 4.0, 0, 1) * np.clip((time + 4 - t) / 4.0, 0, 1)
    song += hum
    song = song[: int(RATE * (time + 6))]
    song = song / np.max(np.abs(song)) * 0.6   # as loud as the Merry music after the echo
    here = os.path.dirname(os.path.abspath(__file__))
    raw = os.path.join(here, "music_scary_raw.wav")
    with wave.open(raw, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes((song * 32767).astype(np.int16).tobytes())
    target = os.path.join(here, "..", "assets", "sounds", "music_scary.mp3")
    # A big empty room (long echo), the high end dull, as if from far away.
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", raw, "-af",
                    "aecho=0.8:0.7:180|420|700:0.35|0.25|0.15,lowpass=f=3500",
                    "-ac", "1", "-b:a", "128k", target], check=True)
    os.remove(raw)
    print("saved music_scary.mp3")


if __name__ == "__main__":
    main()

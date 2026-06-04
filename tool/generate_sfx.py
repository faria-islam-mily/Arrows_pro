"""Generates a loud, distinct 'heart lost' sound effect -> assets/sfx/heart.wav.
A soft descending two-tone "uh-oh" blip with a quick decay."""
import math
import struct
import wave
import os

SR = 44100
DUR = 0.42
N = int(SR * DUR)
PEAK = 0.9

def tone(t, f):
    # body + a little 2nd harmonic for warmth
    return math.sin(2 * math.pi * f * t) + 0.3 * math.sin(2 * math.pi * 2 * f * t)

samples = []
for i in range(N):
    t = i / SR
    p = t / DUR
    # Pitch glides down (E -> C-ish), classic "lost" feel.
    f = 392.0 * (1.0 - 0.32 * p)          # ~G4 down to ~D4
    # Two soft beats (de-dum) via an amplitude envelope.
    beat = max(0.0, math.sin(math.pi * min(p / 0.5, 1.0))) if p < 0.5 \
        else max(0.0, math.sin(math.pi * ((p - 0.5) / 0.5)))
    env = beat * (1.0 - 0.2 * p)
    samples.append(tone(t, f) * env)

peak = max(abs(s) for s in samples) or 1.0
g = PEAK / peak
out = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "assets", "sfx", "heart.wav"))
with wave.open(out, "w") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, s * g)) * 32767)) for s in samples))
print("Wrote", out, f"({DUR}s, peak {PEAK})")

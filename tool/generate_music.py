"""Generates a calm, seamlessly-looping ambient pad for the game's background
music and writes it to assets/music/ambient.wav.

Seamless loop: every partial's frequency is snapped to an integer number of
cycles over the loop length L, and all envelopes use cosines whose period
divides L. So the waveform's value AND slope match at t=0 and t=L -> no click.
"""
import math
import struct
import wave
import os

SR = 44100
L = 32.0                      # loop length (seconds)
N = int(SR * L)
PEAK = 0.95                   # near full-scale (loud background)

def snap(f):
    """Snap a frequency to a whole number of cycles over the loop."""
    return round(f * L) / L

# Two soothing chords we slowly breathe between: C major <-> A minor.
CHORD_A = [130.81, 164.81, 196.00, 261.63, 329.63]   # C3 E3 G3 C4 E4
CHORD_B = [110.00, 130.81, 164.81, 220.00, 261.63]   # A2 C3 E3 A3 C4
WEIGHTS = [1.0, 0.78, 0.66, 0.5, 0.34]
SUB_A, SUB_B = 65.41, 55.00                          # warm low octave

def partials(chord, sub):
    out = []
    for f, w in zip(chord, WEIGHTS):
        out.append((snap(f), w))            # fundamental
        out.append((snap(f * 1.0025), w * 0.6))  # tiny detune -> warmth/chorus
    out.append((snap(sub), 0.55))           # sub
    return out

PA = partials(CHORD_A, SUB_A)
PB = partials(CHORD_B, SUB_B)

# Pre-snap the breathing LFOs to whole cycles over L too.
def lfo(t, cycles, phase):
    return math.sin(2 * math.pi * cycles * t / L + phase)

left = [0.0] * N
right = [0.0] * N

for i in range(N):
    t = i / SR
    # Crossfade A<->B once over the loop (cos -> seamless).
    cf = 0.5 + 0.5 * math.cos(2 * math.pi * t / L)   # 1 at ends, 0 mid
    eA, eB = cf, 1.0 - cf
    # Slow shimmer so it isn't static (whole cycles over L).
    shimmerL = 1.0 + 0.07 * lfo(t, 3, 0.0)
    shimmerR = 1.0 + 0.07 * lfo(t, 3, math.pi / 2)
    s = 0.0
    for f, w in PA:
        s += eA * w * math.sin(2 * math.pi * f * t)
    for f, w in PB:
        s += eB * w * math.sin(2 * math.pi * f * t)
    left[i] = s * shimmerL
    right[i] = s * shimmerR

# Normalize both channels by a shared factor to the gentle peak.
peak = max(max(abs(v) for v in left), max(abs(v) for v in right)) or 1.0
g = PEAK / peak

out = os.path.join(os.path.dirname(__file__), "..", "assets", "music", "ambient.wav")
out = os.path.abspath(out)
with wave.open(out, "w") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    frames = bytearray()
    for i in range(N):
        l = int(max(-1.0, min(1.0, left[i] * g)) * 32767)
        r = int(max(-1.0, min(1.0, right[i] * g)) * 32767)
        frames += struct.pack("<hh", l, r)
    w.writeframes(bytes(frames))

print(f"Wrote {out}  ({N} frames, {L:.0f}s, stereo {SR}Hz)")

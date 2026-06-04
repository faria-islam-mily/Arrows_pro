"""Normalize every sfx clip up to ~99% full-scale so they play as loud as
digitally possible (clean, no clipping). Run after changing any clip."""
import wave
import array
import os

TARGET = 0.99
SFX_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "sfx"))

for name in ["pop.wav", "blocked.wav", "win.wav", "heart.wav"]:
    path = os.path.join(SFX_DIR, name)
    if not os.path.exists(path):
        print("skip (missing):", name)
        continue
    with wave.open(path, "r") as w:
        ch, sw, sr, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        a = array.array("h")
        a.frombytes(w.readframes(n))
    peak = max((abs(x) for x in a), default=0)
    if peak == 0:
        print("skip (silent):", name)
        continue
    g = (TARGET * 32767) / peak
    for i in range(len(a)):
        a[i] = max(-32768, min(32767, int(a[i] * g)))
    with wave.open(path, "w") as w:
        w.setnchannels(ch)
        w.setsampwidth(sw)
        w.setframerate(sr)
        w.writeframes(a.tobytes())
    print(f"{name}: peak {peak} -> ~{round(TARGET*100)}%FS (x{g:.2f})")

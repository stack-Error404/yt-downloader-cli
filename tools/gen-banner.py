#!/usr/bin/env python3
"""Gera a arte do smiley usada no banner do terminal (yt e yt.ps1).

Lê docs/assets/error404-red-john-dots.png, recorta o emblema e o reduz para
uma grade de pontos Braille (2 x 4 pontos por célula do terminal). Cada
célula sai como 3 dígitos hexadecimais: máscara Braille (2 dígitos) e
intensidade do vermelho (1 dígito, 1 a f).

Uso: python3 tools/gen-banner.py [linhas_do_terminal]   (padrão: 11)
Requer Pillow.
"""
import os
import sys

from PIL import Image

rows = int(sys.argv[1]) if len(sys.argv) > 1 else 11
dots_h = rows * 4
src = os.path.join(os.path.dirname(__file__), "..", "docs", "assets", "error404-red-john-dots.png")

lum = Image.open(src).convert("RGB").split()[0]  # emblema vermelho: canal R = intensidade
crop = lum.crop(lum.point(lambda v: 255 if v > 40 else 0).getbbox())

cells = round(crop.width * dots_h / crop.height / 2)
small = crop.resize((cells * 2, dots_h), Image.LANCZOS)
peak = small.getextrema()[1]
THRESHOLD = 0.30

# bits Braille: coluna esquerda (linhas 0-3) e direita (linhas 0-3)
BITS = [[0x01, 0x02, 0x04, 0x40], [0x08, 0x10, 0x20, 0x80]]

print(f"# {cells} colunas x {rows} linhas ({cells * 2} x {dots_h} pontos)")
for r in range(rows):
    line = []
    for c in range(cells):
        mask, total, count = 0, 0.0, 0
        for dx in range(2):
            for dy in range(4):
                v = small.getpixel((c * 2 + dx, r * 4 + dy)) / peak
                if v >= THRESHOLD:
                    mask |= BITS[dx][dy]
                    total += v
                    count += 1
        level = 0
        if count:
            level = min(15, max(4, round(15 * (total / count) ** 0.7)))
        line.append(f"{mask:02x}{level:x}")
    print(" ".join(line))

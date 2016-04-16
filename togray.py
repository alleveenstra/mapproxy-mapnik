import webcolors
import re
import fileinput
import sys

def to_gray(hex_str):
    c = webcolors.hex_to_rgb(hex_str)
    g = int(c[0] * 0.299 + c[1] * 0.587 + c[2] * 0.114)
    c = (g, g, g)
    h = webcolors.rgb_to_hex(c)
    #return h if h != "#c7c7c7" else "#ffffff"
    return h

def regex_replace(match):
    hex_color = match.group(2) if "#" in match.group(2) else webcolors.name_to_hex(match.group(2))
    return match.group().replace(match.group(2), to_gray(hex_color))

for line in fileinput.input([sys.argv[1]], inplace=True, backup='.bak'):
    print re.sub(r'(fill|stroke|color)="([^"]+)"', regex_replace, line).replace("\n", "")

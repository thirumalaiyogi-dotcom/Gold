# Style 5 (STM Premium) theme generator.
# Reads the main <style> of index.html, finds every active rule that paints a blue / blue-grey colour,
# and emits an override rule (higher specificity via [data-p5]) with only those declarations,
# colours remapped to the maroon / champagne / ivory palette. Gold colours are kept.
import re, sys, colorsys
src = open(sys.argv[1], encoding='utf-8').read()
m = re.search(r'<style>', src); css = src[m.end(): src.index('</style>', m.end())]

def hx(h):
    h = h.lstrip('#')
    if len(h) == 3: h = ''.join(c*2 for c in h)
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
def tohex(r, g, b): return '#%02X%02X%02X' % (round(r), round(g), round(b))

def remap(rgb):
    r, g, b = [x/255 for x in rgb]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    hd = h*360
    blue = 185 <= hd <= 260
    if not blue: return None
    if s < 0.22:                       # blue-grey text / borders → warm neutral
        nh, ns = 30/360, min(s, 0.10)
    elif l >= 0.88:                    # pale blue tints → ivory / champagne tint
        nh, ns = 40/360, min(0.55, s*0.6)
    elif l >= 0.62:                    # light accents → soft gold
        nh, ns = 40/360, 0.55
    else:                              # brand blues → maroon / burgundy
        nh, ns = 350/360, min(0.70, max(0.55, s*0.8))
        l = l*0.92 if l > 0.35 else l*0.85
    nr, ng, nb = colorsys.hls_to_rgb(nh, l, ns)
    return (nr*255, ng*255, nb*255)

def fix_value(v):
    changed = [False]
    def rep_hex(mo):
        rgb = hx(mo.group(0)); n = remap(rgb)
        if n is None: return mo.group(0)
        changed[0] = True; return tohex(*n)
    def rep_rgba(mo):
        parts = [p.strip() for p in mo.group(2).split(',')]
        try: rgb = tuple(float(p) for p in parts[:3])
        except: return mo.group(0)
        n = remap(rgb)
        if n is None: return mo.group(0)
        changed[0] = True
        return f"{mo.group(1)}({round(n[0])},{round(n[1])},{round(n[2])}{','+parts[3] if len(parts)>3 else ''})"
    v2 = re.sub(r'#[0-9A-Fa-f]{6}\b|#[0-9A-Fa-f]{3}\b', rep_hex, v)
    v2 = re.sub(r'(rgba?)\(([^()]*)\)', rep_rgba, v2)
    return v2, changed[0]

def prefix(sel):
    out = []
    for part in sel.split(','):
        p = part.strip()
        if not p: continue
        if p.startswith('html[data-style="3"]'):
            out.append('html[data-p5]' + p[4:])
        elif p.startswith('html[data-style=') or p.startswith('html[data-lux') or p.startswith('html.') or 'data-lux' in p:
            return None                          # other styles: not active under Style 5
        elif p.startswith(':root'):
            out.append('html[data-p5]' + p[5:])
        elif p.startswith('html'):
            out.append('html[data-p5]' + p[4:])
        else:
            out.append('html[data-p5] ' + p)
    return ','.join(out) if out else None

res = []
i, n = 0, len(css)
def parse_block(text, wrap=None):
    i = 0
    while i < len(text):
        j = text.find('{', i)
        if j < 0: break
        sel = text[i:j].strip()
        if sel.startswith('@media') or sel.startswith('@supports'):
            depth, k = 1, j+1
            while depth and k < len(text):
                if text[k] == '{': depth += 1
                elif text[k] == '}': depth -= 1
                k += 1
            parse_block(text[j+1:k-1], sel); i = k; continue
        if sel.startswith('@'):                  # keyframes, font-face …: skip whole block
            depth, k = 1, j+1
            while depth and k < len(text):
                if text[k] == '{': depth += 1
                elif text[k] == '}': depth -= 1
                k += 1
            i = k; continue
        k = text.find('}', j)
        body = text[j+1:k]; i = k+1
        sel = re.sub(r'/\*.*?\*/', '', sel, flags=re.S).strip()
        if not sel or '--b' in body and sel.startswith(':root'): pass
        decls = []
        for d in re.split(r';(?![^(]*\))', body):
            if ':' not in d: continue
            prop, val = d.split(':', 1)
            if prop.strip().startswith('--'):     # custom properties: remap too (palette layer)
                pass
            v2, ch = fix_value(val)
            if ch: decls.append(prop.strip() + ':' + v2.strip())
        if not decls: continue
        ps = prefix(sel)
        if not ps: continue
        rule = ps + '{' + ';'.join(decls) + '}'
        res.append(wrap + '{' + rule + '}' if wrap else rule)
parse_block(css)
out = '\n'.join(res)
open(sys.argv[2], 'w', encoding='utf-8').write(out)
print(len(res), 'rules,', len(out), 'bytes')

"""Build staff-new.html (STM Staff v6) from staff.html.

Keeps every element id, function name, Supabase call and business rule. Changes:
  1. Head: fixed premium theme (old ?style=1..3 switch removed, as approved), data-s6 flag, Noto Sans Tamil font.
  2. Dead CSS rules that only applied to the removed Style 1 / Style 2 are dropped.
  3. confirm()/prompt() → in-app dialogs (await ASK / ASKTXT); alert() is replaced at runtime by adm-shell.js.
  4. Bug fixes: IST date in saveRate + remind; old blue colours in the customer detail sheet.
  5. adm-pro (latest source) + adm-shell (new shell) injected before </body>.
Usage: python3 build_staff_new.py staff.html staff-new.html
"""
import re
import sys

src, dst = sys.argv[1], sys.argv[2]
base = '/home/claude/gold/design/stm-premium/'
s = open(src, encoding='utf-8').read()


def sub(a, b, count=1):
    global s
    assert s.count(a) >= 1, ('missing', a[:80])
    s = s.replace(a, b) if count == 0 else s.replace(a, b, count)


# 1. head: fixed theme + v6 flag + font
head_old = re.search(r'<script>/\* Style 1 = .*?\}\)\(\)</script>', s, re.S).group(0)
sub(head_old, '<script>(function(){var h=document.documentElement;h.setAttribute("data-a5","");h.setAttribute("data-style","3");h.setAttribute("data-s6","");var m=document.querySelector(\'meta[name="theme-color"]\');if(m)m.content="#4A0D18"})()</script>'
    '<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>'
    '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+Tamil:wght@400;500;600;700&display=swap">')
sub('<meta name="theme-color" content="#2161D1">', '<meta name="theme-color" content="#4A0D18">')

# 2. drop CSS rules that only target the removed Style 1 / Style 2
def drop_style12(css):
    out = []
    for m in re.finditer(r'([^{}]*)\{([^{}]*)\}', css):
        sel = m.group(1)
        if re.search(r'data-style="?[12]"?\]', sel) and not re.search(r'data-style="?3"?\]', sel):
            continue
        out.append(m.group(0))
    return ''.join(out) if out else css


first = re.search(r'<style>(.*?)</style>', s, re.S)
css = first.group(1)
if '@media' not in css.split('{')[0]:
    pass
# keep @media blocks intact: only filter top-level rules outside media queries
parts = re.split(r'(@media[^{]+\{(?:[^{}]*\{[^{}]*\})*[^{}]*\})', css)
css2 = ''.join(p if p.startswith('@media') else drop_style12(p) for p in parts)
s = s[:first.start(1)] + css2 + s[first.end(1):]

# 3. confirm / prompt → in-app dialogs (all call sites are inside async functions)
n_conf = s.count('!confirm(')
s = s.replace('!confirm(', '!await ASK(')
sub('const v=prompt(', 'const v=await ASKTXT(')

# 4a. IST dates (same as the rest of the app)
sub('const d=new Date(Date.now()-new Date().getTimezoneOffset()*60000).toISOString().slice(0,10),old=window.RT',
    'const d=new Date(Date.now()+330*60000).toISOString().slice(0,10),old=window.RT')
sub('const d=new Date(),ym=d.getFullYear()+"-"+String(d.getMonth()+1).padStart(2,"0");',
    'const ym=new Date(Date.now()+330*60000).toISOString().slice(0,7);')
# 4b. customer detail sheet: old blue → maroon / gold
for a, b in [('border-bottom:1px solid #eef2f8', 'border-bottom:1px solid #F3ECDD'), ('background:#eef4ff;color:#1d5fd8', 'background:#F7F0E1;color:#6E1423'),
             ('background:#f1f4f9">${esc(MDL', 'background:#F7F0E1">${esc(MDL'), ('color:#5b6885">${esc(pdate', 'color:#777">${esc(pdate'),
             ('border:0;background:#f1f4f9;font-size:20px', 'border:0;background:#F7F0E1;font-size:20px')]:
    sub(a, b)

# 5. inject latest adm-pro + adm-shell
s = re.sub(r'\n?<!-- adm-pro:start -->.*?<!-- adm-pro:end -->\n?', '\n', s, flags=re.S)
s = re.sub(r'\n?<!-- adm-shell:start -->.*?<!-- adm-shell:end -->\n?', '\n', s, flags=re.S)
rd = lambda f: open(base + f, encoding='utf-8').read()
block = (f'<!-- adm-pro:start -->\n<style id="admpro">\n{rd("adm-pro.css")}\n</style>\n<script>\n{rd("adm-pro.js")}\n</script>\n<!-- adm-pro:end -->\n'
         f'<!-- adm-shell:start -->\n<style id="admshell">\n{rd("adm-shell.css")}\n</style>\n<script>\n{rd("adm-shell.js")}\n</script>\n<!-- adm-shell:end -->\n')
assert s.count('</body>') == 1
s = s.replace('</body>', block + '</body>')
open(dst, 'w', encoding='utf-8').write(s)
print(f'built {dst}: confirm→ASK x{n_conf}, css {len(css)}→{len(css2)} bytes')

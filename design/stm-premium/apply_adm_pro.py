"""Inject STM Admin Pro (design/stm-premium/adm-pro.css + .js) into staff.html, idempotent."""
import sys, re
p = sys.argv[1]
base = '/home/claude/gold/design/stm-premium/'
s = open(p, encoding='utf-8').read()
css = open(base + 'adm-pro.css', encoding='utf-8').read()
js = open(base + 'adm-pro.js', encoding='utf-8').read()
s = re.sub(r'\n?<!-- adm-pro:start -->.*?<!-- adm-pro:end -->\n?', '\n', s, flags=re.S)
block = f'<!-- adm-pro:start -->\n<style id="admpro">\n{css}\n</style>\n<script>\n{js}\n</script>\n<!-- adm-pro:end -->\n'
assert s.count('</body>') == 1
s = s.replace('</body>', block + '</body>')
open(p, 'w', encoding='utf-8').write(s)
print('adm-pro injected')

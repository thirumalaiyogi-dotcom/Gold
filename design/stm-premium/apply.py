import sys,re
p=sys.argv[1];s=open(p,encoding='utf-8').read()
# 1) style switch: allow ?style=5 (Style 3 base + data-p5 layer)
a='(location.search.match(/[?&]style=([1234])/)||[])[1]'
assert s.count(a)==1; s=s.replace(a,'(location.search.match(/[?&]style=([12345])/)||[])[1]')
a='if(v!=="1"&&v!=="2"&&v!=="3"&&v!=="4")v=D;'
assert s.count(a)==1
s=s.replace(a,a[:-4].replace('&&v!=="4"','&&v!=="4"&&v!=="5"')+'v=D;if(v==="5"){document.documentElement.setAttribute("data-p5","");v="3";var pf=document.createElement("link");pf.rel="stylesheet";pf.href="https://fonts.googleapis.com/css2?family=Noto+Serif+Tamil:wght@500;600;700&display=swap";document.head.appendChild(pf)}')
s=s.replace('/* Style 1 = நீலம், 2 = மரூன், 3 = default, 4 = Luxury (Style 3 + data-lux layer). மாற்ற: ?style=1..4 */','/* Style 1 = நீலம், 2 = மரூன், 3 = default, 4 = Luxury (Style 3 + data-lux), 5 = STM Premium (Style 3 + data-p5, preview). மாற்ற: ?style=1..5 */',1)
# theme-color for p5
a='var m=document.querySelector(\'meta[name="theme-color"]\');if(m)m.content='
assert s.count(a)==1
s=s.replace(a,'var m=document.querySelector(\'meta[name="theme-color"]\');if(m&&document.documentElement.hasAttribute("data-p5")){m.content="#4A0D18"}else if(m)m.content=')
# default style → 5 (saved ?style= choices on a phone are kept)
a='(function(){var D="3",'
assert s.count(a)==1; s=s.replace(a,'(function(){var D="5",')
# 2) CSS: tokens + components + generated colour layer, after the main stylesheet
css=open('/home/claude/p5/p5.css',encoding='utf-8').read()+"\n/* ----- generated: blue → maroon/champagne remap of active Style 3 rules (tools: p5/gen_theme.py) ----- */\n"+open('/home/claude/p5/theme.css',encoding='utf-8').read()
i=s.index('</style>',s.index('<style>'))+len('</style>')
assert 'id="p5css"' not in s
s=s[:i]+'\n<style id="p5css">\n'+css+'\n</style>'+s[i:]
# 3) Dashboard script before </body>
js=open('/home/claude/p5/p5.js',encoding='utf-8').read()
assert s.count('</body>')==1
s=s.replace('</body>','<script>\n'+js+'\n</script>\n</body>')
open(p,'w',encoding='utf-8').write(s)
print("applied")

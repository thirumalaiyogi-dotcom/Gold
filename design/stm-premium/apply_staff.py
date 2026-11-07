import sys
p=sys.argv[1];s=open(p,encoding='utf-8').read()
# style switch: add 5 (Style 3 base + data-a5), default 5
a='(function(){var D="3",k="stm_style",v=D;try{var q=(location.search.match(/[?&]style=([123])/)||[])[1];if(q)localStorage.setItem(k,q);v=localStorage.getItem(k)||D}catch(e){}if(v!=="1"&&v!=="2"&&v!=="3")v=D;document.documentElement.setAttribute("data-style",v);var m=document.querySelector(\'meta[name="theme-color"]\');if(m)m.content=v==="2"?"#5B1420":v==="3"?"#092A63":"#2161D1"})()'
assert s.count(a)==1,"head"
b='(function(){var D="5",k="stm_style",v=D;try{var q=(location.search.match(/[?&]style=([12345])/)||[])[1];if(q)localStorage.setItem(k,q);v=localStorage.getItem(k)||D}catch(e){}if(v==="4")v="3";if(v!=="1"&&v!=="2"&&v!=="3"&&v!=="5")v=D;var a5=v==="5";if(a5){document.documentElement.setAttribute("data-a5","");v="3"}document.documentElement.setAttribute("data-style",v);var m=document.querySelector(\'meta[name="theme-color"]\');if(m)m.content=a5?"#4A0D18":v==="2"?"#5B1420":v==="3"?"#092A63":"#2161D1"})()'
s=s.replace(a,b)
# tab labels
a='const G=[["today","📋 இன்று",'
assert s.count(a)==1; s=s.replace(a,'const G=[["today","📊 Dashboard",')
css="/* generated blue → maroon remap */\n"+open('/home/claude/p5/staff_theme.css',encoding='utf-8').read()+"\n"+open('/home/claude/p5/a5.css',encoding='utf-8').read()
i=s.index('</style>',s.index('<style>'))+len('</style>')
s=s[:i]+'\n<style id="a5css">\n'+css+'\n</style>'+s[i:]
js='''<script>
/* STM Admin (Style 5): tab icons instead of emoji */
(function(){if(!document.documentElement.hasAttribute("data-a5"))return;
 const I={today:'<rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/>',
  cust:'<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><path d="M16 4.5a3.5 3.5 0 0 1 0 7M21.5 20a6.5 6.5 0 0 0-4-6"/>',
  notify:'<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.9 1.9 0 0 0 3.4 0"/>',
  set:'<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
  out:'<path d="M15 4h4v16h-4M10 8l-4 4 4 4M6 12h11"/>'};
 const L={today:"Dashboard",cust:"Customers",notify:"அறிவிப்பு",set:"App அமைப்பு"};
 const bar=document.getElementById("stabs");if(!bar)return;
 bar.querySelectorAll("[data-g]").forEach(b=>{const k=b.dataset.g;if(I[k])b.innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true">'+I[k]+'</svg><span>'+L[k]+'</span>'});
 const lo=document.getElementById("slo");if(lo)lo.innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true">'+I.out+'</svg><span>வெளியேறு</span>';
})();
</script>
'''
assert s.count('</body>')==1
s=s.replace('</body>',js+'</body>')
open(p,'w',encoding='utf-8').write(s)
print("staff applied")

/* ===== STM Premium (Style 5) · Home Dashboard =====
   Read-only view over data the app already loads: window.PBD (passbook, after mPIN login),
   window.RT (gold_rate row), NT (notices). No new network calls, no writes. */
(function(){
 if(!document.documentElement.hasAttribute("data-p5"))return;
 const main=document.querySelector("#s .xmain");if(!main||document.getElementById("d5"))return;
 const host=document.createElement("section");host.id="d5";host.className="d5";host.setAttribute("aria-label","முகப்பு");
 main.prepend(host);
 const E=s=>String(s==null?"":s).replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
 const R=n=>Math.round(+n||0).toLocaleString("en-IN");
 const SV=n=>(+n||0).toLocaleString("en-IN",{minimumFractionDigits:2,maximumFractionDigits:2});
 const IST=()=>new Date(Date.now()+19800000);
 const ym=d=>String(d||"").slice(0,7);
 const T=(fn,d)=>{try{return fn()}catch(e){return d}};
 const ICO={
  pb:'<path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/><path d="M8 7h8M8 11h6"/>',
  pay:'<rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20M6 15h4"/>',
  sch:'<path d="M6 3h12l4 6-10 12L2 9Z"/><path d="M2 9h20"/>',
  ref:'<path d="M20 12v9H4v-9M2 7h20v5H2zM12 21V7M12 7H7.5a2.5 2.5 0 1 1 0-5C11 2 12 7 12 7ZM12 7h4.5a2.5 2.5 0 1 0 0-5C13 2 12 7 12 7Z"/>',
  rate:'<path d="m22 7-8.5 8.5-5-5L2 17"/><path d="M16 7h6v6"/>',
  call:'<path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1 1 .4 1.9.7 2.8a2 2 0 0 1-.5 2.1L8 9.9a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.5c.9.3 1.8.6 2.8.7a2 2 0 0 1 1.7 2z"/>',
  ok:'<path d="M20 6 9 17l-5-5"/>'};
 const svg=k=>`<svg viewBox="0 0 24 24" aria-hidden="true">${ICO[k]}</svg>`;
 const greet=()=>T(()=>greetT(),"வணக்கம்");
 const schName=k=>T(()=>SN[k],k)||k;
 const months=k=>T(()=>MON(k),12);
 const grams=k=>T(()=>GR(k),false);
 const fixed=k=>T(()=>FX(k),false);
 const silver=k=>T(()=>isSilver(k),false);
 const dt=s=>T(()=>pbDate(s),String(s||"").slice(0,10));

 function rateBlock(){
  const r=window.RT;
  const chg=(n,p,dec)=>{if(n==null||p==null||+n==+p)return"";const d=+n-+p;return `<em class="${d>0?"up":"dn"}">${d>0?"▲":"▼"} ₹${dec?SV(Math.abs(d)):R(Math.abs(d))}</em>`};
  const stamp=r?T(()=>rtStamp(r.updated_on),""):"விலை ஏற்றுகிறது…";
  return `<div class="d5-rt" role="group" aria-label="இன்றைய விலை">
   <button type="button" data-q="rate" aria-label="22K தங்கம் விலை நிலவரம்"><small>தங்கம் 22K · 1 கிராம்</small><b>${r?"₹"+R(r.rate22):"—"}</b>${r?chg(r.rate22,r.prev_rate22,0):""}</button>
   <button type="button" data-q="rate" aria-label="வெள்ளி விலை நிலவரம்"><small>வெள்ளி · 1 கிராம்</small><b>${r&&r.silver!=null?"₹"+SV(r.silver):"—"}</b>${r?chg(r.silver,r.prev_silver,1):""}</button>
  </div><div class="d5-rtu"><span>${E(stamp)}</span><button type="button" data-q="rate">விலை நிலவரம் ›</button></div>`}

 function qa(logged){
  const items=logged?[["pb","என் Passbook"],["pay","தவணை செலுத்த"],["sch","திட்டங்கள்"],["ref","நண்பரை சேர்க்க"]]
                    :[["pb","என் Passbook"],["sch","திட்டங்கள்"],["rate","விலை நிலவரம்"],["call","கடைக்கு அழை"]];
  return `<div class="d5-qa" role="group" aria-label="முக்கிய செயல்கள்">${items.map(([k,t])=>k=="call"
   ?`<button type="button" data-d5call><i>${svg(k)}</i><span>${t}</span></button>`
   :`<button type="button" data-q="${k}"><i>${svg(k)}</i><span>${t}</span></button>`).join("")}</div>`}

 function notices(){
  const L=T(()=>NT,[])||[];
  const items=L.slice(0,2);
  return `<div class="d5-card"><div class="d5-ch"><b>அறிவிப்புகள்</b>${L.length?'<button type="button" data-d5n>அனைத்தும் ›</button>':""}</div>${items.length
   ?items.map(n=>`<div class="d5-an"><b>${E(n.title)}</b>${n.body?`<p>${E(n.body)}</p>`:""}<small>${E(T(()=>nd(n.created_at),""))}</small></div>`).join("")
   :'<p class="d5-empty">இப்போதைக்கு புது அறிவிப்பு எதுவும் இல்லை.</p>'}</div>`}

 function savings(d){
  const ps=(d.payments||[]).slice(),k=d.scheme,mo=months(k),fl=silver(k);
  const tot=ps.reduce((a,x)=>a+(+x.amount||0),0),g=ps.reduce((a,x)=>a+(+x.grams||0),0);
  const mset=new Set(ps.map(x=>ym(x.on))),cur=ym(IST().toISOString());
  const paid=fl?mset.size:ps.length,left=Math.max(0,mo-paid);
  const paidThis=mset.has(cur);
  const now=IST(),day=now.getUTCDate();
  let nx;
  if(left===0&&!(fl&&paidThis)){
   nx=`<div class="d5-nx"><div><small>திட்டம்</small><b>எல்லா தவணையும் முடிந்தது <em class="ok">✓</em></b></div></div>`;
  }else{
   const due=new Date(Date.UTC(now.getUTCFullYear(),now.getUTCMonth()+(paidThis?1:0),7));
   const dueS=due.toLocaleDateString("ta-IN",{day:"numeric",month:"short",timeZone:"UTC"});
   const st=paidThis?(fl?["இந்த மாசம் சேமிச்சாச்சு","ok"]:["இந்த மாசம் செலுத்தியாச்சு","ok"]):!ps.length?["முதல் தவணை","due"]:day<=7?["நிலுவையில்","due"]:["தாமதம்","late"];
   const amt=fixed(k)?(ps.length?"₹"+R(ps[0].amount):+d.monthly_amount>0?"₹"+R(d.monthly_amount):"நிலையான தொகை"):fl?"₹100 முதல்":"உங்க விருப்பத் தொகை";
   const showPay=!paidThis||fl;
   nx=`<div class="d5-nx"><div><small>${fl&&paidThis?"இந்த மாசம் மேலும் சேர்க்கலாம்":(paidThis?"அடுத்த தவணை":"தவணை")+" · "+E(dueS)+"க்குள்"}</small><b>${E(amt)} <em class="${st[1]}">${st[0]}</em></b></div>${showPay?'<button type="button" class="d5-pay" data-q="pay">செலுத்த</button>':""}</div>`;
  }
  const end=T(()=>{const s=new Date(d.start);s.setMonth(s.getMonth()+mo);return s.toLocaleDateString("ta-IN",{month:"short",year:"numeric"})},"");
  return `<div class="d5-sv">
   <div class="d5-k"><b>${E(schName(k))} திட்டம்</b>${d.refer&&d.refer.code?`<span>${E(d.refer.code)}</span>`:""}</div>
   <div class="d5-tot">₹${R(tot)}</div><div class="d5-tl">மொத்த சேமிப்பு</div>
   <div class="d5-g">
    <div><small>${fl?"சேமித்த மாதம்":"கட்டிய தவணை"}</small><b>${paid} / ${mo}</b></div>
    <div><small>மீதி</small><b>${left}</b></div>
    <div><small>${grams(k)?"தங்க எடை":"நகை வாங்க"}</small><b>${grams(k)?g.toFixed(3)+" கி":E(end)}</b></div>
   </div>
   <div class="d5-bar" role="progressbar" aria-label="சேமிப்பு முன்னேற்றம்" aria-valuemin="0" aria-valuemax="${mo}" aria-valuenow="${paid}"><i style="width:${Math.min(100,paid/mo*100)}%"></i></div>
   ${nx}
  </div>`}

 function tx(d){
  const k=d.scheme,mo=months(k),fl=silver(k);
  const L=(d.payments||[]).map((x,i)=>({x,n:i+1})).reverse().slice(0,3);
  return `<div class="d5-card"><div class="d5-ch"><b>சமீபத்திய பரிவர்த்தனைகள்</b>${L.length?'<button type="button" data-q="pb">அனைத்தும் ›</button>':""}</div>${L.length
   ?L.map(({x,n})=>`<div class="d5-tx"><span class="ic">${svg("ok")}</span><div class="m"><b>${fl?"சேமிப்பு "+n:"தவணை "+n+" / "+mo}</b><small>${E(dt(x.on))}${x.grams?" · "+(+x.grams).toFixed(3)+" கி":""}</small></div><div class="a"><b>₹${R(x.amount)}</b><small>செலுத்தப்பட்டது</small></div></div>`).join("")
   :'<p class="d5-empty">இன்னும் தவணை எதுவும் இல்லை. முதல் தவணை கட்டியதும் இங்கே தெரியும்.</p>'}</div>`}

 function render(){
  const d=window.PBOK&&window.PBD;
  if(d){
   const first=String(d.name||"").trim().split(/\s+/)[0]||"";
   host.innerHTML=`<div class="d5-hi"><div><small>${E(greet())}</small><h1>${E(first||"வணக்கம்")}</h1></div></div>
    ${savings(d)}${rateBlock()}${qa(true)}${tx(d)}${notices()}`;
  }else{
   host.innerHTML=`<div class="d5-hi"><div><small>${E(greet())}</small><h1>வணக்கம், வருக!</h1></div></div>
    <div class="d5-wel"><small>சுப்புலட்சுமி தங்கமாளிகை</small><h2>தங்க நகை சேமிப்புத் திட்டம்</h2>
     <p>ஒவ்வொரு மாதமும் சிறிது சிறிதாக சேமித்து, 12 வது மாதம் உங்கள் கனவு நகையை வாங்குங்கள்.</p>
     <div class="d5-b2"><button type="button" class="d5-btn pri" data-q="sch">திட்டங்கள் பார்க்க</button><button type="button" class="d5-btn sec" data-q="pb">என் சேமிப்பு</button></div></div>
    ${rateBlock()}${qa(false)}${notices()}`;
  }
 }
 // Re-render only when something visible changed
 let sig="";
 function tick(){const d=window.PBOK&&window.PBD,r=window.RT,L=T(()=>NT,[])||[];
  const s=[!!d,d&&d.name,d&&(d.payments||[]).length,d&&(d.payments||[]).reduce((a,x)=>a+(+x.amount||0),0),r&&[r.rate22,r.silver,r.updated_on].join(),L.length,L[0]&&L[0].id,greet()].join("|");
  if(s!==sig){sig=s;render()}}
 host.addEventListener("click",e=>{
  if(e.target.closest("[data-d5n]")){const b=document.querySelector('nav button[data-t="n"]');if(b)b.click()}
  else if(e.target.closest("[data-d5call]"))location.href="tel:+919791918344"});
 // dashboard first, contact chips right after it
 function place(){if(main.firstElementChild!==host)main.prepend(host);const ch=main.querySelector(".qchips");if(ch&&host.nextElementSibling!==ch)host.after(ch)}
 tick();place();setInterval(()=>{tick();place()},1000);
 document.addEventListener("visibilitychange",()=>{if(document.visibilityState=="visible")tick()});
})();

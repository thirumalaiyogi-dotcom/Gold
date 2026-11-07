# STM Premium (Style 5): design system source

**Preview:** `https://gold.thirumalaiyogi.workers.dev/?style=5`. இந்த மாற்றம் அந்த phone-ல மட்டும் நினைவில் இருக்கும். பழைய style-க்கு திரும்ப `?style=3`.

| File | என்ன |
|---|---|
| `p5.css` | Design tokens (நிறம், எழுத்து, இடைவெளி, radius, shadow) + Home Dashboard components |
| `p5.js` | Customer Home Dashboard. App ஏற்கனவே load பண்ணின data-வை (PBD, RT, NT) மட்டும் படிக்கும். Network call இல்லை, எதையும் எழுதாது. |
| `gen_theme.py` | Style 3-ல உள்ள நீல நிறங்களை maroon / champagne / ivory-க்கு மாத்தி ஒரு override layer உருவாக்கும் |
| `adm5.html` | Staff panel-ல "📊 Dashboard" card (Admin design foundation) |

`index.html`-ல இவை `<style id="p5css">` மற்றும் கடைசி `<script>`-ஆ inline-ஆ சேர்க்கப்பட்டிருக்கு. Single-file app என்பதால் அப்படி. Style 3 CSS மாறினா `gen_theme.py`-ஐ திரும்ப ஓட்டணும்.

## Tokens
- Maroon `#6E1423`
- Burgundy `#4A0D18`
- Champagne gold `#C9A45C`
- Soft gold `#E5C98B`
- Ivory `#FBF8F1`
- Text `#252525` / `#777777`
- Success `#24865B`
- Error `#C63C45`
- Fonts: தலைப்பு மற்றும் தொகைகளுக்கு Noto Serif Tamil, மற்ற எழுத்துக்கு Noto Sans Tamil
- Radius: 20 / 14 / 10
- Spacing: 4-pt grid

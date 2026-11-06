# Genera le varianti SVG dell'icona (viewBox 108, come i livelli adattivi di Android)
def simbolo(bianco="#FFFFFF", barre=("#FFD54A", "#C6F26B", "#7FD13B"), foglia="#B6F04E", vena="#0A7C8A", mono=False):
    if mono:
        barre = (bianco, bianco, bianco); foglia = bianco
    return f'''
  <g transform="translate(54 54) scale(0.93) translate(-54 -54)">
    <!-- Q: anello + codina -->
    <circle cx="38" cy="55" r="15.5" fill="none" stroke="{bianco}" stroke-width="7.5"/>
    <path d="M47.5 65.5 L56 74" stroke="{bianco}" stroke-width="7.5" stroke-linecap="round" fill="none"/>
    <!-- dentro la Q: tre barre che salgono (economia) -->
    <rect x="30.2" y="56" width="4.6" height="7" rx="1.3" fill="{barre[0]}"/>
    <rect x="36.2" y="51.5" width="4.6" height="11.5" rx="1.3" fill="{barre[1]}"/>
    <rect x="42.2" y="46" width="4.6" height="17" rx="1.3" fill="{barre[2]}"/>
    <!-- V: il braccio destro sale come un fusto -->
    <path d="M60 41 L69 71 L85 37" stroke="{bianco}" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    <!-- germoglio (crescita personale) -->
    <path d="M85 37 C85 27 91 22 99 21.5 C99.5 30 94 36.5 85 37 Z" fill="{foglia}"/>
    <path d="M85 37 C85 30 80 25 74 24.5 C73.5 31 78 36 85 37 Z" fill="{foglia}" opacity="0.9"/>
  </g>'''

def sfondo():
    return '''
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#0A4C86"/><stop offset="0.55" stop-color="#0A7C8A"/><stop offset="1" stop-color="#35C0C8"/>
    </linearGradient>
    <radialGradient id="sole" cx="0.85" cy="0.12" r="0.6">
      <stop offset="0" stop-color="#FBFFD8" stop-opacity="0.75"/><stop offset="1" stop-color="#FBFFD8" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="108" height="108" fill="url(#g)"/>
  <rect width="108" height="108" fill="url(#sole)"/>'''

def svg(corpo, bordo=False):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108" width="108" height="108">{corpo}</svg>'

open("sfondo.svg","w").write(svg(sfondo()))
open("primo_piano.svg","w").write(svg(simbolo()))
open("monocromo.svg","w").write(svg(simbolo(mono=True)))
# icona completa per il lancio "vecchio stile" (Android 7): quadrato arrotondato
open("completa.svg","w").write(svg(
  '<defs><clipPath id="c"><rect width="108" height="108" rx="24"/></clipPath></defs><g clip-path="url(#c)">'+sfondo()+simbolo()+'</g>'))
# anteprima grande con maschere diverse
open("anteprima.html","w").write('''<body style="margin:0;background:#e9f3f5;display:flex;gap:24px;padding:24px;align-items:center;font-family:sans-serif">
<div><img src="completa.svg" width="300"></div>
<div style="width:200px;height:200px;border-radius:50%;overflow:hidden;position:relative"><img src="sfondo.svg" width="200" style="position:absolute"><img src="primo_piano.svg" width="200" style="position:absolute"></div>
<div style="width:96px;height:96px;border-radius:26px;overflow:hidden;position:relative"><img src="sfondo.svg" width="96" style="position:absolute"><img src="primo_piano.svg" width="96" style="position:absolute"></div>
<div style="width:48px;height:48px;border-radius:14px;overflow:hidden;position:relative"><img src="sfondo.svg" width="48" style="position:absolute"><img src="primo_piano.svg" width="48" style="position:absolute"></div>
</body>''')

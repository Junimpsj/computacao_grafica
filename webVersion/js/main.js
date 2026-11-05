/* Janela principal: um TPageControl com uma aba por pratica (equivalente a uMain.pas).
   #N na URL abre a aba N direto (ex.: index.html#7). */
const ABAS = [
  ['1 HSL', abaHSL], ['2 Pixels', abaPixels], ['3 Retas', abaRetas3], ['4 Bresenham', abaBresenham],
  ['5 Circulos', abaCirculos5], ['6 Bresenham Circ', abaBresenhamCirc], ['7 Casinha 3D', abaCasinha],
  ['8 Clipping', abaClipping], ['9 Preenchimento', abaPreenchimento], ['10 Z-Buffer', abaZBuffer],
];

const tira = document.getElementById('abas');
const paginas = document.getElementById('paginas');
const botoes = [], divs = [];

function seleciona(i) {
  botoes.forEach((b, j) => { b.classList.toggle('ativa', i === j); divs[j].hidden = i !== j; });
  try { history.replaceState(null, '', '#' + (i + 1)); } catch (e) { /* file:// restrito: ignora */ }
}

ABAS.forEach(([titulo, monta], i) => {
  const pagina = el('div', { class: 'pagina', hidden: true });
  paginas.append(pagina);
  monta(pagina);
  const b = botao(titulo, () => seleciona(i));
  b.className = 'aba';
  tira.append(b);
  botoes.push(b); divs.push(pagina);
});

seleciona(Math.min(ABAS.length, Math.max(1, parseInt(location.hash.slice(1), 10) || 1)) - 1);

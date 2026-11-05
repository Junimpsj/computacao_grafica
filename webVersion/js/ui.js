/* Helpers de interface (equivalente a uUI.pas + uAreaDesenho.pas).
   AreaDesenho guarda um buffer proprio de pixels (TColor 0x00BBGGRR); os algoritmos
   plotam NELE pixel a pixel e atualizar() copia o buffer para o canvas. */

function el(tag, props = {}, ...kids) {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(props)) {
    if (k === 'class') e.className = v;
    else if (k === 'style') e.style.cssText = v;
    else if (k in e) e[k] = v;
    else e.setAttribute(k, v);
  }
  e.append(...kids.flat());
  return e;
}

const rotulo = (txt, w) => el('label', { textContent: txt, style: w ? `min-width:${w}px` : '' });
const campo = (txt, w = 50) => el('input', { type: 'text', value: txt, style: `width:${w}px` });
const botao = (txt, fn) => el('button', { type: 'button', textContent: txt, onclick: fn });
const grupo = (titulo, ...kids) => el('fieldset', {}, el('legend', { textContent: titulo }), ...kids);
const linha = (...kids) => el('div', { class: 'linha' }, ...kids);

let _radioId = 0;
/* grupo de radios (TRadioGroup): get() devolve o indice marcado */
function radios(titulo, itens, sel = 0, colunas = 1) {
  const nome = 'rg' + _radioId++;
  const inputs = itens.map((t, i) => el('input', { type: 'radio', name: nome, checked: i === sel }));
  const lista = el('div', { class: 'radios', style: `grid-template-columns:repeat(${colunas},auto)` },
    ...itens.map((t, i) => el('label', {}, inputs[i], t)));
  return { el: grupo(titulo, lista), get: () => inputs.findIndex(r => r.checked) };
}

function check(txt, marcado = false, onchange = null) {
  const input = el('input', { type: 'checkbox', checked: marcado, onchange });
  return { el: el('label', {}, input, txt), get checked() { return input.checked; } };
}

/* le real aceitando ponto ou virgula; invalido -> padrao (StrToFloatDef) */
function flt(input, padrao = 0) {
  const t = input.value.trim().replace(',', '.');
  const v = t === '' ? NaN : Number(t);
  return Number.isFinite(v) ? v : padrao;
}
/* le inteiro; invalido -> 0 (StrToIntDef). Limitado a +-100000: valores absurdos travariam os lacos de tracado */
const inteiro = input => (/^-?\d+$/.test(input.value.trim()) ? Math.max(-100000, Math.min(100000, parseInt(input.value, 10))) : 0);

class AreaDesenho {
  constructor(pagina, larg, alt, fundo) {
    this.fundo = fundo;
    this.contagem = 0;                       // pixels plotados (a aba zera e le)
    this.barra = el('div', { class: 'barra' });
    this.canvas = el('canvas', { class: 'tela' });
    this.ctx = this.canvas.getContext('2d', { willReadFrequently: true });
    this.lblXY = el('span', { class: 'xy', textContent: 'x,y = -' });
    this.lblInfo = el('span', { class: 'info' });
    this.onLimpar = this.onMover = this.onDown = this.onUp = null;
    this.plot = (x, y, cor) => {             // vai direto como TPlotProc
      if (x >= 0 && y >= 0 && x < this.W && y < this.H) { this.buf[y * this.W + x] = cor; this.contagem++; }
    };

    pagina.append(
      this.barra,
      el('div', { class: 'caixa' }, this.canvas),
      el('div', { class: 'rodape' },
        botao('Limpar', () => { this.limpar(); this.onLimpar?.(); }), this.lblXY, this.lblInfo));

    const pos = e => { const r = this.canvas.getBoundingClientRect(); return [Math.floor(e.clientX - r.left), Math.floor(e.clientY - r.top)]; };
    this.canvas.addEventListener('contextmenu', e => e.preventDefault());
    this.canvas.addEventListener('pointerdown', e => {
      this.canvas.setPointerCapture(e.pointerId);
      this.onDown?.(...pos(e), e.button);
    });
    this.canvas.addEventListener('pointermove', e => {
      const [x, y] = pos(e);
      this.lblXY.textContent = `x,y = ${x},${y}`;
      this.onMover?.(x, y);
    });
    this.canvas.addEventListener('pointerup', e => this.onUp?.(...pos(e)));
    this.redimensionar(larg, alt);
  }

  set info(s) { this.lblInfo.textContent = s; }
  get largura() { return this.W; }
  get altura() { return this.H; }

  redimensionar(larg, alt) {
    this.W = this.canvas.width = larg;
    this.H = this.canvas.height = alt;
    this.buf = new Int32Array(larg * alt);
    this.img = this.ctx.createImageData(larg, alt);
    this.u32 = new Uint32Array(this.img.data.buffer);
    this.limpar();
  }
  limpar() { this.buf.fill(this.fundo); this.atualizar(); }
  ler(x, y) { return x >= 0 && y >= 0 && x < this.W && y < this.H ? this.buf[y * this.W + x] : this.fundo; }
  atualizar() {                              // buffer -> tela (0x00BBGGRR | alfa = ABGR do canvas)
    for (let i = 0; i < this.buf.length; i++) this.u32[i] = this.buf[i] | 0xFF000000;
    this.ctx.putImageData(this.img, 0, 0);
  }
  copiar() { return this.buf.slice(); }
  colar(orig, larg, alt) {
    if (larg !== this.W || alt !== this.H) this.redimensionar(larg, alt);
    this.buf.set(orig);
    this.atualizar();
  }
  carregarDeImageData(d) {                   // ImageData -> buffer (redimensiona)
    this.redimensionar(d.width, d.height);
    for (let i = 0; i < this.buf.length; i++) this.buf[i] = d.data[4 * i] | (d.data[4 * i + 1] << 8) | (d.data[4 * i + 2] << 16);
    this.atualizar();
  }
}

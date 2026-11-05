/* Uma funcao por aba (equivalente aos f*.pas). Cada uma recebe o <div> da pagina.
   A matematica fica toda em CG (algo.js). Cores em TColor 0x00BBGGRR. */

const BRANCO = 0xFFFFFF, PRETO = 0, VERMELHO = 0x0000FF;

/* ---------------- ABA 1 - HSL (Aula 03) ---------------- */
function abaHSL(p) {
  const eR = campo('255', 60), eG = campo('0', 60), eB = campo('0', 60);
  const eH = campo('0', 60), eS = campo('240', 60), eL = campo('120', 60);
  const amostra = el('div', { class: 'amostra', textContent: 'amostra', style: 'background:rgb(255,0,0)' });
  const num = (e, max) => { const v = Math.min(max, Math.max(0, inteiro(e))); e.value = v; return v; };
  const mostra = (r, g, b) => { amostra.style.background = `rgb(${r},${g},${b})`; };

  const rgbHsl = () => {
    const R = num(eR, 255), G = num(eG, 255), B = num(eB, 255);
    const [H, L, S] = CG.rgbParaHLS(R, G, B);
    eH.value = H; eS.value = S; eL.value = L;
    mostra(R, G, B);
  };
  const hslRgb = () => {
    const [R, G, B] = CG.hlsParaRGB(num(eH, 239), num(eL, 240), num(eS, 240));
    eR.value = R; eG.value = G; eB.value = B;
    mostra(R, G, B);
  };
  const limpar = () => { [eR, eG, eB, eH, eS, eL].forEach(e => { e.value = 0; }); mostra(0, 0, 0); };

  p.append(el('div', { class: 'hsl' },
    el('div', { class: 'col' },
      linha(rotulo('R (0..255)', 70), eR), linha(rotulo('G (0..255)', 70), eG), linha(rotulo('B (0..255)', 70), eB),
      botao('RGB -> HSL', rgbHsl), botao('Limpar', limpar)),
    el('div', { class: 'col' },
      linha(rotulo('H (0..239)', 70), eH), linha(rotulo('S (0..240)', 70), eS), linha(rotulo('L (0..240)', 70), eL),
      botao('HSL -> RGB', hslRgb)),
    amostra));
}

/* ---------------- ABA 2 - Pixels (Aula 04) ---------------- */
function abaPixels(p) {
  const area = new AreaDesenho(p, 320, 240, BRANCO);
  let orig, ow, oh;
  const lblRGB = el('span', { class: 'dica', textContent: 'e) clique desenha ponto; mouse mostra R,G,B' });
  const media = check('media (R+G+B)/3');
  const arquivo = el('input', { type: 'file', accept: 'image/*', style: 'display:none' });

  const guarda = () => { orig = area.copiar(); ow = area.largura; oh = area.altura; };

  // imagem de teste (degrade colorido) para a aba funcionar sem abrir arquivo
  for (let y = 0; y < 240; y++)
    for (let x = 0; x < 320; x++) area.plot(x, y, CG.rgbParaCor(Math.floor(x * 255 / 319), Math.floor(y * 255 / 239), 255 - Math.floor(x * 255 / 319)));
  area.atualizar(); guarda();

  const percorre = fn => {
    for (let y = 0; y < area.altura; y++)
      for (let x = 0; x < area.largura; x++) { const [r, g, b] = CG.corParaRGB(area.ler(x, y)); area.plot(x, y, fn(r, g, b)); }
    area.atualizar();
  };

  arquivo.onchange = () => {                          // a) abrir imagem (bmp/png/jpg)
    const f = arquivo.files[0];
    if (!f) return;
    const img = new Image();
    img.onload = () => {
      const f = Math.min(1, 2000 / Math.max(img.width, img.height));   // lado maximo 2000 px: imagem gigante travaria a aba
      const w = Math.max(1, Math.round(img.width * f)), h = Math.max(1, Math.round(img.height * f));
      const c = el('canvas', { width: w, height: h }).getContext('2d');
      c.fillStyle = '#fff'; c.fillRect(0, 0, w, h);
      c.drawImage(img, 0, 0, w, h);
      area.carregarDeImageData(c.getImageData(0, 0, w, h));
      guarda();
      URL.revokeObjectURL(img.src);
    };
    img.onerror = () => alert('Nao foi possivel abrir a imagem.');
    img.src = URL.createObjectURL(f);
    arquivo.value = '';
  };

  // b) tons de cinza: I = 0.299 R + 0.587 G + 0.114 B (ou media simples)
  const cinza = () => percorre((r, g, b) => {
    const i = media.checked ? Math.floor((r + g + b) / 3) : CG.roundP(0.299 * r + 0.587 * g + 0.114 * b);
    return CG.rgbParaCor(i, i, i);
  });
  // c) inverter: 255 - canal
  const inverter = () => percorre((r, g, b) => CG.rgbParaCor(255 - r, 255 - g, 255 - b));
  // d) tres imagens lado a lado: so R, so G, so B
  const separar = () => {
    const src = area.copiar(), W = area.largura, H = area.altura;
    area.redimensionar(3 * W, H);
    for (let y = 0; y < H; y++)
      for (let x = 0; x < W; x++) {
        const [r, g, b] = CG.corParaRGB(src[y * W + x]);
        area.plot(x, y, CG.rgbParaCor(r, 0, 0));
        area.plot(W + x, y, CG.rgbParaCor(0, g, 0));
        area.plot(2 * W + x, y, CG.rgbParaCor(0, 0, b));
      }
    area.atualizar();
  };
  // f) unico lugar onde linha pronta do Canvas e permitida (LineTo do Lazarus)
  const retas = () => {
    const W = area.largura, H = area.altura, c = area.ctx;
    const traco = (cor, x1, y1, x2, y2) => { c.strokeStyle = cor; c.lineWidth = 1; c.beginPath(); c.moveTo(x1 + .5, y1 + .5); c.lineTo(x2 + .5, y2 + .5); c.stroke(); };
    traco('#000', W >> 1, 0, W >> 1, H - 1);
    traco('#000', 0, H >> 1, W - 1, H >> 1);
    traco('#f00', 0, 0, W - 1, H - 1);
    traco('#00f', 0, H - 1, W - 1, 0);
    area.carregarDeImageData(c.getImageData(0, 0, W, H));
  };

  area.onMover = (x, y) => {                          // e) pixel sob o mouse
    const [r, g, b] = CG.corParaRGB(area.ler(x, y));
    lblRGB.textContent = `e) pixel (${x},${y}): R=${r} G=${g} B=${b}`;
  };
  area.onDown = (x, y) => {                           // e) clique desenha ponto 3x3 vermelho
    for (let j = -1; j <= 1; j++) for (let i = -1; i <= 1; i++) area.plot(x + i, y + j, CG.rgbParaCor(255, 0, 0));
    area.atualizar();
  };
  area.onLimpar = () => { lblRGB.textContent = 'e) clique desenha ponto; mouse mostra R,G,B'; };

  area.barra.append(
    linha(botao('a) Abrir imagem', () => arquivo.click()), botao('b) Tons de cinza', cinza), media.el,
      botao('c) Inverter', inverter), botao('d) Separar R G B', separar),
      botao('Restaurar', () => area.colar(orig, ow, oh))),
    linha(botao('f) Retas (LineTo)', retas), lblRGB), arquivo);
}

/* ---------------- ABAS 3 e 4 - Retas / Bresenham (Aulas 05, 05A, 06) ---------------- */
function abaRetas(p, itens, desenha) {
  const area = new AreaDesenho(p, 640, 480, BRANCO);
  const metodo = radios('Metodo', itens);
  const eX1 = campo('100'), eY1 = campo('100'), eX2 = campo('400'), eY2 = campo('300');
  let temP1 = false;

  const desenhar = () => {
    area.contagem = 0;
    desenha(area, metodo.get(), inteiro(eX1), inteiro(eY1), inteiro(eX2), inteiro(eY2), PRETO);
    area.info = `pixels plotados: ${area.contagem}`;
    area.atualizar();
  };
  // estrela: raios em 16 direcoes (8 principais + 8 intermediarias) para testar todos os octantes
  const estrela = () => {
    const cores = [0x0000FF, 0x00A000, 0xFF0000, 0x0080FF], cx = area.largura >> 1, cy = area.altura >> 1;
    area.contagem = 0;
    for (let i = 0; i < 16; i++) {
      const a = i * Math.PI / 8;
      desenha(area, metodo.get(), cx, cy, cx + CG.arred(200 * Math.cos(a)), cy + CG.arred(200 * Math.sin(a)), cores[i % 4]);
    }
    area.info = `estrela: ${area.contagem} pixels plotados`;
    area.atualizar();
  };

  area.onDown = (x, y) => {
    if (!temP1) {
      eX1.value = x; eY1.value = y;
      for (const [dx, dy] of [[0, 0], [1, 0], [0, 1], [1, 1]]) area.plot(x + dx, y + dy, 0x808080);
      area.atualizar();
      temP1 = true;
    } else {
      eX2.value = x; eY2.value = y;
      temP1 = false;
      desenhar();
    }
  };
  area.onLimpar = () => { temP1 = false; };

  area.barra.append(
    metodo.el,
    el('div', { class: 'col' },
      linha(rotulo('x1'), eX1, rotulo('y1'), eY1), linha(rotulo('x2'), eX2, rotulo('y2'), eY2)),
    el('div', { class: 'col' }, botao('Desenhar reta', desenhar), botao('Desenhar estrela', estrela)),
    el('span', { class: 'dica', textContent: 'ou clique 2 pontos na area' }));
}

const abaRetas3 = p => abaRetas(p,
  ['A) Equacao geral', 'B) Parametrica (passo 1/max)', 'B) Parametrica (passo fixo 0.01)'],
  (a, m, x1, y1, x2, y2, cor) => {
    if (m === 0) CG.retaEquacaoGeral(x1, y1, x2, y2, cor, a.plot);
    else CG.retaParametrica(x1, y1, x2, y2, cor, a.plot, m === 1 ? 0 : 0.01);
  });

const abaBresenham = p => abaRetas(p, ['Bresenham (inteiros, 8 octantes)'],
  (a, m, x1, y1, x2, y2, cor) => CG.retaBresenham(x1, y1, x2, y2, cor, a.plot));

/* ---------------- ABAS 5 e 6 - Circulos / Bresenham circulo (Aulas 07, 08) ---------------- */
function abaCirculos(p, itens, comExtras, desenha) {
  const area = new AreaDesenho(p, 640, 480, BRANCO);
  const metodo = radios('Metodo', itens);
  const eXc = campo('320'), eYc = campo('240'), eR = campo('100'), ePasso = campo('0.05');
  const sim8 = check('simetria de 8 (metodo 1)');
  let base = null;                                    // imagem antes do arraste (previa)

  const desenhar = () => {
    area.contagem = 0;
    desenha(area, metodo.get(), inteiro(eXc), inteiro(eYc), inteiro(eR), PRETO, { passo: Math.max(0.001, flt(ePasso, 0.05)), sim8: sim8.checked });   // passo minimo evita laco quase infinito
    area.info = `pixels plotados: ${area.contagem}`;
    area.atualizar();
  };

  area.onDown = (x, y) => { eXc.value = x; eYc.value = y; base = area.copiar(); };
  area.onMover = (x, y) => {
    if (!base) return;
    const r = CG.arred(Math.hypot(x - inteiro(eXc), y - inteiro(eYc)));
    eR.value = r;
    area.colar(base, area.largura, area.altura);
    area.contagem = 0;
    desenha(area, metodo.get(), inteiro(eXc), inteiro(eYc), r, PRETO, { passo: Math.max(0.001, flt(ePasso, 0.05)), sim8: sim8.checked });
    area.info = `R=${r}  pixels plotados: ${area.contagem}`;
    area.atualizar();
  };
  area.onUp = () => { base = null; };

  area.barra.append(
    metodo.el,
    el('div', { class: 'col' },
      linha(rotulo('xc'), eXc, rotulo('yc'), eYc),
      linha(rotulo('R'), eR, ...(comExtras ? [rotulo('passo'), ePasso] : []))),
    el('div', { class: 'col' }, botao('Desenhar', desenhar), ...(comExtras ? [sim8.el] : [])),
    el('span', { class: 'dica', textContent: 'clique+arraste na area: centro e raio' }));
}

const abaCirculos5 = p => abaCirculos(p,
  ['1) y = sqrt(R2 - x2)', '2) Parametrica (cos, sen)', '3) Rotacoes incrementais (1 grau)'], true,
  (a, m, xc, yc, R, cor, o) => {
    if (m === 0) CG.circEquacao(xc, yc, R, cor, a.plot, o.sim8);
    else if (m === 1) CG.circParametrica(xc, yc, R, cor, a.plot, o.passo);
    else CG.circRotacoes(xc, yc, R, cor, a.plot);
  });

const abaBresenhamCirc = p => abaCirculos(p,
  ['Bresenham 2a ordem (dE, dSE)', 'Bresenham 1a ordem'], false,
  (a, m, xc, yc, R, cor) => (m === 0 ? CG.circBresenham : CG.circBresenham1)(xc, yc, R, cor, a.plot));

/* ---------------- ABA 7 - Casinha 3D (Aulas 11, 12, 12A) ---------------- */
function abaCasinha(p) {
  const area = new AreaDesenho(p, 640, 400, BRANCO);
  const VERT = [[0, 0, 0], [100, 0, 0], [100, 100, 0], [50, 150, 0], [0, 100, 0],
                [0, 0, 100], [100, 0, 100], [100, 100, 100], [50, 150, 100], [0, 100, 100]];
  const AREST = [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0], [5, 6], [6, 7], [7, 8], [8, 9], [9, 5],
                 [0, 5], [1, 6], [2, 7], [3, 8], [4, 9]];
  const ESCALA = 2;                                   // pixels por unidade do mundo
  let obj;                                            // objeto ATUAL (cumulativo)

  const op = radios('Operacao', ['Escala Local', 'Escala Global', 'Translacao', 'Rotacao (origem)', 'Rotacao (centro)', 'Shearing'], 2);
  const eixo = radios('Eixo', ['X', 'Y', 'Z'], 2, 3);
  const eSx = campo('1', 44), eSy = campo('1', 44), eSz = campo('1', 44), eS = campo('1', 44);
  const eTx = campo('0', 44), eTy = campo('0', 44), eTz = campo('0', 44), eGraus = campo('30', 44);
  const shear = [0, 1, 2, 3].map(i => [0, 1, 2, 3].map(j => campo(i === j ? '1' : '0', 44)));

  function matrizDaOperacao() {
    const ax = 'XYZ'[eixo.get()];
    switch (op.get()) {
      case 0: return CG.matEscalaLocal(flt(eSx, 1), flt(eSy, 1), flt(eSz, 1));
      case 1: { const s = flt(eS, 1); return s !== 0 ? CG.matEscalaGlobal(s) : CG.matIdentidade(); }
      case 2: return CG.matTranslacao(flt(eTx), flt(eTy), flt(eTz));
      case 3: return CG.matRot(ax, flt(eGraus));
      case 4: { const c = CG.centroMedio(obj); return CG.matRotCentro(ax, flt(eGraus), c.x, c.y, c.z); }
      default: { const M = CG.matIdentidade(); shear.forEach((l, i) => l.forEach((e, j) => { M[i][j] = flt(e, M[i][j]); })); return M; }
    }
  }

  // Projecao ortogonal em z=0 (descarta z); janela -> porta de visao (Aula 13); y invertido no fim
  function desenhar() {
    const W = area.largura, H = area.altura;
    const xmin = 50 - W / (2 * ESCALA), xmax = 50 + W / (2 * ESCALA);
    const ymin = 75 - H / (2 * ESCALA), ymax = 75 + H / (2 * ESCALA);
    const PX = x => CG.arred(CG.janelaPorta(x, xmin, xmax, 0, W - 1));
    const PY = y => (H - 1) - CG.arred(CG.janelaPorta(y, ymin, ymax, 0, H - 1));
    area.limpar();
    CG.retaBresenham(0, PY(0), W - 1, PY(0), 0xC0C0C0, area.plot);
    CG.retaBresenham(PX(0), 0, PX(0), H - 1, 0xC0C0C0, area.plot);
    for (const [a, b] of AREST) {
      const v = [PX(obj[a].x), PY(obj[a].y), PX(obj[b].x), PY(obj[b].y)];
      if (v.every(n => Math.abs(n) < 1e5)) CG.retaBresenham(...v, PRETO, area.plot);   // escala absurda (ou NaN): pula a aresta
    }
    const c = CG.centroMedio(obj);
    area.info = `centro do objeto = (${c.x.toFixed(1)}, ${c.y.toFixed(1)}, ${c.z.toFixed(1)})`;
    area.atualizar();
  }
  const reiniciar = () => { obj = VERT.map(([x, y, z]) => ({ x, y, z })); desenhar(); };

  area.barra.append(
    op.el,
    el('div', { class: 'col' },
      linha(rotulo('Sx'), eSx, rotulo('Sy'), eSy, rotulo('Sz'), eSz),
      linha(rotulo('s (global)'), eS),
      linha(rotulo('Tx'), eTx, rotulo('Ty'), eTy, rotulo('Tz'), eTz),
      linha(eixo.el, rotulo('graus'), eGraus),
      linha(botao('EXECUTA', () => { obj = CG.aplicaLista(obj, matrizDaOperacao()); desenhar(); }), botao('Reset', reiniciar),
        el('span', { class: 'dica', textContent: 's>1 reduz, s<1 amplia' }))),
    grupo('Shearing (matriz 4x4)', el('div', { class: 'matriz' }, ...shear.flat())));
  reiniciar();
}

/* ---------------- ABA 8 - Clipping (Aulas 15a/15b/15c) ---------------- */
function abaClipping(p) {
  const area = new AreaDesenho(p, 640, 480, BRANCO);
  const algo = radios('Algoritmo', ['Cohen-Sutherland', 'Liang-Barsky'], 0, 2);
  const descartada = check('mostrar parte descartada em cinza', true);
  const lblEstado = el('span', { class: 'dica' });
  const CJANELA = 0xFF0000, CRETA = 0, CDESC = 0xB0B0B0;
  let estado = 0;                                     // 0 = 1o canto, 1 = 2o canto, 2 = desenha retas
  let jx1, jy1, jx2, jy2, ax, ay, base = null;

  const texto = () => {
    lblEstado.textContent = ['clique o 1o canto da janela de recorte', 'clique o 2o canto da janela', 'arraste para desenhar retas'][estado];
  };
  const desenhaJanela = () => {
    const l = (a, b, c, d) => CG.retaBresenham(a, b, c, d, CJANELA, area.plot);
    l(jx1, jy1, jx2, jy1); l(jx2, jy1, jx2, jy2); l(jx2, jy2, jx1, jy2); l(jx1, jy2, jx1, jy1);
  };
  const reinicia = () => { estado = 0; base = null; texto(); };

  // tela tem y para baixo, o algoritmo usa y para cima: ym = (H-1) - ys
  function recortaEDesenha(x1, y1, x2, y2) {
    const H = area.altura;
    if (descartada.checked) CG.retaBresenham(x1, y1, x2, y2, CDESC, area.plot);
    const f = algo.get() === 0 ? CG.cohenSutherland : CG.liangBarsky;
    const r = f(jx1, (H - 1) - jy2, jx2, (H - 1) - jy1, x1, (H - 1) - y1, x2, (H - 1) - y2);
    if (r) {
      const [a, b, c, d] = r;
      CG.retaBresenham(CG.arred(a), (H - 1) - CG.arred(b), CG.arred(c), (H - 1) - CG.arred(d), CRETA, area.plot);
      area.info = `visivel: (${a.toFixed(2)}, ${((H - 1) - b).toFixed(2)}) - (${c.toFixed(2)}, ${((H - 1) - d).toFixed(2)})`;
    } else area.info = 'reta totalmente fora da janela (descartada)';
    desenhaJanela();                                  // janela por cima
  }

  area.onDown = (x, y) => {
    if (estado === 0) {
      jx1 = x; jy1 = y;
      for (const [dx, dy] of [[0, 0], [1, 0], [0, 1], [1, 1]]) area.plot(x + dx, y + dy, CJANELA);
      area.atualizar();
      estado = 1;
    } else if (estado === 1) {
      jx2 = x; jy2 = y;
      if (jx1 > jx2) [jx1, jx2] = [jx2, jx1];
      if (jy1 > jy2) [jy1, jy2] = [jy2, jy1];
      desenhaJanela(); area.atualizar();
      estado = 2;
    } else { ax = x; ay = y; base = area.copiar(); }
    texto();
  };
  area.onMover = (x, y) => {                          // previa da reta durante o arraste
    if (!base) return;
    area.colar(base, area.largura, area.altura);
    CG.retaBresenham(ax, ay, x, y, CDESC, area.plot);
    area.atualizar();
  };
  area.onUp = (x, y) => {
    if (!base) return;
    area.colar(base, area.largura, area.altura);
    base = null;
    recortaEDesenha(ax, ay, x, y);
    area.atualizar();
  };
  area.onLimpar = reinicia;

  area.barra.append(algo.el, el('div', { class: 'col' }, descartada.el,
    linha(botao('Nova janela', () => { area.limpar(); reinicia(); }), lblEstado)));
  texto();
}

/* ---------------- ABA 9 - Preenchimento (Aula 16) ---------------- */
function abaPreenchimento(p) {
  const area = new AreaDesenho(p, 640, 480, BRANCO);
  const modo = radios('Modo', ['1) Inversao de cores (edge fill)', '2) Flood fill (clique = semente)', '3) Scanline (lista ordenada)']);
  const viz = radios('Vizinhanca (flood)', ['4', '8'], 0, 2);
  const bbox = check('mostrar bounding box');
  const lblInfo = el('span', { class: 'dica', textContent: 'clique: vertices; direito: fecha' });
  const CBORDA = PRETO, CPREENCH = VERMELHO, CFUNDO = BRANCO;
  const GW = 32, GH = 24, ZOOM = 20;                  // grade de teste: 32x24 pixels logicos, zoom 20
  let poly = [], fechado = false, limpo, camada, passo = 0, modoGrade = false, grade;

  const aresta = i => {
    const a = poly[i], b = poly[(i + 1) % poly.length];
    CG.retaBresenham(a.x, a.y, b.x, b.y, CBORDA, area.plot);
  };
  const redesenha = () => {                           // camada de inversao + bordas (+ bbox)
    area.colar(camada, area.largura, area.altura);
    poly.forEach((_, i) => aresta(i));
    if (bbox.checked && poly.length) {
      const { xmin, ymin, xmax, ymax } = CG.boundingBox(poly), c = 0x808080;
      CG.retaBresenham(xmin, ymin, xmax, ymin, c, area.plot); CG.retaBresenham(xmax, ymin, xmax, ymax, c, area.plot);
      CG.retaBresenham(xmax, ymax, xmin, ymax, c, area.plot); CG.retaBresenham(xmin, ymax, xmin, ymin, c, area.plot);
    }
    area.atualizar();
  };
  const desenhaGrade = () => {
    for (let y = 0; y < GH; y++)
      for (let x = 0; x < GW; x++)
        for (let j = 0; j < ZOOM; j++)
          for (let i = 0; i < ZOOM; i++)
            area.plot(x * ZOOM + i, y * ZOOM + j, i === ZOOM - 1 || j === ZOOM - 1 ? 0xD0D0D0 : grade[y * GW + x]);
    area.atualizar();
  };
  const reinicia = () => { poly = []; fechado = false; modoGrade = false; passo = 0; lblInfo.textContent = 'clique: vertices; direito: fecha'; };

  const preencher = () => {
    if (!fechado) { lblInfo.textContent = 'feche o poligono (clique direito)'; return; }
    camada = limpo.slice();
    if (modo.get() === 2) {
      CG.preencheScanline(camada, area.largura, area.altura, poly, CPREENCH);
      lblInfo.textContent = 'preenchido (scanline)';
    } else {
      CG.preencheInversao(camada, area.largura, area.altura, poly, CFUNDO, CPREENCH);
      lblInfo.textContent = 'preenchido (inversao, todas as arestas)';
    }
    passo = poly.length;
    redesenha();
  };
  const passoAPasso = () => {                         // resultado depois de cada aresta
    if (!fechado) { lblInfo.textContent = 'feche o poligono (clique direito)'; return; }
    if (passo >= poly.length) { camada = limpo.slice(); passo = 0; }
    const { xmax } = CG.boundingBox(poly);
    const a = poly[passo], b = poly[(passo + 1) % poly.length];
    CG.inverteAresta(camada, area.largura, area.altura, a.x, a.y, b.x, b.y, xmax, CFUNDO, CPREENCH);
    passo++;
    redesenha();
    lblInfo.textContent = `aresta ${passo} de ${poly.length}`;
  };
  // losango cuja borda so se toca pelas diagonais: vizinhanca 4 nao atravessa, a 8 vaza
  const carregaGrade = () => {
    area.limpar(); reinicia(); modoGrade = true;
    grade = new Int32Array(GW * GH);
    for (let y = 0; y < GH; y++) for (let x = 0; x < GW; x++) grade[y * GW + x] = Math.abs(x - 16) + Math.abs(y - 12) === 9 ? CBORDA : CFUNDO;
    desenhaGrade();
    lblInfo.textContent = 'clique dentro do losango (troque 4/8 e recarregue)';
  };

  area.onDown = (x, y, botaoMouse) => {
    if (modoGrade) {
      CG.floodFill(grade, GW, GH, Math.floor(x / ZOOM), Math.floor(y / ZOOM), CBORDA, CPREENCH, viz.get() === 1);
      desenhaGrade();
      return;
    }
    if (fechado) {
      if (modo.get() === 1) {                         // flood fill sobre o buffer da area
        const buf = area.copiar();
        CG.floodFill(buf, area.largura, area.altura, x, y, CBORDA, CPREENCH, viz.get() === 1);
        area.colar(buf, area.largura, area.altura);
      }
      return;
    }
    if (botaoMouse === 2) {                           // direito: fecha o poligono
      if (poly.length >= 3) {
        aresta(poly.length - 1);
        fechado = true; camada = limpo.slice(); passo = 0;
        area.atualizar();
        lblInfo.textContent = 'poligono fechado';
      }
      return;
    }
    if (poly.length === 0) limpo = area.copiar();     // guarda a imagem antes das bordas
    poly.push({ x, y });
    if (poly.length === 1) area.plot(x, y, CBORDA);
    else { const a = poly[poly.length - 2]; CG.retaBresenham(a.x, a.y, x, y, CBORDA, area.plot); }
    area.atualizar();
  };
  area.onLimpar = reinicia;

  area.barra.append(modo.el,
    el('div', { class: 'col' }, viz.el, bbox.el),
    el('div', { class: 'col' }, botao('Preencher (modo 1 ou 3)', preencher), botao('Passo a passo', passoAPasso),
      botao('Grade de teste', carregaGrade), lblInfo));
}

/* ---------------- ABA 10 - Z-Buffer (Aula 17) ---------------- */
function abaZBuffer(p) {
  const area = new AreaDesenho(p, 640, 480, PRETO);
  const zb = new CG.ZBuffer(area.largura, area.altura, PRETO);
  const NOMES = ['1 azul z=x2+y', '2 verm. plano', '3 amar. cone', '4 verde esfera', '5 branco cubo'];
  const eixo = radios('Eixo (rotacao na origem)', ['X', 'Y', 'Z'], 1, 3);
  const eGraus = campo('20'), eZoom = campo('1');
  let M = CG.matIdentidade();                         // rotacao acumulada
  const cx = area.largura / 2, cy = area.altura / 2;
  // escala que faz TODOS os objetos caberem: o raio maximo nao muda com a rotacao
  const k0 = Math.min(area.largura, area.altura) / 2 * 0.95 / CG.raioMaximo();
  let k = k0;

  const chk = NOMES.map(n => check(n, true, () => renderiza()));

  function renderiza() {
    zb.limpar(PRETO);                                 // zbuffer = maior valor possivel
    const emite = (x, y, z, c) => {
      const q = CG.aplicaPonto({ x, y, z }, M);       // rotacao; projecao ortogonal ignora z na posicao
      zb.ponto(CG.roundP(cx + q.x * k), CG.roundP(cy - q.y * k), q.z, c);
    };
    chk.forEach((c, i) => { if (c.checked) CG.geraObjeto(i + 1, 0.6 / k, emite); });   // passo <= 0.6 pixel
    area.colar(zb.cor, area.largura, area.altura);
  }

  area.onLimpar = () => zb.limpar(PRETO);             // "Rotaciona" ou "Reset" redesenha

  area.barra.append(
    linha(...chk.map(c => c.el)),
    linha(eixo.el, rotulo('graus'), eGraus,
      botao('Rotaciona', () => { M = CG.matMul(M, CG.matRot('XYZ'[eixo.get()], flt(eGraus))); renderiza(); }),
      botao('Reset', () => { M = CG.matIdentidade(); renderiza(); }),
      rotulo('zoom'), eZoom,
      botao('Aplicar zoom', () => { const z = flt(eZoom, 1); k = k0 * (z > 0 ? Math.min(z, 10) : 1); renderiza(); })));   // zoom maximo 10: acima disso o passo de amostragem explode
  renderiza();
}

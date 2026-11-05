/* Algoritmos das praticas, portados 1:1 das units Pascal de algo/ (mesma matematica).
   Cores no formato TColor do Lazarus: 0x00BBGGRR. Sem DOM: roda no navegador e no Node.
   Cada bloco cita a unit de origem. */
const CG = (() => {
  const idiv = (a, b) => Math.trunc(a / b);            // "div" do Pascal
  const arred = v => Math.floor(v + 0.5);              // uLinhas.Arred (.5 sobe)
  const roundP = v => {                                // Round do Pascal (bancario)
    let r = Math.round(v);
    if (Math.abs(v % 1) === 0.5 && r % 2 !== 0) r--;
    return r;
  };

  /* ---------- uCores (Aula 03) ---------- */
  const HLSMAX = 240, RGBMAX = 255, INDEFINIDO = idiv(HLSMAX * 2, 3);
  const rgbParaCor = (R, G, B) => R | (G << 8) | (B << 16);
  const corParaRGB = c => [c & 255, (c >> 8) & 255, (c >> 16) & 255];

  function rgbParaHLS(R, G, B) {
    const cMax = Math.max(R, G, B), cMin = Math.min(R, G, B);
    let H, S;
    const L = idiv((cMax + cMin) * HLSMAX + RGBMAX, 2 * RGBMAX);
    if (cMax === cMin) { S = 0; H = INDEFINIDO; }
    else {
      if (L <= idiv(HLSMAX, 2)) S = idiv((cMax - cMin) * HLSMAX + idiv(cMax + cMin, 2), cMax + cMin);
      else S = idiv((cMax - cMin) * HLSMAX + idiv(2 * RGBMAX - cMax - cMin, 2), 2 * RGBMAX - cMax - cMin);
      const d = c => idiv((cMax - c) * idiv(HLSMAX, 6) + idiv(cMax - cMin, 2), cMax - cMin);
      const Rd = d(R), Gd = d(G), Bd = d(B);
      if (R === cMax) H = Bd - Gd;
      else if (G === cMax) H = idiv(HLSMAX, 3) + Rd - Bd;
      else H = idiv(2 * HLSMAX, 3) + Gd - Rd;
      if (H < 0) H += HLSMAX;
      if (H >= HLSMAX) H -= HLSMAX;
    }
    return [H, L, S];
  }

  function hueToRGB(n1, n2, hue) {
    if (hue < 0) hue += HLSMAX;
    if (hue > HLSMAX) hue -= HLSMAX;
    if (hue < idiv(HLSMAX, 6)) return n1 + idiv((n2 - n1) * hue + idiv(HLSMAX, 12), idiv(HLSMAX, 6));
    if (hue < idiv(HLSMAX, 2)) return n2;
    if (hue < idiv(HLSMAX * 2, 3))
      return n1 + idiv((n2 - n1) * (idiv(HLSMAX * 2, 3) - hue) + idiv(HLSMAX, 12), idiv(HLSMAX, 6));
    return n1;
  }

  function hlsParaRGB(H, L, S) {
    let R, G, B;
    if (S === 0) { R = G = B = idiv(L * RGBMAX, HLSMAX); }
    else {
      const m2 = L <= idiv(HLSMAX, 2) ? idiv(L * (HLSMAX + S) + idiv(HLSMAX, 2), HLSMAX)
                                      : L + S - idiv(L * S + idiv(HLSMAX, 2), HLSMAX);
      const m1 = 2 * L - m2;
      const f = h => idiv(hueToRGB(m1, m2, h) * RGBMAX + idiv(HLSMAX, 2), HLSMAX);
      R = f(H + idiv(HLSMAX, 3)); G = f(H); B = f(H - idiv(HLSMAX, 3));
    }
    const c = v => Math.min(RGBMAX, Math.max(0, v));
    return [c(R), c(G), c(B)];
  }

  /* ---------- uLinhas (Aulas 05, 05A, 06) ---------- */
  function retaEquacaoGeral(x1, y1, x2, y2, cor, plot) {
    const dx = x2 - x1, dy = y2 - y1;
    if (dx === 0 && dy === 0) { plot(x1, y1, cor); return; }
    if (dx === 0) {                                     // vertical: m seria infinito
      const inc = Math.sign(dy);
      for (let y = y1; y !== y2 + inc; y += inc) plot(x1, y, cor);
      return;
    }
    const m = dy / dx;
    if (Math.abs(dx) >= Math.abs(dy)) {
      const inc = Math.sign(dx);
      for (let x = x1; x !== x2 + inc; x += inc) plot(x, arred(m * (x - x1) + y1), cor);
    } else {
      const inc = Math.sign(dy);
      for (let y = y1; y !== y2 + inc; y += inc) plot(arred((y - y1) / m + x1), y, cor);
    }
  }

  // passo <= 0: automatico 1/max(|dx|,|dy|); senao passo fixo (ex.: 0.01)
  function retaParametrica(x1, y1, x2, y2, cor, plot, passo = 0) {
    const n = Math.max(Math.abs(x2 - x1), Math.abs(y2 - y1));
    if (passo <= 0) {
      if (n === 0) { plot(x1, y1, cor); return; }       // (no Pascal plota 2x e divide 0/0)
      for (let i = 0; i <= n; i++) {
        const t = i / n;
        plot(arred(x1 + (x2 - x1) * t), arred(y1 + (y2 - y1) * t), cor);
      }
    } else {
      for (let i = 0, t = 0; t <= 1 + 1e-9; t = ++i * passo)
        plot(arred(x1 + (x2 - x1) * t), arred(y1 + (y2 - y1) * t), cor);
    }
  }

  // Bresenham: d = 2dy-dx, dE = 2dy, dNE = 2(dy-dx); d<0 -> E, senao NE
  function retaBresenham(x1, y1, x2, y2, cor, plot) {
    let dx = Math.abs(x2 - x1), dy = Math.abs(y2 - y1);
    const sx = Math.sign(x2 - x1) || 1, sy = Math.sign(y2 - y1) || 1;
    const trocou = dy > dx;
    if (trocou) [dx, dy] = [dy, dx];                    // eixo rapido = dx
    let d = 2 * dy - dx;
    const dE = 2 * dy, dNE = 2 * (dy - dx);
    let x = x1, y = y1;
    for (let i = 0; i <= dx; i++) {
      plot(x, y, cor);
      if (d < 0) { d += dE; if (trocou) y += sy; else x += sx; }
      else { d += dNE; x += sx; y += sy; }
    }
  }

  /* ---------- uCirculos (Aulas 07 e 08) ---------- */
  function plota8(xc, yc, x, y, cor, plot) {
    plot(xc + x, yc + y, cor);
    if (x !== y) plot(xc + y, yc + x, cor);
    if (x !== 0) plot(xc - x, yc + y, cor);
    if (x !== y) plot(xc - y, yc + x, cor);
    plot(xc + x, yc - y, cor);
    if (x !== y && x !== 0) plot(xc + y, yc - x, cor);
    if (x !== 0) plot(xc - x, yc - y, cor);
    if (x !== y && x !== 0) plot(xc - y, yc - x, cor);
  }

  function circEquacao(xc, yc, R, cor, plot, simetria8 = false) {
    if (simetria8) {
      const lim = arred(R / Math.SQRT2);
      for (let x = 0; x <= lim; x++) plota8(xc, yc, x, arred(Math.sqrt(R * R - x * x)), cor, plot);
    } else {
      for (let x = -R; x <= R; x++) {
        const y = arred(Math.sqrt(R * R - x * x));
        plot(xc + x, yc + y, cor);
        plot(xc + x, yc - y, cor);
      }
    }
  }

  function circParametrica(xc, yc, R, cor, plot, passo = 0) {
    if (passo <= 0) passo = R > 0 ? 1 / R : 1;
    for (let a = 0; a < 2 * Math.PI; a += passo)
      plot(xc + arred(R * Math.cos(a)), yc + arred(R * Math.sin(a)), cor);
  }

  function circRotacoes(xc, yc, R, cor, plot) {         // 360 rotacoes de 1 grau
    const c = Math.cos(Math.PI / 180), s = Math.sin(Math.PI / 180);
    let x = R, y = 0;
    for (let i = 1; i <= 360; i++) {
      const xn = x * c - y * s;
      y = x * s + y * c;
      x = xn;
      plot(xc + arred(x), yc + arred(y), cor);
    }
  }

  function circBresenham(xc, yc, R, cor, plot) {        // 2a ordem (dE, dSE)
    let x = 0, y = R, h = 1 - R, dE = 3, dSE = -2 * R + 5;
    plota8(xc, yc, x, y, cor, plot);
    while (x < y) {
      if (h < 0) { h += dE; dE += 2; dSE += 2; }
      else { h += dSE; dE += 2; dSE += 4; y--; }
      x++;
      if (x <= y) plota8(xc, yc, x, y, cor, plot);
    }
  }

  function circBresenham1(xc, yc, R, cor, plot) {       // 1a ordem
    let x = 0, y = R, h = 1 - R;
    plota8(xc, yc, x, y, cor, plot);
    while (x < y) {
      if (h < 0) h += 2 * x + 3;
      else { h += 2 * (x - y) + 5; y--; }
      x++;
      if (x <= y) plota8(xc, yc, x, y, cor, plot);
    }
  }

  /* ---------- uMatriz (Aulas 11, 12, 12A, 13): vetor linha [x y z 1] . M ---------- */
  const matIdentidade = () => [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]];
  function matMul(A, B) {                               // aplica A, depois B
    const R = matIdentidade();
    for (let i = 0; i < 4; i++)
      for (let j = 0; j < 4; j++) {
        let s = 0;
        for (let k = 0; k < 4; k++) s += A[i][k] * B[k][j];
        R[i][j] = s;
      }
    return R;
  }
  const matEscalaLocal = (sx, sy, sz) => { const M = matIdentidade(); M[0][0] = sx; M[1][1] = sy; M[2][2] = sz; return M; };
  const matEscalaGlobal = s => { const M = matIdentidade(); M[3][3] = s; return M; };
  const matTranslacao = (tx, ty, tz) => { const M = matIdentidade(); M[3][0] = tx; M[3][1] = ty; M[3][2] = tz; return M; };
  function matRot(eixo, graus) {
    const a = graus * Math.PI / 180, c = Math.cos(a), s = Math.sin(a), M = matIdentidade();
    if (eixo === 'X') { M[1][1] = c; M[1][2] = s; M[2][1] = -s; M[2][2] = c; }
    else if (eixo === 'Y') { M[0][0] = c; M[0][2] = -s; M[2][0] = s; M[2][2] = c; }
    else { M[0][0] = c; M[0][1] = s; M[1][0] = -s; M[1][1] = c; }
    return M;
  }
  const matRotCentro = (eixo, graus, cx, cy, cz) =>
    matMul(matMul(matTranslacao(-cx, -cy, -cz), matRot(eixo, graus)), matTranslacao(cx, cy, cz));

  function aplicaPonto(p, M) {
    let x = p.x * M[0][0] + p.y * M[1][0] + p.z * M[2][0] + M[3][0];
    let y = p.x * M[0][1] + p.y * M[1][1] + p.z * M[2][1] + M[3][1];
    let z = p.x * M[0][2] + p.y * M[1][2] + p.z * M[2][2] + M[3][2];
    const w = p.x * M[0][3] + p.y * M[1][3] + p.z * M[2][3] + M[3][3];
    if (w !== 1 && w !== 0) { x /= w; y /= w; z /= w; }
    return { x, y, z };
  }
  const aplicaLista = (pts, M) => pts.map(p => aplicaPonto(p, M));
  function centroMedio(pts) {
    const n = pts.length || 1, c = { x: 0, y: 0, z: 0 };
    for (const p of pts) { c.x += p.x; c.y += p.y; c.z += p.z; }
    return { x: c.x / n, y: c.y / n, z: c.z / n };
  }
  const janelaPorta = (v, vmin, vmax, umin, umax) => (v - vmin) * (umax - umin) / (vmax - vmin) + umin;

  /* ---------- uClipping (Aulas 15a/15b/15c): y para cima; devolvem null ou [x1,y1,x2,y2] ---------- */
  const ACIMA = 1, ABAIXO = 2, DIREITA = 4, ESQUERDA = 8;
  function codigoRegiao(x, y, xmin, ymin, xmax, ymax) {
    let r = 0;
    if (y > ymax) r |= ACIMA; else if (y < ymin) r |= ABAIXO;
    if (x > xmax) r |= DIREITA; else if (x < xmin) r |= ESQUERDA;
    return r;
  }

  function cohenSutherland(xmin, ymin, xmax, ymax, x1, y1, x2, y2) {
    for (;;) {
      const c1 = codigoRegiao(x1, y1, xmin, ymin, xmax, ymax);
      const c2 = codigoRegiao(x2, y2, xmin, ymin, xmax, ymax);
      if (c1 === 0 && c2 === 0) return [x1, y1, x2, y2];   // aceitacao trivial
      if (c1 & c2) return null;                            // rejeicao trivial
      const cod = c1 !== 0 ? c1 : c2;
      const m = x2 !== x1 ? (y2 - y1) / (x2 - x1) : 0;
      let x, y;
      if (cod & ACIMA) { y = ymax; x = x2 === x1 ? x1 : (y - y1) / m + x1; }
      else if (cod & ABAIXO) { y = ymin; x = x2 === x1 ? x1 : (y - y1) / m + x1; }
      else if (cod & DIREITA) { x = xmax; y = m * (x - x1) + y1; }
      else { x = xmin; y = m * (x - x1) + y1; }
      if (cod === c1) { x1 = x; y1 = y; } else { x2 = x; y2 = y; }
    }
  }

  function liangBarsky(xmin, ymin, xmax, ymax, x0, y0, x2, y2) {
    const dx = x2 - x0, dy = y2 - y0;
    const p = [-dx, dx, -dy, dy];
    const q = [x0 - xmin, xmax - x0, y0 - ymin, ymax - y0];
    let u1 = 0, u2 = 1;
    for (let k = 0; k < 4; k++) {
      if (p[k] === 0) { if (q[k] < 0) return null; }       // paralela e fora
      else {
        const r = q[k] / p[k];
        if (p[k] < 0) { if (r > u1) u1 = r; } else if (r < u2) u2 = r;
      }
    }
    if (u1 > u2) return null;
    return [x0 + u1 * dx, y0 + u1 * dy, x0 + u2 * dx, y0 + u2 * dy];
  }

  /* ---------- uPreenchimento (Aula 16): B = array linha a linha, W x H ---------- */
  function boundingBox(poly) {
    const xs = poly.map(p => p.x), ys = poly.map(p => p.y);
    return { xmin: Math.min(...xs), ymin: Math.min(...ys), xmax: Math.max(...xs), ymax: Math.max(...ys) };
  }

  function inverteAresta(B, W, H, x1, y1, x2, y2, xmaxBB, corFundo, corPreench) {
    if (y1 === y2) return;
    if (y1 > y2) { [x1, x2] = [x2, x1]; [y1, y2] = [y2, y1]; }
    for (let y = y1; y < y2; y++) {                        // [ymin, ymax)
      if (y < 0 || y >= H) continue;
      const xi = arred(x1 + (y - y1) * (x2 - x1) / (y2 - y1));
      for (let x = Math.max(xi, 0); x <= Math.min(xmaxBB, W - 1); x++)
        B[y * W + x] = B[y * W + x] === corPreench ? corFundo : corPreench;
    }
  }

  function preencheInversao(B, W, H, poly, corFundo, corPreench) {
    if (poly.length < 3) return;
    const { xmax } = boundingBox(poly);
    poly.forEach((a, i) => {
      const b = poly[(i + 1) % poly.length];
      inverteAresta(B, W, H, a.x, a.y, b.x, b.y, xmax, corFundo, corPreench);
    });
  }

  function preencheScanline(B, W, H, poly, corPreench) {
    const n = poly.length;
    if (n < 3) return;
    const { ymin, ymax } = boundingBox(poly);
    for (let y = ymin; y < ymax; y++) {
      if (y < 0 || y >= H) continue;
      const xs = [];
      for (let i = 0; i < n; i++) {
        let { x: x1, y: y1 } = poly[i], { x: x2, y: y2 } = poly[(i + 1) % n];
        if (y1 === y2) continue;
        if (y1 > y2) { [x1, x2] = [x2, x1]; [y1, y2] = [y2, y1]; }
        if (y >= y1 && y < y2) xs.push(arred(x1 + (y - y1) * (x2 - x1) / (y2 - y1)));
      }
      xs.sort((a, b) => a - b);                            // lista ORDENADA de intersecoes
      for (let p = 0; p + 1 < xs.length; p += 2)
        for (let x = Math.max(xs[p], 0); x <= Math.min(xs[p + 1] - 1, W - 1); x++) B[y * W + x] = corPreench;
    }
  }

  function floodFill(B, W, H, sx, sy, corBorda, corPreench, oito) {   // pilha explicita
    if (sx < 0 || sy < 0 || sx >= W || sy >= H) return;
    const pilha = [sy * W + sx];
    while (pilha.length) {
      const i = pilha.pop(), x = i % W, y = Math.floor(i / W);
      if (B[i] === corBorda || B[i] === corPreench) continue;
      B[i] = corPreench;
      for (let dy = -1; dy <= 1; dy++)
        for (let dx = -1; dx <= 1; dx++) {
          if (dx === 0 && dy === 0) continue;
          if (!oito && dx !== 0 && dy !== 0) continue;     // 4: sem diagonais
          const nx = x + dx, ny = y + dy;
          if (nx >= 0 && ny >= 0 && nx < W && ny < H) {
            const c = B[ny * W + nx];
            if (c !== corBorda && c !== corPreench) pilha.push(ny * W + nx);
          }
        }
    }
  }

  /* ---------- uZBuffer (Aula 17): menor z vence ---------- */
  class ZBuffer {
    constructor(W, H, fundo) { this.W = W; this.H = H; this.z = new Float64Array(W * H); this.cor = new Int32Array(W * H); this.limpar(fundo); }
    limpar(fundo) { this.z.fill(Number.MAX_VALUE); this.cor.fill(fundo); }
    ponto(x, y, z, c) {
      if (x < 0 || y < 0 || x >= this.W || y >= this.H) return;
      const i = y * this.W + x;
      if (z < this.z[i]) { this.z[i] = z; this.cor[i] = c; }
    }
  }

  const NUM_OBJETOS = 5;
  const EscalaZ1 = 0.1;      // z do objeto 1 (ate 940) e reduzido para nao sair da tela ao rotacionar
  const CorObj = [0, 0xFF0000, 0x0000FF, 0x00FFFF, 0x00C000, 0xFFFFFF];   // azul, verm., amar., verde, branco

  // amostra a superficie do objeto n; passo = distancia 3D maxima entre amostras
  function geraObjeto(n, passo, emite) {
    const c = CorObj[n];
    switch (n) {
      case 1: {                                            // z = x^2 + y, x[10,30], y[20,40]
        const nu = Math.ceil(20 / (passo / 6.1)), nv = Math.ceil(20 / (passo / 1.1));
        for (let i = 0; i <= nu; i++)
          for (let j = 0; j <= nv; j++) {
            const x = 10 + 20 * i / nu, y = 20 + 20 * j / nv;
            emite(x, y, (x * x + y) * EscalaZ1, c);
          }
        break;
      }
      case 2: {                                            // z = 3x - 2y + 5, x[50,100], y[30,80]
        const nu = Math.ceil(50 / (passo / 3.17)), nv = Math.ceil(50 / (passo / 2.25));
        for (let i = 0; i <= nu; i++)
          for (let j = 0; j <= nv; j++) {
            const x = 50 + 50 * i / nu, y = 30 + 50 * j / nv;
            emite(x, y, 3 * x - 2 * y + 5, c);
          }
        break;
      }
      case 3: {                                            // cone
        const nu = Math.ceil(50 / (passo / 1.42));
        for (let i = 0; i <= nu; i++) {
          const t = 50 * i / nu, nb = Math.ceil(2 * Math.PI * t / passo) + 1;
          for (let j = 0; j < nb; j++) {
            const a = 2 * Math.PI * j / nb;
            emite(30 + Math.cos(a) * t, 50 + Math.sin(a) * t, 10 + t, c);
          }
        }
        break;
      }
      case 4: {                                            // esfera r=30 centro (100,50,20)
        const nu = Math.ceil(2 * Math.PI * 30 / passo);
        for (let i = 0; i <= nu; i++) {
          const a = 2 * Math.PI * i / nu, nb = Math.ceil(2 * Math.PI * 30 * Math.abs(Math.cos(a)) / passo) + 1;
          for (let j = 0; j < nb; j++) {
            const b = 2 * Math.PI * j / nb;
            emite(100 + 30 * Math.cos(a) * Math.cos(b), 50 + 30 * Math.cos(a) * Math.sin(b), 20 + 30 * Math.sin(a), c);
          }
        }
        break;
      }
      case 5: {                                            // cubo de lado 40 na origem
        const nu = Math.ceil(40 / passo), du = 40 / nu;
        const face = (eixo, valor) => {
          for (let p = 0; p <= nu; p++)
            for (let q = 0; q <= nu; q++) {
              const u = -20 + p * du, v = -20 + q * du;
              if (eixo === 0) emite(valor, u, v, c); else if (eixo === 1) emite(u, valor, v, c); else emite(u, v, valor, c);
            }
        };
        for (let e = 0; e < 3; e++) { face(e, -20); face(e, 20); }
        break;
      }
    }
  }

  // maior distancia a origem dos objetos: invariante a rotacao, define a escala que sempre cabe
  function raioMaximo(usa = [true, true, true, true, true]) {
    let r2 = 0;
    for (let n = 1; n <= NUM_OBJETOS; n++)
      if (usa[n - 1]) geraObjeto(n, 2, (x, y, z) => { r2 = Math.max(r2, x * x + y * y + z * z); });
    return Math.sqrt(r2);
  }

  return {
    arred, roundP, rgbParaCor, corParaRGB, rgbParaHLS, hlsParaRGB,
    retaEquacaoGeral, retaParametrica, retaBresenham,
    plota8, circEquacao, circParametrica, circRotacoes, circBresenham, circBresenham1,
    matIdentidade, matMul, matEscalaLocal, matEscalaGlobal, matTranslacao, matRot, matRotCentro,
    aplicaPonto, aplicaLista, centroMedio, janelaPorta,
    cohenSutherland, liangBarsky,
    boundingBox, inverteAresta, preencheInversao, preencheScanline, floodFill,
    ZBuffer, NUM_OBJETOS, geraObjeto, raioMaximo,
  };
})();
if (typeof module !== 'undefined') module.exports = CG;

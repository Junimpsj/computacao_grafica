// Uso: node teste.js  (confere o algo.js contra os mesmos casos de testes/TestesCG.lpr)
const CG = require('./js/algo.js');
const assert = require('assert');
const pix = (f, ...a) => { const l = []; f(...a, 0, (x, y) => l.push(x + ',' + y)); return l; };

// HSL: vermelho puro -> H0 L120 S240 e volta
assert.deepStrictEqual(CG.rgbParaHLS(255, 0, 0), [0, 120, 240]);
assert.deepStrictEqual(CG.hlsParaRGB(0, 120, 240), [255, 0, 0]);

// Bresenham: 8 direcoes, sem pixel repetido, max(|dx|,|dy|)+1 pixels
for (const [x, y] of [[100, 0], [100, 40], [40, 100], [0, 100], [-40, 100], [-100, 40], [-100, -40], [40, -100]]) {
  const l = pix(CG.retaBresenham, 0, 0, x, y);
  assert.strictEqual(l.length, Math.max(Math.abs(x), Math.abs(y)) + 1);
  assert.strictEqual(new Set(l).size, l.length);
}
// ponto unico: 1 pixel (o Pascal plota 2x e divide 0/0)
assert.strictEqual(pix(CG.retaParametrica, 5, 5, 5, 5).length, 1);

// Clipping: janela x[20,80] y[10,60], reta (30,5)-(100,70) -> (35.38,10)-(80,51.43)
for (const f of [CG.liangBarsky, CG.cohenSutherland]) {
  const r = f(20, 10, 80, 60, 30, 5, 100, 70);
  assert.ok(Math.abs(r[0] - 35.38) < 0.01 && r[1] === 10 && r[2] === 80 && Math.abs(r[3] - 51.43) < 0.01);
}
assert.strictEqual(CG.liangBarsky(20, 10, 80, 60, 0, 0, 10, 5), null);

// Flood fill no losango: vizinhanca 4 contem (145), 8 vaza (732)
const [GW, GH, bd, bg, pr] = [32, 24, 0, 0xFFFFFF, 0xFF];
const mk = () => Array.from({ length: GW * GH }, (_, i) => (Math.abs(i % GW - 16) + Math.abs(Math.floor(i / GW) - 12) === 9 ? bd : bg));
for (const [oito, esperado] of [[false, 145], [true, 732]]) {
  const g = mk(); CG.floodFill(g, GW, GH, 16, 12, bd, pr, oito);
  assert.strictEqual(g.filter(c => c === pr).length, esperado);
}

// Scanline == inversao em poligono concavo
const poly = [[10, 10], [90, 10], [90, 90], [60, 90], [60, 40], [40, 40], [40, 90], [10, 90]].map(([x, y]) => ({ x, y }));
const A = new Array(100 * 100).fill(bg), B = A.slice();
CG.preencheInversao(A, 100, 100, poly, bg, pr);
CG.preencheScanline(B, 100, 100, poly, pr);
assert.deepStrictEqual(A, B);

// Matrizes: rotZ 90 de (1,0,0) -> (0,1,0); escala global 4 de (1,1,1) -> 0.25
const p = CG.aplicaPonto({ x: 1, y: 0, z: 0 }, CG.matRot('Z', 90));
assert.ok(Math.abs(p.x) < 1e-9 && Math.abs(p.y - 1) < 1e-9);
assert.strictEqual(CG.aplicaPonto({ x: 1, y: 1, z: 1 }, CG.matEscalaGlobal(4)).x, 0.25);

// Z-buffer: menor z vence
const zb = new CG.ZBuffer(4, 4, 0);
zb.ponto(1, 1, 5, 7); zb.ponto(1, 1, 9, 8); zb.ponto(1, 1, 2, 9);
assert.strictEqual(zb.cor[5], 9);

console.log('webVersion: todos os testes passaram');

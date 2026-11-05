unit uPreenchimento;
{ Preenchimento de poligonos (Aula 16). Unit pura, sem LCL: trabalha sobre um
  buffer de pixels (TBufCores, largura W x altura H, linha a linha). }
{$mode objfpc}{$H+}

interface

uses
  Math, uCores, uLinhas;

type
  TPontoI = record x, y: Integer; end;
  TPoligono = array of TPontoI;

procedure BoundingBox(const Poly: TPoligono; out xmin, ymin, xmax, ymax: Integer);

{ Inversao de cores (edge fill), UMA aresta: para cada linha de varredura entre
  ymin e ymax da aresta (intervalo semiaberto [ymin, ymax) para tratar os
  vertices), acha o x da interseção e inverte todos os pixels dali ate xmax da
  bounding box. Inverter = alternar entre corFundo e corPreench. }
procedure InverteAresta(var B: TBufCores; W, H: Integer; x1, y1, x2, y2, xmaxBB: Integer;
  corFundo, corPreench: TColor);

{ todas as arestas do poligono (fechado) de uma vez }
procedure PreencheInversao(var B: TBufCores; W, H: Integer; const Poly: TPoligono;
  corFundo, corPreench: TColor);

{ Scanline com lista ordenada de interseções (Aula 16, opcional): para cada linha
  de varredura monta a lista ORDENADA dos x das arestas que a cruzam (intervalo
  semiaberto) e pinta entre os pares (1o-2o, 3o-4o, ...). Mesmo resultado da inversao. }
procedure PreencheScanline(var B: TBufCores; W, H: Integer; const Poly: TPoligono;
  corPreench: TColor);

{ Flood fill (seed fill) com pilha explicita; vizinhanca 4 ou 8.
  Pinta enquanto o pixel nao for borda e nao tiver a cor de preenchimento. }
procedure FloodFill(var B: TBufCores; W, H, sx, sy: Integer; corBorda, corPreench: TColor;
  oito: Boolean);

implementation

procedure BoundingBox(const Poly: TPoligono; out xmin, ymin, xmax, ymax: Integer);
var
  i: Integer;
begin
  xmin := Poly[0].x; xmax := xmin; ymin := Poly[0].y; ymax := ymin;
  for i := 1 to High(Poly) do
  begin
    if Poly[i].x < xmin then xmin := Poly[i].x;
    if Poly[i].x > xmax then xmax := Poly[i].x;
    if Poly[i].y < ymin then ymin := Poly[i].y;
    if Poly[i].y > ymax then ymax := Poly[i].y;
  end;
end;

procedure InverteAresta(var B: TBufCores; W, H: Integer; x1, y1, x2, y2, xmaxBB: Integer;
  corFundo, corPreench: TColor);
var
  t, y, x, xi: Integer;
  xf: Double;
begin
  if y1 = y2 then Exit;                      // aresta horizontal: nao entra
  if y1 > y2 then
  begin
    t := x1; x1 := x2; x2 := t;
    t := y1; y1 := y2; y2 := t;
  end;
  for y := y1 to y2 - 1 do                   // [ymin, ymax): o vertice de cima conta, o de baixo nao
  begin
    if (y < 0) or (y >= H) then Continue;
    xf := x1 + (y - y1) * (x2 - x1) / (y2 - y1);   // x da interseção com a linha y
    xi := Arred(xf);
    for x := Max(xi, 0) to Min(xmaxBB, W - 1) do   // inverte tudo a direita ate a bbox
      if B[y * W + x] = corPreench then B[y * W + x] := corFundo
      else B[y * W + x] := corPreench;
  end;
end;

procedure PreencheInversao(var B: TBufCores; W, H: Integer; const Poly: TPoligono;
  corFundo, corPreench: TColor);
var
  i, j, xmin, ymin, xmax, ymax: Integer;
begin
  if Length(Poly) < 3 then Exit;
  BoundingBox(Poly, xmin, ymin, xmax, ymax);
  for i := 0 to High(Poly) do
  begin
    j := (i + 1) mod Length(Poly);
    InverteAresta(B, W, H, Poly[i].x, Poly[i].y, Poly[j].x, Poly[j].y, xmax,
                  corFundo, corPreench);
  end;
end;

procedure PreencheScanline(var B: TBufCores; W, H: Integer; const Poly: TPoligono;
  corPreench: TColor);
var
  n, i, j, k, y, x, t, y1, y2, x1, x2, xi, p, xmin, ymin, xmax, ymax: Integer;
  xs: array of Integer;     // lista ordenada de interseções da linha atual
begin
  n := Length(Poly);
  if n < 3 then Exit;
  SetLength(xs, n);
  BoundingBox(Poly, xmin, ymin, xmax, ymax);
  for y := ymin to ymax - 1 do
  begin
    if (y < 0) or (y >= H) then Continue;
    k := 0;
    for i := 0 to n - 1 do
    begin
      j := (i + 1) mod n;
      x1 := Poly[i].x; y1 := Poly[i].y; x2 := Poly[j].x; y2 := Poly[j].y;
      if y1 = y2 then Continue;                         // horizontal: ignora
      if y1 > y2 then
      begin
        t := x1; x1 := x2; x2 := t;
        t := y1; y1 := y2; y2 := t;
      end;
      if (y >= y1) and (y < y2) then                    // [ymin, ymax)
      begin
        xi := Arred(x1 + (y - y1) * (x2 - x1) / (y2 - y1));
        p := k;                                         // insercao ordenada
        while (p > 0) and (xs[p - 1] > xi) do begin xs[p] := xs[p - 1]; Dec(p); end;
        xs[p] := xi;
        Inc(k);
      end;
    end;
    p := 0;
    while p + 1 < k do                                  // pinta entre pares
    begin
      for x := Max(xs[p], 0) to Min(xs[p + 1] - 1, W - 1) do
        B[y * W + x] := corPreench;
      Inc(p, 2);
    end;
  end;
end;

{ Versao recursiva do slide (so para referencia: estoura a pilha em areas grandes):

  procedure Preenche(x, y: Integer);
  begin
    if (cor(x,y) <> borda) and (cor(x,y) <> preench) then
    begin
      pinta(x, y, preench);
      Preenche(x+1, y); Preenche(x-1, y); Preenche(x, y+1); Preenche(x, y-1);
      // (vizinhanca 8: mais as 4 diagonais)
    end;
  end;

  Abaixo: a mesma ideia com uma pilha EXPLICITA (array de posicoes). }
procedure FloodFill(var B: TBufCores; W, H, sx, sy: Integer; corBorda, corPreench: TColor;
  oito: Boolean);
var
  Pilha: array of Integer;
  topo, x, y, dx, dy, nx, ny, i: Integer;

  procedure Empilha(p: Integer);
  begin
    if topo >= Length(Pilha) then SetLength(Pilha, Length(Pilha) * 2 + 64);
    Pilha[topo] := p;
    Inc(topo);
  end;

begin
  if (sx < 0) or (sy < 0) or (sx >= W) or (sy >= H) then Exit;
  topo := 0;
  Empilha(sy * W + sx);
  while topo > 0 do
  begin
    Dec(topo);
    i := Pilha[topo];
    x := i mod W;
    y := i div W;
    if (B[i] = corBorda) or (B[i] = corPreench) then Continue;
    B[i] := corPreench;
    for dy := -1 to 1 do
      for dx := -1 to 1 do
      begin
        if (dx = 0) and (dy = 0) then Continue;
        if (not oito) and (dx <> 0) and (dy <> 0) then Continue;   // 4: sem diagonais
        nx := x + dx; ny := y + dy;
        if (nx >= 0) and (ny >= 0) and (nx < W) and (ny < H) then
          if (B[ny * W + nx] <> corBorda) and (B[ny * W + nx] <> corPreench) then
            Empilha(ny * W + nx);
      end;
  end;
end;

end.

program TestesCG;
{ Testes dos algoritmos (console, sem LCL). Rodar: testes/rodar.sh }
{$mode objfpc}{$H+}
uses SysUtils, uCores, uLinhas, uCirculos, uMatriz, uClipping, uPreenchimento, uZBuffer;

var
  Falhas, Total: Integer;

procedure Confere(ok: Boolean; const msg: string);
begin
  Inc(Total);
  if ok then WriteLn('  ok   ', msg)
  else begin Inc(Falhas); WriteLn('  FALHA ', msg); end;
end;

type
  TGrava = class
    X, Y: array of Integer;
    procedure Plota(px, py: Integer; cor: TColor);
  end;

procedure TGrava.Plota(px, py: Integer; cor: TColor);
begin
  SetLength(X, Length(X) + 1); SetLength(Y, Length(Y) + 1);
  X[High(X)] := px; Y[High(Y)] := py;
end;

procedure TestaBresenhaReta;
const
  Alvos: array[0..15, 0..1] of Integer = (
    (10, 0), (10, 3), (10, 10), (3, 10), (0, 10), (-3, 10), (-10, 10), (-10, 3),
    (-10, 0), (-10, -3), (-10, -10), (-3, -10), (0, -10), (3, -10), (10, -10), (10, -3));
var
  A, B: TGrava;
  i, k, mx: Integer;
  ok: Boolean;
begin
  WriteLn('Bresenham reta');
  A := TGrava.Create;
  RetaBresenham(0, 0, 5, 2, 0, @A.Plota);
  ok := (Length(A.X) = 6);
  if ok then
    ok := (A.X[0]=0) and (A.Y[0]=0) and (A.X[1]=1) and (A.Y[1]=0) and (A.X[2]=2) and (A.Y[2]=1)
      and (A.X[3]=3) and (A.Y[3]=1) and (A.X[4]=4) and (A.Y[4]=2) and (A.X[5]=5) and (A.Y[5]=2);
  Confere(ok, '(0,0)-(5,2) = (0,0)(1,0)(2,1)(3,1)(4,2)(5,2)');
  A.Free;

  ok := True; mx := 0;
  for k := 0 to 15 do
  begin
    A := TGrava.Create; B := TGrava.Create;
    RetaBresenham(0, 0, Alvos[k, 0], Alvos[k, 1], 0, @A.Plota);
    RetaEquacaoGeral(0, 0, Alvos[k, 0], Alvos[k, 1], 0, @B.Plota);
    if Length(A.X) <> Length(B.X) then ok := False
    else
      for i := 0 to High(A.X) do
      begin
        if Abs(A.X[i] - B.X[i]) > mx then mx := Abs(A.X[i] - B.X[i]);
        if Abs(A.Y[i] - B.Y[i]) > mx then mx := Abs(A.Y[i] - B.Y[i]);
      end;
    A.Free; B.Free;
  end;
  Confere(ok and (mx <= 1), '16 direcoes (8 octantes) vs float: diferenca maxima = ' + IntToStr(mx));
end;

procedure TestaBresenhamCirculo;
const
  R = 10;
var
  A, B: TGrava;
  i, j, d: Integer;
  ok, dup, igual: Boolean;
begin
  WriteLn('Bresenham circunferencia');
  A := TGrava.Create;
  CircBresenham(0, 0, R, 0, @A.Plota);
  ok := True;
  for i := 0 to High(A.X) do
  begin
    d := A.X[i] * A.X[i] + A.Y[i] * A.Y[i] - R * R;
    if Abs(d) > R then ok := False;
  end;
  Confere(ok, 'R=10: todos com |x2+y2-R2| <= R (' + IntToStr(Length(A.X)) + ' pixels)');
  dup := False;
  for i := 0 to High(A.X) do
    for j := i + 1 to High(A.X) do
      if (A.X[i] = A.X[j]) and (A.Y[i] = A.Y[j]) then dup := True;
  Confere(not dup, 'nenhum pixel repetido');
  B := TGrava.Create;
  CircBresenham1(0, 0, R, 0, @B.Plota);
  igual := Length(A.X) = Length(B.X);
  if igual then
    for i := 0 to High(A.X) do
      if (A.X[i] <> B.X[i]) or (A.Y[i] <> B.Y[i]) then igual := False;
  Confere(igual, '2a ordem == 1a ordem (mesmos pixels, mesma ordem)');
  A.Free; B.Free;
end;

function Perto(a, b: Double): Boolean;
begin
  Result := Abs(a - b) < 1e-9;
end;

procedure TestaMatrizes;
var
  p, q: TPonto;
  c: TPonto;
begin
  WriteLn('Matrizes');
  p.x := 1; p.y := 0; p.z := 0;
  q := AplicaPonto(p, MatRotZ(90));
  Confere(Perto(q.x, 0) and Perto(q.y, 1) and Perto(q.z, 0), 'rotZ 90 de (1,0,0) -> (0,1,0)');
  p.x := 0; p.y := 0; p.z := 0;
  q := AplicaPonto(p, MatTranslacao(2, 5, -4));
  Confere(Perto(q.x, 2) and Perto(q.y, 5) and Perto(q.z, -4), 'translacao (2,5,-4) de (0,0,0)');
  p.x := 1; p.y := 1; p.z := 1;
  q := AplicaPonto(p, MatEscalaGlobal(4));
  Confere(Perto(q.x, 0.25) and Perto(q.y, 0.25) and Perto(q.z, 0.25), 'escala global s=4 de (1,1,1) -> 0.25');
  // rotacao em torno do centro deixa o proprio centro fixo
  c.x := 50; c.y := 75; c.z := 50;
  q := AplicaPonto(c, MatRotCentro('Y', 37, c.x, c.y, c.z));
  Confere(Perto(q.x, 50) and Perto(q.y, 75) and Perto(q.z, 50), 'rotacao em torno do centro mantem o centro');
  // composicao: translada e depois escala local
  p.x := 1; p.y := 2; p.z := 3;
  q := AplicaPonto(p, MatMul(MatTranslacao(1, 1, 1), MatEscalaLocal(2, 2, 2)));
  Confere(Perto(q.x, 4) and Perto(q.y, 6) and Perto(q.z, 8), 'composicao T . S aplica T primeiro');
  Confere(Perto(JanelaPorta(5, 0, 10, 100, 200), 150), 'janela/porta: 5 em [0,10] -> 150 em [100,200]');
end;

procedure TestaClipping;
var
  a, b, c, d: Double;
  ok: Boolean;
begin
  WriteLn('Clipping (janela x[20,80] y[10,60], reta (30,5)-(100,70))');
  a := 30; b := 5; c := 100; d := 70;
  ok := LiangBarsky(20, 10, 80, 60, a, b, c, d);
  Confere(ok and (Abs(a - 35.38) < 0.01) and (Abs(b - 10) < 0.01) and
          (Abs(c - 80) < 0.01) and (Abs(d - 51.42) < 0.01),
          Format('Liang-Barsky -> (%.2f,%.2f)-(%.2f,%.2f)', [a, b, c, d]));
  a := 30; b := 5; c := 100; d := 70;
  ok := CohenSutherland(20, 10, 80, 60, a, b, c, d);
  Confere(ok and (Abs(a - 35.38) < 0.01) and (Abs(b - 10) < 0.01) and
          (Abs(c - 80) < 0.01) and (Abs(d - 51.42) < 0.01),
          Format('Cohen-Sutherland -> (%.2f,%.2f)-(%.2f,%.2f)', [a, b, c, d]));
  a := 0; b := 0; c := 10; d := 5;
  Confere(not CohenSutherland(20, 10, 80, 60, a, b, c, d) and
          not LiangBarsky(20, 10, 80, 60, a, b, c, d), 'rejeicao trivial nos dois');
  a := 50; b := 0; c := 50; d := 100;     // vertical atravessando
  ok := CohenSutherland(20, 10, 80, 60, a, b, c, d);
  Confere(ok and (a = 50) and (b = 10) and (c = 50) and (d = 60), 'vertical (Cohen-Sutherland)');
  a := 0; b := 30; c := 100; d := 30;     // horizontal atravessando
  ok := LiangBarsky(20, 10, 80, 60, a, b, c, d);
  Confere(ok and (a = 20) and (b = 30) and (c = 80) and (d = 30), 'horizontal (Liang-Barsky)');
end;

procedure TestaPreenchimento;
const
  GW = 32; GH = 24;
var
  G: TBufCores;
  x, y, n4, n8, borda: Integer;
  Poly: TPoligono;
  B: TBufCores;
  dentro, fora: Integer;

  function Conta(const Buf: TBufCores; c: TColor): Integer;
  var k: Integer;
  begin
    Result := 0;
    for k := 0 to High(Buf) do if Buf[k] = c then Inc(Result);
  end;

  procedure MontaGrade;
  var gx, gy: Integer;
  begin
    SetLength(G, GW * GH);
    for gy := 0 to GH - 1 do
      for gx := 0 to GW - 1 do
        if Abs(gx - 16) + Abs(gy - 12) = 9 then G[gy * GW + gx] := 1   // losango 8-conexo
        else G[gy * GW + gx] := 0;
  end;

begin
  WriteLn('Preenchimento');
  MontaGrade;
  FloodFill(G, GW, GH, 16, 12, 1, 2, False);
  n4 := Conta(G, 2);
  MontaGrade;
  FloodFill(G, GW, GH, 16, 12, 1, 2, True);
  n8 := Conta(G, 2);
  borda := 4 * 9;
  Confere(n4 = 145, 'flood fill vizinhanca 4 contem: ' + IntToStr(n4) + ' pixels (esperado 145)');
  Confere(n8 = GW * GH - borda, 'flood fill vizinhanca 8 vaza: ' + IntToStr(n8) + ' pixels (esperado ' + IntToStr(GW * GH - borda) + ')');

  // inversao: quadrado (10,10)-(20,20) deve pintar exatamente os x em [10,20) e y em [10,20)
  SetLength(Poly, 4);
  Poly[0].x := 10; Poly[0].y := 10; Poly[1].x := 20; Poly[1].y := 10;
  Poly[2].x := 20; Poly[2].y := 20; Poly[3].x := 10; Poly[3].y := 20;
  SetLength(B, 40 * 40);
  for x := 0 to High(B) do B[x] := 0;
  PreencheInversao(B, 40, 40, Poly, 0, 7);
  dentro := 0; fora := 0;
  for y := 0 to 39 do
    for x := 0 to 39 do
      if B[y * 40 + x] = 7 then
        if (x >= 10) and (x < 20) and (y >= 10) and (y < 20) then Inc(dentro) else Inc(fora);
  Confere((dentro = 100) and (fora = 0), Format('inversao: quadrado 10x10 -> %d dentro, %d fora', [dentro, fora]));

  // scanline deve dar exatamente o mesmo resultado da inversao, tambem em poligono concavo
  SetLength(Poly, 7);
  Poly[0].x := 5;  Poly[0].y := 5;   Poly[1].x := 35; Poly[1].y := 8;
  Poly[2].x := 30; Poly[2].y := 20;  Poly[3].x := 20; Poly[3].y := 12;
  Poly[4].x := 12; Poly[4].y := 34;  Poly[5].x := 25; Poly[5].y := 36;
  Poly[6].x := 3;  Poly[6].y := 25;
  SetLength(B, 40 * 40);
  SetLength(G, 40 * 40);
  for x := 0 to High(B) do begin B[x] := 0; G[x] := 0; end;
  PreencheInversao(B, 40, 40, Poly, 0, 7);
  PreencheScanline(G, 40, 40, Poly, 7);
  dentro := 0; fora := 0;
  for x := 0 to High(B) do
  begin
    if B[x] <> G[x] then Inc(fora);
    if G[x] = 7 then Inc(dentro);
  end;
  Confere((fora = 0) and (dentro > 100), Format('scanline == inversao em poligono concavo (%d pixels, %d diferencas)', [dentro, fora]));
end;

type
  TProj = class
    ZB: TZBuffer;
    k: Double;
    procedure Pt(x, y, z: Double; c: TColor);
  end;

procedure TProj.Pt(x, y, z: Double; c: TColor);
begin
  ZB.Ponto(Round(100 + x * k), Round(100 - y * k), z, c);
end;

procedure TestaZBuffer;
var
  zb: TZBuffer;
  P: TProj;
  x, y, preenchidos, esperado: Integer;
begin
  WriteLn('Z-Buffer');
  zb := TZBuffer.Create(10, 10, 0);
  zb.Ponto(5, 5, 10, 1);
  zb.Ponto(5, 5, 3, 2);      // mais perto: vence
  zb.Ponto(5, 5, 7, 3);      // mais longe: ignorado
  Confere(zb.Cor[5 * 10 + 5] = 2, 'menor z vence');
  zb.Free;

  // esfera de raio 30 com k = 2: o disco projetado (raio 60 px) tem de ficar sem buracos
  P := TProj.Create;
  P.ZB := TZBuffer.Create(300, 300, 0);
  P.k := 2;
  GeraObjeto(4, 0.6 / P.k, @P.Pt);
  preenchidos := 0; esperado := 0;
  for y := 0 to 299 do
    for x := 0 to 299 do
    begin
      // so conta pixels bem dentro do disco (centro projetado: (100+100*2? ) ver abaixo)
      if Sqr(x - Round(100 + 100 * P.k)) + Sqr(y - Round(100 - 50 * P.k)) < Sqr(30 * P.k - 2) then
      begin
        Inc(esperado);
        if P.ZB.Cor[y * 300 + x] <> 0 then Inc(preenchidos);
      end;
    end;
  Confere((esperado > 0) and (preenchidos = esperado),
    Format('esfera sem buracos: %d de %d pixels', [preenchidos, esperado]));
end;

procedure TestaHSL;
var
  H, L, S, R, G, B, r0, g0, b0, mx: Integer;
begin
  WriteLn('HSL');
  RGBparaHLS(255, 0, 0, H, L, S);
  Confere((H = 0) and (S = 240) and (L = 120), Format('vermelho -> H%d S%d L%d', [H, S, L]));
  RGBparaHLS(255, 255, 255, H, L, S);
  Confere((S = 0) and (L = 240), Format('branco -> S%d L%d', [S, L]));
  RGBparaHLS(0, 128, 0, H, L, S);
  Confere((H = 80) and (S = 240) and (L = 60), Format('(0,128,0) -> H%d S%d L%d', [H, S, L]));
  // ida e volta: erro <= 1 em cores de teste (0/128/255). Em geral o HSL de 240 niveis perde ate ~2 niveis (limite do algoritmo da MS).
  mx := 0;
  for r0 in [0, 128, 255] do
    for g0 in [0, 128, 255] do
      for b0 in [0, 128, 255] do
      begin
        RGBparaHLS(r0, g0, b0, H, L, S);
        HLSparaRGB(H, L, S, R, G, B);
        if Abs(R - r0) > mx then mx := Abs(R - r0);
        if Abs(G - g0) > mx then mx := Abs(G - g0);
        if Abs(B - b0) > mx then mx := Abs(B - b0);
      end;
  Confere(mx <= 1, 'ida e volta, erro maximo = ' + IntToStr(mx));
end;

begin
  TestaHSL;
  TestaBresenhaReta;
  TestaBresenhamCirculo;
  TestaMatrizes;
  TestaClipping;
  TestaPreenchimento;
  TestaZBuffer;
  WriteLn;
  WriteLn(Total - Falhas, '/', Total, ' testes passaram');
  if Falhas > 0 then Halt(1);
end.

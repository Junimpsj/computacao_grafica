unit uCirculos;
{ Circunferencias pixel a pixel (Aulas 07 e 08). Unit pura, sem LCL. }
{$mode objfpc}{$H+}

interface

uses
  Math, uCores, uLinhas;

{ Aula 07 - metodo 1: y = sqrt(R^2 - x^2) para x = -R..R. Com simetria8=True usa
  so o 1o octante e espelha (opcional do enunciado). }
procedure CircEquacao(xc, yc, R: Integer; cor: TColor; Plot: TPlotProc;
  simetria8: Boolean = False);

{ Aula 07 - metodo 2: parametrica x = r cos a, y = r sen a, a de 0 a 2pi.
  passo em radianos; passo <= 0 usa 1/R (cerca de 1 pixel de arco) }
procedure CircParametrica(xc, yc, R: Integer; cor: TColor; Plot: TPlotProc;
  passo: Double = 0);

{ Aula 07 - metodo 3: rotacoes incrementais de 1 grau (360 passos) }
procedure CircRotacoes(xc, yc, R: Integer; cor: TColor; Plot: TPlotProc);

{ Aula 08 - Bresenham, diferencas de segunda ordem + simetria de 8 }
procedure CircBresenham(xc, yc, R: Integer; cor: TColor; Plot: TPlotProc);

{ Aula 08 - Bresenham, versao de primeira ordem (h += 2x+3 / h += 2(x-y)+5) }
procedure CircBresenham1(xc, yc, R: Integer; cor: TColor; Plot: TPlotProc);

{ plota (x,y) e seus 7 simetricos somados ao centro, sem repetir pixel
  nos eixos (x=0) e na diagonal (x=y) }
procedure Plota8(xc, yc, x, y: Integer; cor: TColor; Plot: TPlotProc);

implementation

procedure Plota8(xc, yc, x, y: Integer; cor: TColor; Plot: TPlotProc);
begin
  // os 8 simetricos; x=0 e x=y geram pontos coincidentes, entao sao pulados
  Plot(xc + x, yc + y, cor);
  if x <> y then Plot(xc + y, yc + x, cor);
  if x <> 0 then Plot(xc - x, yc + y, cor);
  if x <> y then Plot(xc - y, yc + x, cor);
  Plot(xc + x, yc - y, cor);
  if (x <> y) and (x <> 0) then Plot(xc + y, yc - x, cor);
  if x <> 0 then Plot(xc - x, yc - y, cor);
  if (x <> y) and (x <> 0) then Plot(xc - y, yc - x, cor);
end;

procedure CircEquacao(xc, yc, R: Integer; cor: TColor; Plot: TPlotProc;
  simetria8: Boolean);
var
  x, y: Integer;
begin
  if simetria8 then
  begin
    // so de x = 0 ate R/raiz(2): o resto vem por simetria
    for x := 0 to Arred(R / Sqrt(2)) do
      Plota8(xc, yc, x, Arred(Sqrt(R * R - x * x)), cor, Plot);
  end
  else
    for x := -R to R do
    begin
      y := Arred(Sqrt(R * R - x * x));
      Plot(xc + x, yc + y, cor);          // metade de baixo (tela)
      Plot(xc + x, yc - y, cor);          // metade de cima
    end;
end;

procedure CircParametrica(xc, yc, R: Integer; cor: TColor; Plot: TPlotProc;
  passo: Double);
var
  a: Double;
begin
  if passo <= 0 then
    if R > 0 then passo := 1 / R else passo := 1;
  a := 0;
  while a < 2 * Pi do
  begin
    Plot(xc + Arred(R * Cos(a)), yc + Arred(R * Sin(a)), cor);
    a := a + passo;
  end;
end;

procedure CircRotacoes(xc, yc, R: Integer; cor: TColor; Plot: TPlotProc);
var
  i: Integer;
  x, y, xn, c, s: Double;
begin
  // O slide escreve cos(1)/sen(1), mas a intencao e 1 GRAU = pi/180 radianos
  // (as funcoes trigonometricas do Pascal trabalham em radianos).
  c := Cos(Pi / 180);
  s := Sin(Pi / 180);
  x := R;
  y := 0;
  for i := 1 to 360 do
  begin
    xn := x * c - y * s;      // rotacao do ponto por 1 grau
    y := x * s + y * c;
    x := xn;
    Plot(xc + Arred(x), yc + Arred(y), cor);
  end;
end;

procedure CircBresenham(xc, yc, R: Integer; cor: TColor; Plot: TPlotProc);
var
  x, y, h, dE, dSE: Integer;
begin
  x := 0;
  y := R;
  h := 1 - R;
  dE := 3;
  dSE := -2 * R + 5;
  Plota8(xc, yc, x, y, cor, Plot);
  while x < y do
  begin
    if h < 0 then
    begin
      // escolhe E: so x avanca
      h := h + dE;
      dE := dE + 2;
      dSE := dSE + 2;
    end
    else
    begin
      // escolhe SE: x avanca e y diminui
      h := h + dSE;
      dE := dE + 2;
      dSE := dSE + 4;
      Dec(y);
    end;
    Inc(x);
    // se um passo SE cruzar a diagonal (x > y) o ponto e so o espelho de um
    // ja plotado: nao plota de novo
    if x <= y then Plota8(xc, yc, x, y, cor, Plot);
  end;
end;

procedure CircBresenham1(xc, yc, R: Integer; cor: TColor; Plot: TPlotProc);
var
  x, y, h: Integer;
begin
  x := 0;
  y := R;
  h := 1 - R;
  Plota8(xc, yc, x, y, cor, Plot);
  while x < y do
  begin
    if h < 0 then
      h := h + 2 * x + 3                // E
    else
    begin
      h := h + 2 * (x - y) + 5;         // SE
      Dec(y);
    end;
    Inc(x);
    if x <= y then Plota8(xc, yc, x, y, cor, Plot);
  end;
end;

end.

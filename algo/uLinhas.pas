unit uLinhas;
{ Retas pixel a pixel (Aulas 05, 05A e 06). Unit pura, sem LCL:
  recebe o procedimento de plotagem. Coordenadas de tela (y cresce para baixo). }
{$mode objfpc}{$H+}

interface

uses
  Math, uCores;

{ Aula 05 - metodo A: equacao geral y = m(x-x1)+y1 (floats; arredonda so ao plotar) }
procedure RetaEquacaoGeral(x1, y1, x2, y2: Integer; cor: TColor; Plot: TPlotProc);

{ Aula 05A - metodo B: parametrica x = x1+(x2-x1)t, y = y1+(y2-y1)t, t em [0,1].
  passo <= 0 usa o passo automatico 1/max(|dx|,|dy|); senao passo fixo (ex.: 0.01) }
procedure RetaParametrica(x1, y1, x2, y2: Integer; cor: TColor; Plot: TPlotProc;
  passo: Double = 0);

{ Aula 06 - Bresenham (so inteiros) em todos os octantes }
procedure RetaBresenham(x1, y1, x2, y2: Integer; cor: TColor; Plot: TPlotProc);

{ arredondamento "para o mais proximo, .5 sobe" (Round do FPC e bancario) }
function Arred(v: Double): Integer;

implementation

function Arred(v: Double): Integer;
begin
  Result := Floor(v + 0.5);
end;

procedure RetaEquacaoGeral(x1, y1, x2, y2: Integer; cor: TColor; Plot: TPlotProc);
var
  dx, dy, x, y, inc: Integer;
  m: Double;
begin
  dx := x2 - x1;
  dy := y2 - y1;
  if (dx = 0) and (dy = 0) then
    Plot(x1, y1, cor)
  else if dx = 0 then
  begin
    // reta vertical: tratada a parte (m seria infinito)
    inc := Sign(dy);
    y := y1;
    while y <> y2 + inc do begin Plot(x1, y, cor); y := y + inc; end;
  end
  else
  begin
    m := dy / dx;
    if Abs(dx) >= Abs(dy) then
    begin
      // varia x de 1 em 1 e calcula y = m(x-x1)+y1
      inc := Sign(dx);
      x := x1;
      while x <> x2 + inc do
      begin
        Plot(x, Arred(m * (x - x1) + y1), cor);
        x := x + inc;
      end;
    end
    else
    begin
      // |dy| > |dx|: varia y de 1 em 1 e calcula x = (y-y1)/m + x1
      inc := Sign(dy);
      y := y1;
      while y <> y2 + inc do
      begin
        Plot(Arred((y - y1) / m + x1), y, cor);
        y := y + inc;
      end;
    end;
  end;
end;

procedure RetaParametrica(x1, y1, x2, y2: Integer; cor: TColor; Plot: TPlotProc;
  passo: Double);
var
  n, i: Integer;
  t: Double;
begin
  n := Max(Abs(x2 - x1), Abs(y2 - y1));
  if passo <= 0 then
  begin
    // passo automatico 1/n: n+1 pontos, sem buracos (i/n evita erro acumulado)
    if n = 0 then Plot(x1, y1, cor);
    for i := 0 to n do
    begin
      t := i / n;
      Plot(Arred(x1 + (x2 - x1) * t), Arred(y1 + (y2 - y1) * t), cor);
    end;
  end
  else
  begin
    // passo fixo: se for grande demais para o comprimento, aparecem buracos
    i := 0;
    t := 0;
    while t <= 1 + 1e-9 do
    begin
      Plot(Arred(x1 + (x2 - x1) * t), Arred(y1 + (y2 - y1) * t), cor);
      Inc(i);
      t := i * passo;
    end;
  end;
end;

{ Bresenham.  Correspondencia com o slide (1o octante: dx>=dy>=0):
    d   = 2dy - dx          (variavel de decisao inicial)
    dE  = 2dy               (soma a d quando escolhe E:  x++)
    dNE = 2(dy - dx)        (soma a d quando escolhe NE: x++, y++)
    d < 0 -> E, senao -> NE
  Para os outros octantes: sx/sy = +-1 dao o sentido, e quando |dy| > |dx|
  trocamos os papeis de x e y (o "eixo rapido" passa a ser y). }
procedure RetaBresenham(x1, y1, x2, y2: Integer; cor: TColor; Plot: TPlotProc);
var
  dx, dy, sx, sy, d, dE, dNE, x, y, i: Integer;
  trocou: Boolean;
begin
  dx := Abs(x2 - x1);
  dy := Abs(y2 - y1);
  sx := Sign(x2 - x1); if sx = 0 then sx := 1;
  sy := Sign(y2 - y1); if sy = 0 then sy := 1;

  trocou := dy > dx;
  if trocou then begin i := dx; dx := dy; dy := i; end;   // eixo rapido = dx

  d := 2 * dy - dx;
  dE := 2 * dy;
  dNE := 2 * (dy - dx);

  x := x1;
  y := y1;
  for i := 0 to dx do          // dx+1 pixels
  begin
    Plot(x, y, cor);
    if d < 0 then
    begin
      d := d + dE;                         // escolhe E: so avanca no eixo rapido
      if trocou then y := y + sy else x := x + sx;
    end
    else
    begin
      d := d + dNE;                        // escolhe NE: avanca nos dois eixos
      x := x + sx;
      y := y + sy;
    end;
  end;
end;

end.

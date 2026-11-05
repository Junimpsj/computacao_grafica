unit uClipping;
{ Recorte de retas (Aulas 15a/15c Cohen-Sutherland, 15b Liang-Barsky).
  Unit pura, sem LCL.
  Convencao: coordenadas "matematicas" (y cresce para cima), janela com
  xmin<xmax e ymin<ymax. "Acima" = y > ymax, "abaixo" = y < ymin.
  Na tela y cresce para baixo; a interface converte ys -> H-1-ys antes de
  chamar e converte de volta depois (janela/porta de visao). }
{$mode objfpc}{$H+}

interface

const
  ACIMA = 1;      // bit 1
  ABAIXO = 2;     // bit 2
  DIREITA = 4;    // bit 3
  ESQUERDA = 8;   // bit 4

function CodigoRegiao(x, y, xmin, ymin, xmax, ymax: Double): Integer;

{ Cohen-Sutherland. Devolve True se sobrou parte visivel; x1..y2 viram a parte visivel }
function CohenSutherland(xmin, ymin, xmax, ymax: Double;
  var x1, y1, x2, y2: Double): Boolean;

{ Liang-Barsky (Aula 15b), mesma interface }
function LiangBarsky(xmin, ymin, xmax, ymax: Double;
  var x1, y1, x2, y2: Double): Boolean;

implementation

function CodigoRegiao(x, y, xmin, ymin, xmax, ymax: Double): Integer;
begin
  Result := 0;
  if y > ymax then Result := Result or ACIMA
  else if y < ymin then Result := Result or ABAIXO;
  if x > xmax then Result := Result or DIREITA
  else if x < xmin then Result := Result or ESQUERDA;
end;

function CohenSutherland(xmin, ymin, xmax, ymax: Double;
  var x1, y1, x2, y2: Double): Boolean;
var
  cod1, cod2, cod: Integer;
  x, y, m: Double;
begin
  Result := False;
  while True do
  begin
    cod1 := CodigoRegiao(x1, y1, xmin, ymin, xmax, ymax);
    cod2 := CodigoRegiao(x2, y2, xmin, ymin, xmax, ymax);
    if (cod1 = 0) and (cod2 = 0) then begin Result := True; Exit; end;  // aceitacao trivial
    if (cod1 and cod2) <> 0 then Exit;                                  // rejeicao trivial

    // escolhe um extremo fora da janela e o move para a borda
    if cod1 <> 0 then cod := cod1 else cod := cod2;
    if x2 <> x1 then m := (y2 - y1) / (x2 - x1) else m := 0;   // m so e usado se nao for vertical

    if (cod and ACIMA) <> 0 then
    begin
      y := ymax;
      if x2 = x1 then x := x1 else x := (y - y1) / m + x1;     // topo/base: x = (Y-y1)/m + x1
    end
    else if (cod and ABAIXO) <> 0 then
    begin
      y := ymin;
      if x2 = x1 then x := x1 else x := (y - y1) / m + x1;
    end
    else if (cod and DIREITA) <> 0 then
    begin
      x := xmax;
      y := m * (x - x1) + y1;                                  // esq/dir: y = m(X-x1)+y1
    end
    else
    begin
      x := xmin;
      y := m * (x - x1) + y1;
    end;

    if cod = cod1 then begin x1 := x; y1 := y; end
    else begin x2 := x; y2 := y; end;
  end;
end;

function LiangBarsky(xmin, ymin, xmax, ymax: Double;
  var x1, y1, x2, y2: Double): Boolean;
var
  dx, dy, u1, u2, r: Double;
  p, q: array[1..4] of Double;
  k: Integer;
  x0, y0: Double;
begin
  Result := False;
  x0 := x1; y0 := y1;
  dx := x2 - x0; dy := y2 - y0;
  p[1] := -dx; q[1] := x0 - xmin;
  p[2] := dx;  q[2] := xmax - x0;
  p[3] := -dy; q[3] := y0 - ymin;
  p[4] := dy;  q[4] := ymax - y0;
  u1 := 0; u2 := 1;
  for k := 1 to 4 do
  begin
    if p[k] = 0 then
    begin
      if q[k] < 0 then Exit;          // paralela a borda e fora dela
    end
    else
    begin
      r := q[k] / p[k];
      if p[k] < 0 then
      begin
        if r > u1 then u1 := r;       // entrando na janela
      end
      else
        if r < u2 then u2 := r;       // saindo da janela
    end;
  end;
  if u1 > u2 then Exit;
  x1 := x0 + u1 * dx; y1 := y0 + u1 * dy;
  x2 := x0 + u2 * dx; y2 := y0 + u2 * dy;
  Result := True;
end;

end.

unit uMatriz;
{ Transformacoes 3D em coordenadas homogeneas (Aulas 11, 12, 12A, 13).
  Convencao dos slides: ponto = vetor LINHA [x y z 1], resultado = [P] . [T].
  Unit pura, sem LCL. }
{$mode objfpc}{$H+}

interface

type
  TMat4 = array[0..3, 0..3] of Double;    // M[linha, coluna]
  TPonto = record x, y, z: Double; end;
  TListaPontos = array of TPonto;

function MatIdentidade: TMat4;
function MatMul(const A, B: TMat4): TMat4;          // A . B (aplica A, depois B)
function MatEscalaLocal(sx, sy, sz: Double): TMat4; // diagonal a, e, i
function MatEscalaGlobal(s: Double): TMat4;         // elemento [4,4] = s
function MatTranslacao(tx, ty, tz: Double): TMat4;  // ultima linha
function MatRotX(graus: Double): TMat4;
function MatRotY(graus: Double): TMat4;
function MatRotZ(graus: Double): TMat4;
function MatRot(eixo: Char; graus: Double): TMat4;  // eixo 'X','Y' ou 'Z'
{ rotacao em torno do centro c: T(-c) . R . T(c) }
function MatRotCentro(eixo: Char; graus, cx, cy, cz: Double): TMat4;

{ [x y z 1] . M, depois divide por w (escala global deixa w <> 1) }
function AplicaPonto(const p: TPonto; const M: TMat4): TPonto;
procedure AplicaLista(var Pts: TListaPontos; const M: TMat4);
function CentroMedio(const Pts: TListaPontos): TPonto;

{ Aula 13 - janela/porta de visao:
  x' = (x - Xmin) * (Umax - Umin) / (Xmax - Xmin) + Umin }
function JanelaPorta(v, vmin, vmax, umin, umax: Double): Double;

implementation

uses
  Math;

function MatIdentidade: TMat4;
var
  i, j: Integer;
begin
  for i := 0 to 3 do
    for j := 0 to 3 do
      if i = j then Result[i, j] := 1 else Result[i, j] := 0;
end;

function MatMul(const A, B: TMat4): TMat4;
var
  i, j, k: Integer;
  soma: Double;
begin
  for i := 0 to 3 do
    for j := 0 to 3 do
    begin
      soma := 0;
      for k := 0 to 3 do soma := soma + A[i, k] * B[k, j];
      Result[i, j] := soma;
    end;
end;

function MatEscalaLocal(sx, sy, sz: Double): TMat4;
begin
  Result := MatIdentidade;
  Result[0, 0] := sx;
  Result[1, 1] := sy;
  Result[2, 2] := sz;
end;

function MatEscalaGlobal(s: Double): TMat4;
begin
  Result := MatIdentidade;
  Result[3, 3] := s;          // w = s; ao dividir por w, x,y,z ficam x/s...
end;

function MatTranslacao(tx, ty, tz: Double): TMat4;
begin
  Result := MatIdentidade;
  Result[3, 0] := tx;
  Result[3, 1] := ty;
  Result[3, 2] := tz;
end;

function MatRotX(graus: Double): TMat4;
var c, s: Double;
begin
  c := Cos(DegToRad(graus)); s := Sin(DegToRad(graus));
  Result := MatIdentidade;
  Result[1, 1] := c;  Result[1, 2] := s;
  Result[2, 1] := -s; Result[2, 2] := c;
end;

function MatRotY(graus: Double): TMat4;
var c, s: Double;
begin
  c := Cos(DegToRad(graus)); s := Sin(DegToRad(graus));
  Result := MatIdentidade;
  Result[0, 0] := c;  Result[0, 2] := -s;
  Result[2, 0] := s;  Result[2, 2] := c;
end;

function MatRotZ(graus: Double): TMat4;
var c, s: Double;
begin
  c := Cos(DegToRad(graus)); s := Sin(DegToRad(graus));
  Result := MatIdentidade;
  Result[0, 0] := c;  Result[0, 1] := s;
  Result[1, 0] := -s; Result[1, 1] := c;
end;

function MatRot(eixo: Char; graus: Double): TMat4;
begin
  case UpCase(eixo) of
    'X': Result := MatRotX(graus);
    'Y': Result := MatRotY(graus);
  else
    Result := MatRotZ(graus);
  end;
end;

function MatRotCentro(eixo: Char; graus, cx, cy, cz: Double): TMat4;
begin
  // composicao da esquerda para a direita (vetor linha): leva c a origem,
  // gira, e traz de volta
  Result := MatMul(MatMul(MatTranslacao(-cx, -cy, -cz), MatRot(eixo, graus)),
                   MatTranslacao(cx, cy, cz));
end;

function AplicaPonto(const p: TPonto; const M: TMat4): TPonto;
var
  w: Double;
begin
  Result.x := p.x * M[0, 0] + p.y * M[1, 0] + p.z * M[2, 0] + M[3, 0];
  Result.y := p.x * M[0, 1] + p.y * M[1, 1] + p.z * M[2, 1] + M[3, 1];
  Result.z := p.x * M[0, 2] + p.y * M[1, 2] + p.z * M[2, 2] + M[3, 2];
  w        := p.x * M[0, 3] + p.y * M[1, 3] + p.z * M[2, 3] + M[3, 3];
  if (w <> 1) and (w <> 0) then
  begin
    Result.x := Result.x / w;
    Result.y := Result.y / w;
    Result.z := Result.z / w;
  end;
end;

procedure AplicaLista(var Pts: TListaPontos; const M: TMat4);
var
  i: Integer;
begin
  for i := 0 to High(Pts) do Pts[i] := AplicaPonto(Pts[i], M);
end;

function CentroMedio(const Pts: TListaPontos): TPonto;
var
  i: Integer;
begin
  Result.x := 0; Result.y := 0; Result.z := 0;
  if Length(Pts) = 0 then Exit;
  for i := 0 to High(Pts) do
  begin
    Result.x := Result.x + Pts[i].x;
    Result.y := Result.y + Pts[i].y;
    Result.z := Result.z + Pts[i].z;
  end;
  Result.x := Result.x / Length(Pts);
  Result.y := Result.y / Length(Pts);
  Result.z := Result.z / Length(Pts);
end;

function JanelaPorta(v, vmin, vmax, umin, umax: Double): Double;
begin
  Result := (v - vmin) * (umax - umin) / (vmax - vmin) + umin;
end;

end.

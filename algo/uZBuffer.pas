unit uZBuffer;
{ Z-Buffer (Aula 17). Unit pura, sem LCL.
  - TZBuffer: guarda, para cada pixel, o menor z visto (menor z = mais proximo,
    como no slide) e a cor correspondente.
  - GeraObjeto: amostra DENSAMENTE as superficies dos 5 objetos do enunciado e
    entrega cada ponto 3D por callback (sem guardar milhoes de pontos). }
{$mode objfpc}{$H+}

interface

uses
  Math, uCores;

type
  TZBuffer = class
  private
    FW, FH: Integer;
    FZ: array of Double;
  public
    Cor: TBufCores;
    constructor Create(W, H: Integer; Fundo: TColor);
    procedure Limpar(Fundo: TColor);
    { grava o ponto se z < zbuffer[x,y] }
    procedure Ponto(x, y: Integer; z: Double; c: TColor);
    property Largura: Integer read FW;
    property Altura: Integer read FH;
  end;

  TPontoProc = procedure(x, y, z: Double; c: TColor) of object;

const
  NUM_OBJETOS = 5;
  { O objeto 1 (z = x^2 + y) chega a z = 940, muito maior que os outros (< 300).
    Como a rotacao mistura z em x e y, esse z ENORME faria o objeto sair da tela.
    Por isso o z do objeto 1 e multiplicado por EscalaZ1 (so ele). }
  EscalaZ1 = 0.1;
  CorObj: array[1..NUM_OBJETOS] of TColor =
    ($FF0000,    // 1 azul
     $0000FF,    // 2 vermelho
     $00FFFF,    // 3 amarelo
     $00C000,    // 4 verde
     $FFFFFF);   // 5 branco

{ passo = distancia 3D maxima entre amostras vizinhas (em unidades do mundo).
  Como a projecao ortogonal nao aumenta distancias, passo <= ~0.7 pixel nao deixa buracos. }
procedure GeraObjeto(n: Integer; passo: Double; Emite: TPontoProc);

{ maior distancia a origem de qualquer ponto dos objetos: invariante a rotacao em
  torno da origem, serve para escolher uma escala que sempre cabe na tela }
function RaioMaximo(const Usa: array of Boolean): Double;

implementation

constructor TZBuffer.Create(W, H: Integer; Fundo: TColor);
begin
  inherited Create;
  FW := W;
  FH := H;
  SetLength(FZ, W * H);
  SetLength(Cor, W * H);
  Limpar(Fundo);
end;

procedure TZBuffer.Limpar(Fundo: TColor);
var
  i: Integer;
begin
  for i := 0 to High(FZ) do
  begin
    FZ[i] := MaxDouble;     // "maior valor possivel"
    Cor[i] := Fundo;
  end;
end;

procedure TZBuffer.Ponto(x, y: Integer; z: Double; c: TColor);
var
  i: Integer;
begin
  if (x < 0) or (y < 0) or (x >= FW) or (y >= FH) then Exit;
  i := y * FW + x;
  if z < FZ[i] then
  begin
    FZ[i] := z;
    Cor[i] := c;
  end;
end;

procedure GeraObjeto(n: Integer; passo: Double; Emite: TPontoProc);
var
  i, j, nu, nv, nb: Integer;
  x, y, z, t, a, b, du, dv, ca: Double;
  c: TColor;

  { as 6 faces do cubo: um eixo fixo em +-20, os outros dois em [-20,20] }
  procedure Face(eixo: Integer; valor: Double);
  var
    p, q: Integer;
    u, v: Double;
  begin
    for p := 0 to nu do
      for q := 0 to nu do
      begin
        u := -20 + p * du;
        v := -20 + q * du;
        case eixo of
          0: Emite(valor, u, v, c);
          1: Emite(u, valor, v, c);
        else
          Emite(u, v, valor, c);
        end;
      end;
  end;

begin
  c := CorObj[n];
  case n of
    1: begin
         // azul: z = x^2 + y, x em [10,30], y em [20,40]
         // inclinacao max em x = 2x*EscalaZ1 = 6 -> passo em x = passo/sqrt(1+36)
         du := passo / 6.1;
         dv := passo / 1.1;
         nu := Ceil(20 / du);
         nv := Ceil(20 / dv);
         for i := 0 to nu do
           for j := 0 to nv do
           begin
             x := 10 + 20 * i / nu;
             y := 20 + 20 * j / nv;
             Emite(x, y, (x * x + y) * EscalaZ1, c);
           end;
       end;
    2: begin
         // vermelho: z = 3x - 2y + 5, x em [50,100], y em [30,80]
         du := passo / 3.17;      // |grad z| em x: sqrt(1+3^2)
         dv := passo / 2.25;      // em y: sqrt(1+2^2)
         nu := Ceil(50 / du);
         nv := Ceil(50 / dv);
         for i := 0 to nu do
           for j := 0 to nv do
           begin
             x := 50 + 50 * i / nu;
             y := 30 + 50 * j / nv;
             Emite(x, y, 3 * x - 2 * y + 5, c);
           end;
       end;
    3: begin
         // amarelo (cone): x = 30 + cos(a) t, y = 50 + sen(a) t, z = 10 + t
         nu := Ceil(50 / (passo / 1.42));        // passos em t (ao longo da geratriz)
         for i := 0 to nu do
         begin
           t := 50 * i / nu;
           nb := Ceil(2 * Pi * t / passo) + 1;   // circulo de raio t
           for j := 0 to nb - 1 do
           begin
             a := 2 * Pi * j / nb;
             Emite(30 + Cos(a) * t, 50 + Sin(a) * t, 10 + t, c);
           end;
         end;
       end;
    4: begin
         // verde (esfera): x = 100 + 30 cos a cos b, y = 50 + 30 cos a sen b, z = 20 + 30 sen a
         nu := Ceil(2 * Pi * 30 / passo);
         for i := 0 to nu do
         begin
           a := 2 * Pi * i / nu;
           ca := Abs(Cos(a));
           nb := Ceil(2 * Pi * 30 * ca / passo) + 1;   // paralelos menores no polo
           for j := 0 to nb - 1 do
           begin
             b := 2 * Pi * j / nb;
             Emite(100 + 30 * Cos(a) * Cos(b), 50 + 30 * Cos(a) * Sin(b),
                   20 + 30 * Sin(a), c);
           end;
         end;
       end;
    5: begin
         // branco: cubo de lado 40 centrado na origem (6 faces)
         nu := Ceil(40 / passo);
         du := 40 / nu;
         Face(0, -20); Face(0, 20);
         Face(1, -20); Face(1, 20);
         Face(2, -20); Face(2, 20);
       end;
  end;
end;

type
  TMedidor = class
    R2: Double;
    procedure Pt(x, y, z: Double; c: TColor);
  end;

procedure TMedidor.Pt(x, y, z: Double; c: TColor);
begin
  if x * x + y * y + z * z > R2 then R2 := x * x + y * y + z * z;
end;

function RaioMaximo(const Usa: array of Boolean): Double;
var
  M: TMedidor;
  n: Integer;
begin
  M := TMedidor.Create;
  try
    for n := 1 to NUM_OBJETOS do
      if (n - 1 > High(Usa)) or Usa[n - 1] then GeraObjeto(n, 2, @M.Pt);
    Result := Sqrt(M.R2);
  finally
    M.Free;
  end;
end;

end.

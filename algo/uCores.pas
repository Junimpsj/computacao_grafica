unit uCores;
{ Aula 03 - Conversao RGB <-> HSL (padrao do Paint do Windows).
  Algoritmo inteiro da Microsoft (KB "Converting Colors Between RGB and HLS"),
  com HLSMAX = 240 e RGBMAX = 255. Unit pura: sem LCL. }
{$mode objfpc}{$H+}

interface

type
  { mesmo formato do TColor da LCL: $00BBGGRR }
  TColor = Longint;
  { procedimento de plotagem recebido pelos algoritmos de traçado }
  TPlotProc = procedure(x, y: Integer; cor: TColor) of object;
  { buffer de pixels (linha a linha) para os algoritmos que precisam ler a imagem }
  TBufCores = array of TColor;

const
  HLSMAX = 240;
  RGBMAX = 255;
  INDEFINIDO = HLSMAX * 2 div 3;   // H = 160 quando a cor e cinza (S = 0)

procedure RGBparaHLS(R, G, B: Integer; out H, L, S: Integer);
procedure HLSparaRGB(H, L, S: Integer; out R, G, B: Integer);
function RGBparaCor(R, G, B: Integer): TColor;
procedure CorParaRGB(cor: TColor; out R, G, B: Integer);

implementation

function RGBparaCor(R, G, B: Integer): TColor;
begin
  Result := R or (G shl 8) or (B shl 16);
end;

procedure CorParaRGB(cor: TColor; out R, G, B: Integer);
begin
  R := cor and $FF;
  G := (cor shr 8) and $FF;
  B := (cor shr 16) and $FF;
end;

procedure RGBparaHLS(R, G, B: Integer; out H, L, S: Integer);
var
  cMax, cMin, Rdelta, Gdelta, Bdelta: Integer;
begin
  cMax := R; if G > cMax then cMax := G; if B > cMax then cMax := B;
  cMin := R; if G < cMin then cMin := G; if B < cMin then cMin := B;

  // Luminosidade: media de max e min, com arredondamento inteiro
  L := ((cMax + cMin) * HLSMAX + RGBMAX) div (2 * RGBMAX);

  if cMax = cMin then
  begin
    // acromatico (cinza): saturacao 0 e matiz indefinido
    S := 0;
    H := INDEFINIDO;
  end
  else
  begin
    // Saturacao: depende de L estar na metade escura ou clara
    if L <= HLSMAX div 2 then
      S := ((cMax - cMin) * HLSMAX + (cMax + cMin) div 2) div (cMax + cMin)
    else
      S := ((cMax - cMin) * HLSMAX + (2 * RGBMAX - cMax - cMin) div 2)
           div (2 * RGBMAX - cMax - cMin);

    // Matiz: distancia de cada canal ao maximo, em sextos do circulo
    Rdelta := ((cMax - R) * (HLSMAX div 6) + (cMax - cMin) div 2) div (cMax - cMin);
    Gdelta := ((cMax - G) * (HLSMAX div 6) + (cMax - cMin) div 2) div (cMax - cMin);
    Bdelta := ((cMax - B) * (HLSMAX div 6) + (cMax - cMin) div 2) div (cMax - cMin);

    if R = cMax then
      H := Bdelta - Gdelta
    else if G = cMax then
      H := HLSMAX div 3 + Rdelta - Bdelta
    else
      H := 2 * HLSMAX div 3 + Gdelta - Rdelta;

    // ajusta para 0..239
    if H < 0 then H := H + HLSMAX;
    if H >= HLSMAX then H := H - HLSMAX;
  end;
end;

{ HueToRGB do artigo da Microsoft: n1 = Magic1, n2 = Magic2 }
function HueToRGB(n1, n2, hue: Integer): Integer;
begin
  if hue < 0 then hue := hue + HLSMAX;
  if hue > HLSMAX then hue := hue - HLSMAX;

  if hue < HLSMAX div 6 then
    Result := n1 + (((n2 - n1) * hue + (HLSMAX div 12)) div (HLSMAX div 6))
  else if hue < HLSMAX div 2 then
    Result := n2
  else if hue < (HLSMAX * 2) div 3 then
    Result := n1 + (((n2 - n1) * (((HLSMAX * 2) div 3) - hue) + (HLSMAX div 12))
                    div (HLSMAX div 6))
  else
    Result := n1;
end;

procedure HLSparaRGB(H, L, S: Integer; out R, G, B: Integer);
var
  Magic1, Magic2: Integer;
begin
  if S = 0 then
  begin
    // cinza: R = G = B = L reescalado de 0..240 para 0..255
    R := (L * RGBMAX) div HLSMAX;
    G := R;
    B := R;
  end
  else
  begin
    if L <= HLSMAX div 2 then
      Magic2 := (L * (HLSMAX + S) + (HLSMAX div 2)) div HLSMAX
    else
      Magic2 := L + S - ((L * S) + (HLSMAX div 2)) div HLSMAX;
    Magic1 := 2 * L - Magic2;

    R := (HueToRGB(Magic1, Magic2, H + (HLSMAX div 3)) * RGBMAX + (HLSMAX div 2)) div HLSMAX;
    G := (HueToRGB(Magic1, Magic2, H) * RGBMAX + (HLSMAX div 2)) div HLSMAX;
    B := (HueToRGB(Magic1, Magic2, H - (HLSMAX div 3)) * RGBMAX + (HLSMAX div 2)) div HLSMAX;
  end;
  if R > RGBMAX then R := RGBMAX; if R < 0 then R := 0;
  if G > RGBMAX then G := RGBMAX; if G < 0 then G := 0;
  if B > RGBMAX then B := RGBMAX; if B < 0 then B := 0;
end;

end.

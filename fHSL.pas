unit fHSL;
{ ABA 1 - Aula 03: conversao RGB <-> HSL (padrao do Paint do Windows).
  A matematica fica em uCores.pas; aqui so ha a interface. }
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Graphics, uCores, uUI;

type
  TfrmHSL = class(TFrame)
  private
    eR, eG, eB, eH, eS, eL: TEdit;
    Amostra: TPanel;
    procedure RgbParaHsl(Sender: TObject);
    procedure HslParaRgb(Sender: TObject);
    procedure Limpar(Sender: TObject);
    procedure MostraAmostra(R, G, B: Integer);
    function Num(e: TEdit; Max: Integer): Integer;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.lfm}

constructor TfrmHSL.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Rotulo(Self, 'R (0..255)', 20, 20);  eR := Campo(Self, '255', 100, 16, 60);
  Rotulo(Self, 'G (0..255)', 20, 52);  eG := Campo(Self, '0',   100, 48, 60);
  Rotulo(Self, 'B (0..255)', 20, 84);  eB := Campo(Self, '0',   100, 80, 60);
  Botao(Self, 'RGB -> HSL', 20, 118, 140, @RgbParaHsl);

  Rotulo(Self, 'H (0..239)', 240, 20); eH := Campo(Self, '0',   320, 16, 60);
  Rotulo(Self, 'S (0..240)', 240, 52); eS := Campo(Self, '240', 320, 48, 60);
  Rotulo(Self, 'L (0..240)', 240, 84); eL := Campo(Self, '120', 320, 80, 60);
  Botao(Self, 'HSL -> RGB', 240, 118, 140, @HslParaRgb);

  Botao(Self, 'Limpar', 20, 160, 100, @Limpar);

  Amostra := TPanel.Create(Self);
  Amostra.Parent := Self;
  Amostra.SetBounds(440, 16, 180, 130);
  Amostra.Caption := 'amostra';
  Amostra.Color := clRed;
end;

function TfrmHSL.Num(e: TEdit; Max: Integer): Integer;
begin
  Result := StrToIntDef(Trim(e.Text), 0);
  if Result < 0 then Result := 0;
  if Result > Max then Result := Max;
  e.Text := IntToStr(Result);   // mostra o valor ja limitado
end;

procedure TfrmHSL.MostraAmostra(R, G, B: Integer);
begin
  Amostra.Color := TColor(RGBparaCor(R, G, B));
end;

procedure TfrmHSL.RgbParaHsl(Sender: TObject);
var
  R, G, B, H, L, S: Integer;
begin
  R := Num(eR, 255); G := Num(eG, 255); B := Num(eB, 255);
  RGBparaHLS(R, G, B, H, L, S);
  eH.Text := IntToStr(H); eS.Text := IntToStr(S); eL.Text := IntToStr(L);
  MostraAmostra(R, G, B);
end;

procedure TfrmHSL.HslParaRgb(Sender: TObject);
var
  R, G, B, H, L, S: Integer;
begin
  H := Num(eH, 239); S := Num(eS, 240); L := Num(eL, 240);
  HLSparaRGB(H, L, S, R, G, B);
  eR.Text := IntToStr(R); eG.Text := IntToStr(G); eB.Text := IntToStr(B);
  MostraAmostra(R, G, B);
end;

procedure TfrmHSL.Limpar(Sender: TObject);
begin
  eR.Text := '0'; eG.Text := '0'; eB.Text := '0';
  eH.Text := '0'; eS.Text := '0'; eL.Text := '0';
  MostraAmostra(0, 0, 0);
end;

end.

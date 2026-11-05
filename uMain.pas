unit uMain;
{ Formulario principal: um TPageControl com uma aba (TTabSheet) por pratica.
  Cada aba hospeda um TFrame em unit propria. }
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ComCtrls, ExtCtrls, Graphics, fHSL, fPixels, fRetas, fBresenham, fCirculos, fBresenhamCirc, fCasinha, fClipping, fPreenchimento, fZBuffer;

type
  TfrmMain = class(TForm)
  private
    Paginas: TPageControl;
    Tempo: TTimer;
    procedure Captura(Sender: TObject);
    function NovaAba(const Titulo: string): TTabSheet;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ Uso interno para conferir as abas: CG --captura prefixo  salva prefixoN.png e fecha }
procedure TfrmMain.Captura(Sender: TObject);
var
  i: Integer;
  Img: TBitmap;
begin
  Tempo.Enabled := False;
  for i := 0 to Paginas.PageCount - 1 do
  begin
    Paginas.ActivePageIndex := i;
    Application.ProcessMessages;
    Img := GetFormImage;
    try
      Img.SaveToFile(ParamStr(2) + IntToStr(i + 1) + '.bmp');
    finally
      Img.Free;
    end;
  end;
  Close;
end;

function TfrmMain.NovaAba(const Titulo: string): TTabSheet;
begin
  Result := TTabSheet.Create(Paginas);
  Result.PageControl := Paginas;
  Result.Caption := Titulo;
end;

constructor TfrmMain.Create(AOwner: TComponent);

  procedure Poe(Quadro: TFrame; Aba: TTabSheet);
  begin
    Quadro.Parent := Aba;
    Quadro.Align := alClient;
  end;

begin
  inherited Create(AOwner);
  Caption := 'Computacao Grafica - Praticas';
  Paginas := TPageControl.Create(Self);
  Paginas.Parent := Self;
  Paginas.Align := alClient;

  Poe(TfrmHSL.Create(Self), NovaAba('1 HSL'));
  Poe(TfrmPixels.Create(Self), NovaAba('2 Pixels'));
  Poe(TfrmRetas.Create(Self), NovaAba('3 Retas'));
  Poe(TfrmBresenham.Create(Self), NovaAba('4 Bresenham'));
  Poe(TfrmCirculos.Create(Self), NovaAba('5 Circulos'));
  Poe(TfrmBresenhamCirc.Create(Self), NovaAba('6 Bresenham Circ'));
  Poe(TfrmCasinha.Create(Self), NovaAba('7 Casinha 3D'));
  Poe(TfrmClipping.Create(Self), NovaAba('8 Clipping'));
  Poe(TfrmPreenchimento.Create(Self), NovaAba('9 Preenchimento'));
  Poe(TfrmZBuffer.Create(Self), NovaAba('10 Z-Buffer'));

  if (ParamCount >= 2) and (ParamStr(1) = '--captura') then
  begin
    Tempo := TTimer.Create(Self);
    Tempo.Interval := 1500;
    Tempo.OnTimer := @Captura;
  end;
end;

end.

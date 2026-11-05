unit fPixels;
{ ABA 2 - Aula 04: pratica com pixels (carregar imagem, cinza, inverter,
  separar canais, ler pixels, retas com Canvas). }
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Graphics, Dialogs,
  ExtDlgs, uCores, uUI, uAreaDesenho;

type
  TfrmPixels = class(TFrame)
  private
    Area: TAreaDesenho;
    Orig: TBufCores;          // copia da imagem carregada, para "Restaurar"
    OW, OH: Integer;
    chkMedia: TCheckBox;
    lblRGB: TLabel;
    Dlg: TOpenPictureDialog;
    procedure GuardaOriginal;
    procedure Abrir(Sender: TObject);
    procedure Cinza(Sender: TObject);
    procedure Inverter(Sender: TObject);
    procedure Separar(Sender: TObject);
    procedure Restaurar(Sender: TObject);
    procedure Retas(Sender: TObject);
    procedure Mover(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Clicar(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure AoLimpar(Sender: TObject);
    procedure ImagemInicial;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.lfm}

constructor TfrmPixels.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Area := TAreaDesenho.Create(Self, 640, 480, clWhite, 76);
  Area.OnMover := @Mover;
  Area.OnLimpar := @AoLimpar;
  Area.Imagem.OnMouseDown := @Clicar;

  Dlg := TOpenPictureDialog.Create(Self);
  Dlg.Filter := 'Imagens|*.bmp;*.png;*.jpg;*.jpeg|Todos|*.*';

  Botao(Area.Barra, 'a) Abrir imagem', 6, 4, 120, @Abrir);
  Botao(Area.Barra, 'b) Tons de cinza', 132, 4, 120, @Cinza);
  chkMedia := TCheckBox.Create(Self);
  chkMedia.Parent := Area.Barra;
  chkMedia.Caption := 'media (R+G+B)/3';
  chkMedia.SetBounds(258, 8, 140, 22);
  Botao(Area.Barra, 'c) Inverter', 404, 4, 100, @Inverter);
  Botao(Area.Barra, 'd) Separar R G B', 510, 4, 130, @Separar);
  Botao(Area.Barra, 'Restaurar', 646, 4, 90, @Restaurar);
  Botao(Area.Barra, 'f) Retas (LineTo)', 6, 38, 130, @Retas);
  lblRGB := Rotulo(Area.Barra, 'e) clique desenha ponto; mouse mostra R,G,B', 148, 44);
  lblRGB.Width := 420;

  ImagemInicial;
end;

{ imagem de teste (degrade colorido) para a aba funcionar sem abrir arquivo }
procedure TfrmPixels.ImagemInicial;
var
  x, y: Integer;
begin
  Area.Redimensionar(320, 240);
  for y := 0 to 239 do
    for x := 0 to 319 do
      Area.Plot(x, y, RGBparaCor(x * 255 div 319, y * 255 div 239, 255 - x * 255 div 319));
  Area.Atualizar;
  GuardaOriginal;
end;

procedure TfrmPixels.GuardaOriginal;
begin
  Area.Copiar(Orig);
  OW := Area.Largura;
  OH := Area.Altura;
end;

{ a) carregar imagem: TPicture le bmp/png/jpg; desenhamos num TBitmap
  e CarregarDoBitmap le os pixels para o buffer }
procedure TfrmPixels.Abrir(Sender: TObject);
var
  P: TPicture;
  B: TBitmap;
begin
  if not Dlg.Execute then Exit;
  P := TPicture.Create;
  B := TBitmap.Create;
  try
    try
      P.LoadFromFile(Dlg.FileName);
    except
      on E: Exception do begin ShowMessage('Nao foi possivel abrir: ' + E.Message); Exit; end;
    end;
    B.SetSize(P.Width, P.Height);
    B.Canvas.Draw(0, 0, P.Graphic);
    Area.CarregarDoBitmap(B);
    GuardaOriginal;
  finally
    B.Free;
    P.Free;
  end;
end;

{ b) tons de cinza: I = 0.299 R + 0.587 G + 0.114 B  (ou media simples) }
procedure TfrmPixels.Cinza(Sender: TObject);
var
  x, y, R, G, B, I: Integer;
begin
  for y := 0 to Area.Altura - 1 do
    for x := 0 to Area.Largura - 1 do
    begin
      CorParaRGB(Area.Ler(x, y), R, G, B);
      if chkMedia.Checked then
        I := (R + G + B) div 3
      else
        I := Round(0.299 * R + 0.587 * G + 0.114 * B);
      Area.Plot(x, y, RGBparaCor(I, I, I));
    end;
  Area.Atualizar;
end;

{ c) inverter: 255 - canal }
procedure TfrmPixels.Inverter(Sender: TObject);
var
  x, y, R, G, B: Integer;
begin
  for y := 0 to Area.Altura - 1 do
    for x := 0 to Area.Largura - 1 do
    begin
      CorParaRGB(Area.Ler(x, y), R, G, B);
      Area.Plot(x, y, RGBparaCor(255 - R, 255 - G, 255 - B));
    end;
  Area.Atualizar;
end;

{ d) tres imagens lado a lado: so R, so G, so B }
procedure TfrmPixels.Separar(Sender: TObject);
var
  Src: TBufCores;
  W, H, x, y, R, G, B: Integer;
begin
  Area.Copiar(Src);
  W := Area.Largura;
  H := Area.Altura;
  Area.Redimensionar(3 * W, H);
  for y := 0 to H - 1 do
    for x := 0 to W - 1 do
    begin
      CorParaRGB(Src[y * W + x], R, G, B);
      Area.Plot(x, y, RGBparaCor(R, 0, 0));
      Area.Plot(W + x, y, RGBparaCor(0, G, 0));
      Area.Plot(2 * W + x, y, RGBparaCor(0, 0, B));
    end;
  Area.Atualizar;
end;

procedure TfrmPixels.Restaurar(Sender: TObject);
begin
  Area.Colar(Orig, OW, OH);
end;

{ f) unico lugar onde LineTo e permitido: vertical, horizontal e diagonais.
  Desenha no Canvas do bitmap e depois relê para o buffer. }
procedure TfrmPixels.Retas(Sender: TObject);
var
  C: TCanvas;
  W, H: Integer;
begin
  W := Area.Largura;
  H := Area.Altura;
  C := Area.Imagem.Picture.Bitmap.Canvas;
  C.Pen.Width := 1;
  C.Pen.Color := clBlack;
  C.MoveTo(W div 2, 0);  C.LineTo(W div 2, H - 1);        // vertical
  C.MoveTo(0, H div 2);  C.LineTo(W - 1, H div 2);        // horizontal
  C.Pen.Color := clRed;
  C.MoveTo(0, 0);        C.LineTo(W - 1, H - 1);          // diagonal \
  C.Pen.Color := clBlue;
  C.MoveTo(0, H - 1);    C.LineTo(W - 1, 0);              // diagonal /
  Area.CarregarDoBitmap(Area.Imagem.Picture.Bitmap);
end;

{ e) acesso aos pixels: x,y (rotulo da area) + R,G,B do pixel sob o cursor }
procedure TfrmPixels.Mover(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  R, G, B: Integer;
begin
  CorParaRGB(Area.Ler(X, Y), R, G, B);
  lblRGB.Caption := Format('e) pixel (%d,%d): R=%d G=%d B=%d', [X, Y, R, G, B]);
end;

{ e) clicar desenha um ponto (quadrado 3x3 vermelho) }
procedure TfrmPixels.Clicar(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i, j: Integer;
begin
  for j := -1 to 1 do
    for i := -1 to 1 do
      Area.Plot(X + i, Y + j, RGBparaCor(255, 0, 0));
  Area.Atualizar;
end;

procedure TfrmPixels.AoLimpar(Sender: TObject);
begin
  lblRGB.Caption := 'e) clique desenha ponto; mouse mostra R,G,B';
end;

end.

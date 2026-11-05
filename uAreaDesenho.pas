unit uAreaDesenho;
{ Area de desenho comum a todas as abas.
  - Guarda um buffer proprio de pixels (FBuf). Os algoritmos plotam NELE (pixel a pixel)
    e depois Atualizar copia o buffer para o TBitmap do TImage.
  - Nada de LineTo/Ellipse/FloodFill aqui: so Plot/Ler.
  - Cria sozinha: barra superior (controles da aba), botao Limpar e rotulo x,y do mouse. }
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, StdCtrls, Forms, Graphics, IntfGraphics,
  FPImage, uCores;

type
  TAreaDesenho = class
  private
    FImg: TImage;
    FBarra, FRodape: TPanel;
    FLblXY, FLblInfo: TLabel;
    FBuf: TBufCores;
    FW, FH: Integer;
    FFundo: TColor;
    FOnLimpar: TNotifyEvent;
    FOnMover: TMouseMoveEvent;
    procedure SetInfo(const S: string);
    procedure MouseMover(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ClicaLimpar(Sender: TObject);
  public
    Contagem: Integer;                         // pixels plotados (a aba zera e le)
    constructor Create(Dono: TWinControl; Larg, Alt: Integer; Fundo: TColor;
      AlturaBarra: Integer);
    procedure Redimensionar(Larg, Alt: Integer);
    procedure Limpar;
    function Dentro(x, y: Integer): Boolean;
    procedure Plot(x, y: Integer; cor: TColor);
    function Ler(x, y: Integer): TColor;
    procedure Atualizar;                       // buffer -> tela
    procedure CarregarDoBitmap(B: TBitmap);    // bitmap -> buffer (redimensiona)
    procedure Copiar(out Dest: TBufCores);
    procedure Colar(const Orig: TBufCores; Larg, Alt: Integer);
    property Info: string write SetInfo;       // texto de status no rodape
    property Largura: Integer read FW;
    property Altura: Integer read FH;
    property Fundo: TColor read FFundo write FFundo;
    property Imagem: TImage read FImg;
    property Barra: TPanel read FBarra;
    property OnLimpar: TNotifyEvent read FOnLimpar write FOnLimpar;
    property OnMover: TMouseMoveEvent read FOnMover write FOnMover;
  end;

implementation

constructor TAreaDesenho.Create(Dono: TWinControl; Larg, Alt: Integer;
  Fundo: TColor; AlturaBarra: Integer);
var
  Caixa: TScrollBox;
  Btn: TButton;
begin
  inherited Create;
  FFundo := Fundo;

  FBarra := TPanel.Create(Dono);
  FBarra.Parent := Dono;
  FBarra.Align := alTop;
  FBarra.Height := AlturaBarra;
  FBarra.BevelOuter := bvNone;

  FRodape := TPanel.Create(Dono);
  FRodape.Parent := Dono;
  FRodape.Align := alBottom;
  FRodape.Height := 34;
  FRodape.BevelOuter := bvNone;

  Btn := TButton.Create(Dono);
  Btn.Parent := FRodape;
  Btn.Caption := 'Limpar';
  Btn.SetBounds(6, 4, 90, 27);
  Btn.OnClick := @ClicaLimpar;

  FLblXY := TLabel.Create(Dono);
  FLblXY.Parent := FRodape;
  FLblXY.SetBounds(110, 9, 300, 17);
  FLblXY.Caption := 'x,y = -';

  FLblInfo := TLabel.Create(Dono);
  FLblInfo.Parent := FRodape;
  FLblInfo.SetBounds(330, 9, 500, 17);

  Caixa := TScrollBox.Create(Dono);
  Caixa.Parent := Dono;
  Caixa.Align := alClient;

  FImg := TImage.Create(Dono);
  FImg.Parent := Caixa;
  FImg.Stretch := False;
  FImg.AutoSize := False;
  FImg.OnMouseMove := @MouseMover;

  Redimensionar(Larg, Alt);
end;

procedure TAreaDesenho.Redimensionar(Larg, Alt: Integer);
begin
  FW := Larg;
  FH := Alt;
  SetLength(FBuf, FW * FH);
  FImg.SetBounds(0, 0, FW, FH);
  FImg.Picture.Bitmap.SetSize(FW, FH);
  Limpar;
end;

procedure TAreaDesenho.Limpar;
var
  i: Integer;
begin
  for i := 0 to High(FBuf) do FBuf[i] := FFundo;
  Atualizar;
end;

function TAreaDesenho.Dentro(x, y: Integer): Boolean;
begin
  Result := (x >= 0) and (y >= 0) and (x < FW) and (y < FH);
end;

procedure TAreaDesenho.Plot(x, y: Integer; cor: TColor);
begin
  if Dentro(x, y) then
  begin
    FBuf[y * FW + x] := cor;
    Inc(Contagem);
  end;
end;

function TAreaDesenho.Ler(x, y: Integer): TColor;
begin
  if Dentro(x, y) then Result := FBuf[y * FW + x] else Result := FFundo;
end;

procedure TAreaDesenho.Atualizar;
var
  Bmp: TBitmap;
  Img: TLazIntfImage;
  x, y, c: Integer;
begin
  Bmp := FImg.Picture.Bitmap;
  Img := Bmp.CreateIntfImage;
  try
    for y := 0 to FH - 1 do
      for x := 0 to FW - 1 do
      begin
        c := FBuf[y * FW + x];
        Img.Colors[x, y] := FPColor((c and $FF) * 257, ((c shr 8) and $FF) * 257,
                                    ((c shr 16) and $FF) * 257);
      end;
    Bmp.LoadFromIntfImage(Img);
  finally
    Img.Free;
  end;
  FImg.Invalidate;
end;

procedure TAreaDesenho.CarregarDoBitmap(B: TBitmap);
var
  Img: TLazIntfImage;
  x, y: Integer;
  c: TFPColor;
begin
  Redimensionar(B.Width, B.Height);
  Img := B.CreateIntfImage;
  try
    for y := 0 to FH - 1 do
      for x := 0 to FW - 1 do
      begin
        c := Img.Colors[x, y];
        FBuf[y * FW + x] := (c.red shr 8) or ((c.green shr 8) shl 8) or
                            ((c.blue shr 8) shl 16);
      end;
  finally
    Img.Free;
  end;
  Atualizar;
end;

procedure TAreaDesenho.Copiar(out Dest: TBufCores);
begin
  Dest := Copy(FBuf);
end;

procedure TAreaDesenho.Colar(const Orig: TBufCores; Larg, Alt: Integer);
begin
  if (Larg <> FW) or (Alt <> FH) then Redimensionar(Larg, Alt);
  FBuf := Copy(Orig);
  Atualizar;
end;

procedure TAreaDesenho.SetInfo(const S: string);
begin
  FLblInfo.Caption := S;
end;

procedure TAreaDesenho.MouseMover(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  FLblXY.Caption := Format('x,y = %d,%d', [X, Y]);
  if Assigned(FOnMover) then FOnMover(Sender, Shift, X, Y);
end;

procedure TAreaDesenho.ClicaLimpar(Sender: TObject);
begin
  Limpar;
  if Assigned(FOnLimpar) then FOnLimpar(Self);
end;

end.

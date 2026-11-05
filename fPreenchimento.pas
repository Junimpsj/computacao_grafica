unit fPreenchimento;
{ ABA 9 - Aula 16: preenchimento de poligonos.
  Clique esquerdo adiciona vertice, direito fecha. Bordas com Bresenham.
  Modo 1: inversao de cores (edge fill) com bounding box, com passo a passo.
  Modo 2: flood fill (semente), vizinhanca 4 ou 8, pilha explicita.
  "Grade de teste": mostra em zoom 20x20 que a vizinhanca 8 vaza pelas diagonais. }
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Graphics, Math,
  uCores, uUI, uAreaDesenho, uLinhas, uPreenchimento;

type
  TfrmPreenchimento = class(TFrame)
  private
    Area: TAreaDesenho;
    Modo, Viz: TRadioGroup;
    chkBBox: TCheckBox;
    lblInfo: TLabel;
    Poly: TPoligono;
    Fechado: Boolean;
    Limpo: TBufCores;        // imagem antes de qualquer borda
    Camada: TBufCores;       // so a inversao (sem bordas), para o passo a passo
    Passo: Integer;
    ModoGrade: Boolean;
    Grade: TBufCores;        // grade de teste (32 x 24 pixels logicos)
    procedure Descer(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure AoLimpar(Sender: TObject);
    procedure Preencher(Sender: TObject);
    procedure PassoAPasso(Sender: TObject);
    procedure CarregaGrade(Sender: TObject);
    procedure Redesenha;
    procedure DesenhaGrade;
    procedure Aresta(i: Integer);
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.lfm}

const
  CorBorda = $000000;      // preto
  CorPreench = $0000FF;    // vermelho (BGR)
  CorFundo = $FFFFFF;      // branco
  GW = 32;                 // grade de teste: 32 x 24 pixels logicos
  GH = 24;
  ZOOM = 20;               // cada pixel logico = quadrado 20x20

constructor TfrmPreenchimento.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Area := TAreaDesenho.Create(Self, 640, 480, clWhite, 80);
  Area.Imagem.OnMouseDown := @Descer;
  Area.OnLimpar := @AoLimpar;

  Modo := TRadioGroup.Create(Self);
  Modo.Parent := Area.Barra;
  Modo.SetBounds(4, 0, 230, 78);
  Modo.Caption := 'Modo';
  Modo.Items.Text := '1) Inversao de cores (edge fill)'#10'2) Flood fill (clique = semente)'#10'3) Scanline (lista ordenada)';
  Modo.ItemIndex := 0;

  Viz := TRadioGroup.Create(Self);
  Viz.Parent := Area.Barra;
  Viz.SetBounds(240, 0, 150, 46);
  Viz.Caption := 'Vizinhanca (flood)';
  Viz.Columns := 2;
  Viz.Items.Text := '4'#10'8';
  Viz.ItemIndex := 0;

  chkBBox := TCheckBox.Create(Self);
  chkBBox.Parent := Area.Barra;
  chkBBox.Caption := 'mostrar bounding box';
  chkBBox.SetBounds(240, 52, 170, 22);

  Botao(Area.Barra, 'Preencher (modo 1 ou 3)', 420, 4, 150, @Preencher);
  Botao(Area.Barra, 'Passo a passo', 420, 38, 150, @PassoAPasso);
  Botao(Area.Barra, 'Grade de teste', 580, 4, 120, @CarregaGrade);
  lblInfo := Rotulo(Area.Barra, 'clique: vertices; direito: fecha', 580, 48);
  lblInfo.Width := 300;
end;

procedure TfrmPreenchimento.AoLimpar(Sender: TObject);
begin
  SetLength(Poly, 0);
  Fechado := False;
  ModoGrade := False;
  Passo := 0;
  lblInfo.Caption := 'clique: vertices; direito: fecha';
end;

procedure TfrmPreenchimento.Aresta(i: Integer);
var
  j: Integer;
begin
  j := (i + 1) mod Length(Poly);
  RetaBresenham(Poly[i].x, Poly[i].y, Poly[j].x, Poly[j].y, CorBorda, @Area.Plot);
end;

{ camada de inversao + bordas (+ bounding box opcional) }
procedure TfrmPreenchimento.Redesenha;
var
  i, xmin, ymin, xmax, ymax: Integer;
begin
  Area.Colar(Camada, Area.Largura, Area.Altura);
  for i := 0 to High(Poly) do Aresta(i);
  if chkBBox.Checked and (Length(Poly) > 0) then
  begin
    BoundingBox(Poly, xmin, ymin, xmax, ymax);
    RetaBresenham(xmin, ymin, xmax, ymin, $808080, @Area.Plot);
    RetaBresenham(xmax, ymin, xmax, ymax, $808080, @Area.Plot);
    RetaBresenham(xmax, ymax, xmin, ymax, $808080, @Area.Plot);
    RetaBresenham(xmin, ymax, xmin, ymin, $808080, @Area.Plot);
  end;
  Area.Atualizar;
end;

procedure TfrmPreenchimento.Descer(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  n, gx, gy: Integer;
  Buf: TBufCores;
begin
  if ModoGrade then
  begin
    // semente na grade de teste (zoom): converte pixel de tela em pixel logico
    gx := X div ZOOM; gy := Y div ZOOM;
    FloodFill(Grade, GW, GH, gx, gy, CorBorda, CorPreench, Viz.ItemIndex = 1);
    DesenhaGrade;
    Exit;
  end;

  if Fechado then
  begin
    if Modo.ItemIndex = 1 then
    begin
      // flood fill sobre o buffer da area (bordas = preto, preenchimento = vermelho)
      Area.Copiar(Buf);
      FloodFill(Buf, Area.Largura, Area.Altura, X, Y, CorBorda, CorPreench, Viz.ItemIndex = 1);
      Area.Colar(Buf, Area.Largura, Area.Altura);
    end;
    Exit;
  end;

  if Button = mbRight then
  begin
    if Length(Poly) >= 3 then
    begin
      Aresta(High(Poly));            // aresta de fechamento
      Fechado := True;
      Camada := Copy(Limpo);
      Passo := 0;
      Area.Atualizar;
      lblInfo.Caption := 'poligono fechado';
    end;
    Exit;
  end;

  n := Length(Poly);
  if n = 0 then Area.Copiar(Limpo);    // guarda a imagem antes das bordas
  SetLength(Poly, n + 1);
  Poly[n].x := X; Poly[n].y := Y;
  if n = 0 then
    Area.Plot(X, Y, CorBorda)
  else
    RetaBresenham(Poly[n - 1].x, Poly[n - 1].y, X, Y, CorBorda, @Area.Plot);
  Area.Atualizar;
end;

procedure TfrmPreenchimento.Preencher(Sender: TObject);
begin
  if not Fechado then begin lblInfo.Caption := 'feche o poligono (clique direito)'; Exit; end;
  Camada := Copy(Limpo);
  if Modo.ItemIndex = 2 then
  begin
    PreencheScanline(Camada, Area.Largura, Area.Altura, Poly, CorPreench);
    lblInfo.Caption := 'preenchido (scanline)';
  end
  else
  begin
    PreencheInversao(Camada, Area.Largura, Area.Altura, Poly, CorFundo, CorPreench);
    lblInfo.Caption := 'preenchido (inversao, todas as arestas)';
  end;
  Passo := Length(Poly);
  Redesenha;
end;

{ mostra o resultado depois de cada aresta }
procedure TfrmPreenchimento.PassoAPasso(Sender: TObject);
var
  i, j, xmin, ymin, xmax, ymax: Integer;
begin
  if not Fechado then begin lblInfo.Caption := 'feche o poligono (clique direito)'; Exit; end;
  if Passo >= Length(Poly) then
  begin
    Camada := Copy(Limpo);        // recomeca
    Passo := 0;
  end;
  BoundingBox(Poly, xmin, ymin, xmax, ymax);
  i := Passo;
  j := (i + 1) mod Length(Poly);
  InverteAresta(Camada, Area.Largura, Area.Altura, Poly[i].x, Poly[i].y,
                Poly[j].x, Poly[j].y, xmax, CorFundo, CorPreench);
  Inc(Passo);
  Redesenha;
  lblInfo.Caption := Format('aresta %d de %d', [Passo, Length(Poly)]);
end;

{ grade de teste: losango cuja borda so se toca pelas diagonais (8-conexa).
  Vizinhanca 4 nao atravessa; vizinhanca 8 vaza. }
procedure TfrmPreenchimento.CarregaGrade(Sender: TObject);
var
  x, y: Integer;
begin
  Area.Limpar;
  AoLimpar(Sender);
  ModoGrade := True;
  SetLength(Grade, GW * GH);
  for y := 0 to GH - 1 do
    for x := 0 to GW - 1 do
      if Abs(x - 16) + Abs(y - 12) = 9 then Grade[y * GW + x] := CorBorda
      else Grade[y * GW + x] := CorFundo;
  DesenhaGrade;
  lblInfo.Caption := 'clique dentro do losango (troque 4/8 e recarregue)';
end;

procedure TfrmPreenchimento.DesenhaGrade;
var
  x, y, i, j: Integer;
begin
  for y := 0 to GH - 1 do
    for x := 0 to GW - 1 do
      for j := 0 to ZOOM - 1 do
        for i := 0 to ZOOM - 1 do
          if (i = ZOOM - 1) or (j = ZOOM - 1) then
            Area.Plot(x * ZOOM + i, y * ZOOM + j, $D0D0D0)     // linha de grade
          else
            Area.Plot(x * ZOOM + i, y * ZOOM + j, Grade[y * GW + x]);
  Area.Atualizar;
end;

end.

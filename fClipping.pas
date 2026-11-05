unit fClipping;
{ ABA 8 - Aula 15a/15b/15c: recorte de retas (Cohen-Sutherland e Liang-Barsky).
  1) dois cliques definem a janela de recorte;
  2) clicar, arrastar e soltar define cada reta (com previa durante o arraste). }
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Graphics, Math,
  uCores, uUI, uAreaDesenho, uLinhas, uClipping;

type
  TfrmClipping = class(TFrame)
  private
    Area: TAreaDesenho;
    Algo: TRadioGroup;
    chkDescartada: TCheckBox;
    lblEstado: TLabel;
    Estado: Integer;                // 0 = aguarda 1o canto, 1 = aguarda 2o, 2 = desenha retas
    jx1, jy1, jx2, jy2: Integer;    // janela (pixels de tela, normalizada)
    ax, ay: Integer;                // inicio da reta
    Arrastando: Boolean;
    Base: TBufCores;
    procedure Descer(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure Mover(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Subir(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure AoLimpar(Sender: TObject);
    procedure NovaJanela(Sender: TObject);
    procedure DesenhaJanela;
    procedure RecortaEDesenha(x1, y1, x2, y2: Integer);
    procedure Texto;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.lfm}

const
  CorJanela = $FF0000;     // azul (BGR)
  CorReta = $000000;
  CorDescartada = $B0B0B0; // cinza

constructor TfrmClipping.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Area := TAreaDesenho.Create(Self, 640, 480, clWhite, 56);
  Area.Imagem.OnMouseDown := @Descer;
  Area.Imagem.OnMouseUp := @Subir;
  Area.OnMover := @Mover;
  Area.OnLimpar := @AoLimpar;

  Algo := TRadioGroup.Create(Self);
  Algo.Parent := Area.Barra;
  Algo.SetBounds(4, 0, 330, 54);
  Algo.Caption := 'Algoritmo';
  Algo.Columns := 2;
  Algo.Items.Text := 'Cohen-Sutherland'#10'Liang-Barsky';
  Algo.ItemIndex := 0;

  chkDescartada := TCheckBox.Create(Self);
  chkDescartada.Parent := Area.Barra;
  chkDescartada.Caption := 'mostrar parte descartada em cinza';
  chkDescartada.SetBounds(350, 4, 260, 22);
  chkDescartada.Checked := True;

  Botao(Area.Barra, 'Nova janela', 350, 26, 110, @NovaJanela);
  lblEstado := Rotulo(Area.Barra, '', 470, 32);
  lblEstado.Width := 400;
  Texto;
end;

procedure TfrmClipping.Texto;
begin
  case Estado of
    0: lblEstado.Caption := 'clique o 1o canto da janela de recorte';
    1: lblEstado.Caption := 'clique o 2o canto da janela';
  else
    lblEstado.Caption := 'arraste para desenhar retas';
  end;
end;

procedure TfrmClipping.AoLimpar(Sender: TObject);
begin
  Estado := 0;
  Arrastando := False;
  Texto;
end;

procedure TfrmClipping.NovaJanela(Sender: TObject);
begin
  Area.Limpar;
  AoLimpar(Sender);
end;

procedure TfrmClipping.DesenhaJanela;
begin
  RetaBresenham(jx1, jy1, jx2, jy1, CorJanela, @Area.Plot);
  RetaBresenham(jx2, jy1, jx2, jy2, CorJanela, @Area.Plot);
  RetaBresenham(jx2, jy2, jx1, jy2, CorJanela, @Area.Plot);
  RetaBresenham(jx1, jy2, jx1, jy1, CorJanela, @Area.Plot);
end;

{ Janela/porta de visao: a tela tem y para baixo, o algoritmo usa y para cima.
  ym = (H-1) - ys  converte; depois converte o resultado de volta.
  Assim "acima" do algoritmo e o topo visual da tela. }
procedure TfrmClipping.RecortaEDesenha(x1, y1, x2, y2: Integer);
var
  H: Integer;
  a, b, c, d: Double;
  ok: Boolean;
begin
  H := Area.Altura;
  if chkDescartada.Checked then
    RetaBresenham(x1, y1, x2, y2, CorDescartada, @Area.Plot);   // reta inteira em cinza

  a := x1; b := (H - 1) - y1;
  c := x2; d := (H - 1) - y2;
  // janela em coordenadas matematicas: ymin_m = (H-1)-jy2 (borda de baixo da tela)
  if Algo.ItemIndex = 0 then
    ok := CohenSutherland(jx1, (H - 1) - jy2, jx2, (H - 1) - jy1, a, b, c, d)
  else
    ok := LiangBarsky(jx1, (H - 1) - jy2, jx2, (H - 1) - jy1, a, b, c, d);

  if ok then
  begin
    RetaBresenham(Arred(a), (H - 1) - Arred(b), Arred(c), (H - 1) - Arred(d),
                  CorReta, @Area.Plot);
    Area.Info := Format('visivel: (%.2f, %.2f) - (%.2f, %.2f)', [a, (H - 1) - b, c, (H - 1) - d]);
  end
  else
    Area.Info := 'reta totalmente fora da janela (descartada)';
  DesenhaJanela;     // a janela por cima, para ela continuar visivel
end;

procedure TfrmClipping.Descer(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  case Estado of
    0:
      begin
        jx1 := X; jy1 := Y;
        Area.Plot(X, Y, CorJanela); Area.Plot(X + 1, Y, CorJanela);
        Area.Plot(X, Y + 1, CorJanela); Area.Plot(X + 1, Y + 1, CorJanela);
        Area.Atualizar;
        Estado := 1;
      end;
    1:
      begin
        jx2 := X; jy2 := Y;
        if jx1 > jx2 then begin X := jx1; jx1 := jx2; jx2 := X; end;   // normaliza
        if jy1 > jy2 then begin Y := jy1; jy1 := jy2; jy2 := Y; end;
        DesenhaJanela;
        Area.Atualizar;
        Estado := 2;
      end;
  else
    begin
      ax := X; ay := Y;
      Area.Copiar(Base);
      Arrastando := True;
    end;
  end;
  Texto;
end;

procedure TfrmClipping.Mover(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if not Arrastando then Exit;
  // previa da reta enquanto arrasta
  Area.Colar(Base, Area.Largura, Area.Altura);
  RetaBresenham(ax, ay, X, Y, CorDescartada, @Area.Plot);
  Area.Atualizar;
end;

procedure TfrmClipping.Subir(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if not Arrastando then Exit;
  Arrastando := False;
  Area.Colar(Base, Area.Largura, Area.Altura);
  RecortaEDesenha(ax, ay, X, Y);
  Area.Atualizar;
end;

end.

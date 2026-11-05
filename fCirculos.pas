unit fCirculos;
{ ABA 5 - Aula 07: circunferencias por pixels (equacao, parametrica, rotacoes).
  Clique e arraste: o clique define o centro, o arraste define o raio.
  A aba 6 (Bresenham) herda este frame. }
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Graphics, Math,
  uCores, uUI, uAreaDesenho, uLinhas, uCirculos;

type
  TfrmCirculos = class(TFrame)
  protected
    Area: TAreaDesenho;
    eXc, eYc, eR, ePasso: TEdit;
    Metodo: TRadioGroup;
    chkSim8: TCheckBox;
    Base: TBufCores;       // imagem antes do arraste (para a previa)
    Arrastando: Boolean;
    class function Itens: string; virtual;
    class function ComExtras: Boolean; virtual;
    procedure Desenha(xc, yc, R: Integer; cor: TColor); virtual;
    procedure Desenhar(Sender: TObject);
    procedure Descer(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure Mover(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Subir(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    function Val(e: TEdit): Integer;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.lfm}

class function TfrmCirculos.Itens: string;
begin
  Result := '1) y = sqrt(R2 - x2)'#10'2) Parametrica (cos, sen)'#10 +
            '3) Rotacoes incrementais (1 grau)';
end;

class function TfrmCirculos.ComExtras: Boolean;
begin
  Result := True;
end;

constructor TfrmCirculos.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Area := TAreaDesenho.Create(Self, 640, 480, clWhite, 78);
  Area.Imagem.OnMouseDown := @Descer;
  Area.Imagem.OnMouseUp := @Subir;
  Area.OnMover := @Mover;

  Metodo := TRadioGroup.Create(Self);
  Metodo.Parent := Area.Barra;
  Metodo.SetBounds(4, 0, 250, 76);
  Metodo.Caption := 'Metodo';
  Metodo.Items.Text := Itens;
  Metodo.ItemIndex := 0;

  Rotulo(Area.Barra, 'xc', 270, 8);  eXc := Campo(Area.Barra, '320', 292, 4, 50);
  Rotulo(Area.Barra, 'yc', 350, 8);  eYc := Campo(Area.Barra, '240', 372, 4, 50);
  Rotulo(Area.Barra, 'R', 270, 40);  eR := Campo(Area.Barra, '100', 292, 36, 50);
  Botao(Area.Barra, 'Desenhar', 440, 4, 100, @Desenhar);
  if ComExtras then
  begin
    Rotulo(Area.Barra, 'passo', 350, 40); ePasso := Campo(Area.Barra, '0.05', 392, 36, 50);
    chkSim8 := TCheckBox.Create(Self);
    chkSim8.Parent := Area.Barra;
    chkSim8.Caption := 'simetria de 8 (metodo 1)';
    chkSim8.SetBounds(440, 40, 200, 22);
  end;
  Rotulo(Area.Barra, 'clique+arraste na area: centro e raio', 550, 8).Width := 300;
end;

function TfrmCirculos.Val(e: TEdit): Integer;
begin
  Result := StrToIntDef(Trim(e.Text), 0);
end;

procedure TfrmCirculos.Desenha(xc, yc, R: Integer; cor: TColor);
var
  passo: Double;
begin
  case Metodo.ItemIndex of
    0: CircEquacao(xc, yc, R, cor, @Area.Plot, chkSim8.Checked);
    1:
      begin
        passo := StrToFloatDef(StringReplace(ePasso.Text, ',', '.', []), 0.05);
        CircParametrica(xc, yc, R, cor, @Area.Plot, passo);
      end;
    2: CircRotacoes(xc, yc, R, cor, @Area.Plot);
  end;
end;

procedure TfrmCirculos.Desenhar(Sender: TObject);
begin
  Area.Contagem := 0;
  Desenha(Val(eXc), Val(eYc), Val(eR), clBlack);
  Area.Info := Format('pixels plotados: %d', [Area.Contagem]);
  Area.Atualizar;
end;

procedure TfrmCirculos.Descer(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  eXc.Text := IntToStr(X);
  eYc.Text := IntToStr(Y);
  Area.Copiar(Base);
  Arrastando := True;
end;

procedure TfrmCirculos.Mover(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  R: Integer;
begin
  if not Arrastando then Exit;
  // previa: restaura a imagem anterior e desenha com o raio atual
  R := Arred(Sqrt(Sqr(X - Val(eXc)) + Sqr(Y - Val(eYc))));
  eR.Text := IntToStr(R);
  Area.Colar(Base, Area.Largura, Area.Altura);
  Area.Contagem := 0;
  Desenha(Val(eXc), Val(eYc), R, clBlack);
  Area.Info := Format('R=%d  pixels plotados: %d', [R, Area.Contagem]);
  Area.Atualizar;
end;

procedure TfrmCirculos.Subir(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Arrastando := False;
end;

end.

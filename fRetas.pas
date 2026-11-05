unit fRetas;
{ ABA 3 - Aula 05/05A: retas por pixels (equacao geral e parametrica).
  Dois cliques definem a reta (ou digite x1,y1,x2,y2). A aba 4 (Bresenham)
  herda este frame e so troca a lista de metodos e o desenho. }
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Graphics, Math,
  uCores, uUI, uAreaDesenho, uLinhas;

type
  TfrmRetas = class(TFrame)
  protected
    Area: TAreaDesenho;
    eX1, eY1, eX2, eY2: TEdit;
    Metodo: TRadioGroup;
    TemP1: Boolean;
    class function Itens: string; virtual;
    procedure Desenha(x1, y1, x2, y2: Integer; cor: TColor); virtual;
    procedure Desenhar(Sender: TObject);
    procedure Estrela(Sender: TObject);
    procedure Clicar(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure AoLimpar(Sender: TObject);
    function Val(e: TEdit): Integer;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.lfm}

class function TfrmRetas.Itens: string;
begin
  Result := 'A) Equacao geral'#10'B) Parametrica (passo 1/max)'#10 +
            'B) Parametrica (passo fixo 0.01)';
end;

constructor TfrmRetas.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Area := TAreaDesenho.Create(Self, 640, 480, clWhite, 78);
  Area.Imagem.OnMouseDown := @Clicar;
  Area.OnLimpar := @AoLimpar;

  Metodo := TRadioGroup.Create(Self);
  Metodo.Parent := Area.Barra;
  Metodo.SetBounds(4, 0, 250, 76);
  Metodo.Caption := 'Metodo';
  Metodo.Items.Text := Itens;
  Metodo.ItemIndex := 0;

  Rotulo(Area.Barra, 'x1', 270, 8);  eX1 := Campo(Area.Barra, '100', 292, 4, 50);
  Rotulo(Area.Barra, 'y1', 350, 8);  eY1 := Campo(Area.Barra, '100', 372, 4, 50);
  Rotulo(Area.Barra, 'x2', 270, 40); eX2 := Campo(Area.Barra, '400', 292, 36, 50);
  Rotulo(Area.Barra, 'y2', 350, 40); eY2 := Campo(Area.Barra, '300', 372, 36, 50);
  Botao(Area.Barra, 'Desenhar reta', 440, 4, 120, @Desenhar);
  Botao(Area.Barra, 'Desenhar estrela', 440, 36, 120, @Estrela);
  Rotulo(Area.Barra, 'ou clique 2 pontos na area', 570, 8).Width := 200;
end;

function TfrmRetas.Val(e: TEdit): Integer;
begin
  Result := StrToIntDef(Trim(e.Text), 0);
end;

{ despacha para o metodo escolhido (Area.Plot e o TPlotProc) }
procedure TfrmRetas.Desenha(x1, y1, x2, y2: Integer; cor: TColor);
begin
  case Metodo.ItemIndex of
    0: RetaEquacaoGeral(x1, y1, x2, y2, cor, @Area.Plot);
    1: RetaParametrica(x1, y1, x2, y2, cor, @Area.Plot, 0);
    2: RetaParametrica(x1, y1, x2, y2, cor, @Area.Plot, 0.01);
  end;
end;

procedure TfrmRetas.Desenhar(Sender: TObject);
begin
  Area.Contagem := 0;
  Desenha(Val(eX1), Val(eY1), Val(eX2), Val(eY2), clBlack);
  Area.Info := Format('pixels plotados: %d', [Area.Contagem]);
  Area.Atualizar;
end;

{ estrela: raios do centro em 16 direcoes (as 8 principais + 8 intermediarias),
  para testar todos os octantes }
procedure TfrmRetas.Estrela(Sender: TObject);
const
  Cores: array[0..3] of TColor = ($0000FF, $00A000, $FF0000, $0080FF);
var
  cx, cy, i, R: Integer;
  a: Double;
begin
  cx := Area.Largura div 2;
  cy := Area.Altura div 2;
  R := 200;
  Area.Contagem := 0;
  for i := 0 to 15 do
  begin
    a := i * Pi / 8;
    Desenha(cx, cy, cx + Arred(R * Cos(a)), cy + Arred(R * Sin(a)), Cores[i mod 4]);
  end;
  Area.Info := Format('estrela: %d pixels plotados', [Area.Contagem]);
  Area.Atualizar;
end;

procedure TfrmRetas.Clicar(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if not TemP1 then
  begin
    eX1.Text := IntToStr(X); eY1.Text := IntToStr(Y);
    Area.Plot(X, Y, clGray); Area.Plot(X + 1, Y, clGray);
    Area.Plot(X, Y + 1, clGray); Area.Plot(X + 1, Y + 1, clGray);
    Area.Atualizar;
    TemP1 := True;
  end
  else
  begin
    eX2.Text := IntToStr(X); eY2.Text := IntToStr(Y);
    TemP1 := False;
    Desenhar(Sender);
  end;
end;

procedure TfrmRetas.AoLimpar(Sender: TObject);
begin
  TemP1 := False;
end;

end.

unit fCasinha;
{ ABA 7 - Aula 11/12/12A: transformacoes 3D e projecao paralela ortogonal
  (a "casinha"). Vetor linha [x y z 1] x matriz 4x4 (uMatriz.pas).
  Interface no estilo do slide 4 da Aula 12A: operacao + parametros + EXECUTA. }
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Graphics, Math,
  uCores, uUI, uAreaDesenho, uLinhas, uMatriz;

type
  TfrmCasinha = class(TFrame)
  private
    Area: TAreaDesenho;
    Op: TRadioGroup;
    Eixo: TRadioGroup;
    eSx, eSy, eSz, eS, eTx, eTy, eTz, eGraus: TEdit;
    Shear: array[0..3, 0..3] of TEdit;
    Obj: TListaPontos;          // objeto ATUAL (cumulativo)
    procedure Reiniciar;
    procedure Executa(Sender: TObject);
    procedure Reset(Sender: TObject);
    procedure Desenhar;
    function MatrizDaOperacao: TMat4;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.lfm}

const
  { 10 vertices: frente (z=0) e fundo (z=100) }
  Vert: array[0..9, 0..2] of Double = (
    (0, 0, 0), (100, 0, 0), (100, 100, 0), (50, 150, 0), (0, 100, 0),
    (0, 0, 100), (100, 0, 100), (100, 100, 100), (50, 150, 100), (0, 100, 100));
  { 15 arestas: pentagono da frente, do fundo e 5 ligacoes frente-fundo }
  Arest: array[0..14, 0..1] of Integer = (
    (0, 1), (1, 2), (2, 3), (3, 4), (4, 0),
    (5, 6), (6, 7), (7, 8), (8, 9), (9, 5),
    (0, 5), (1, 6), (2, 7), (3, 8), (4, 9));
  Escala = 2;     // pixels por unidade do mundo (tamanho da janela de visao)

constructor TfrmCasinha.Create(AOwner: TComponent);
var
  i, j: Integer;
begin
  inherited Create(AOwner);
  Area := TAreaDesenho.Create(Self, 640, 400, clWhite, 192);
  Area.Barra.Color := clBtnFace;

  Op := TRadioGroup.Create(Self);
  Op.Parent := Area.Barra;
  Op.SetBounds(4, 0, 175, 188);
  Op.Caption := 'Operacao';
  Op.Items.Text := 'Escala Local'#10'Escala Global'#10'Translacao'#10 +
                   'Rotacao (origem)'#10'Rotacao (centro)'#10'Shearing';
  Op.ItemIndex := 2;

  Rotulo(Area.Barra, 'Sx', 190, 10);  eSx := Campo(Area.Barra, '1', 214, 6, 44);
  Rotulo(Area.Barra, 'Sy', 264, 10);  eSy := Campo(Area.Barra, '1', 288, 6, 44);
  Rotulo(Area.Barra, 'Sz', 338, 10);  eSz := Campo(Area.Barra, '1', 362, 6, 44);
  Rotulo(Area.Barra, 's (global)', 190, 44); eS := Campo(Area.Barra, '1', 264, 40, 44);
  Rotulo(Area.Barra, 'Tx', 190, 78);  eTx := Campo(Area.Barra, '0', 214, 74, 44);
  Rotulo(Area.Barra, 'Ty', 264, 78);  eTy := Campo(Area.Barra, '0', 288, 74, 44);
  Rotulo(Area.Barra, 'Tz', 338, 78);  eTz := Campo(Area.Barra, '0', 362, 74, 44);

  Eixo := TRadioGroup.Create(Self);
  Eixo.Parent := Area.Barra;
  Eixo.SetBounds(190, 104, 150, 44);
  Eixo.Caption := 'Eixo';
  Eixo.Columns := 3;
  Eixo.Items.Text := 'X'#10'Y'#10'Z';
  Eixo.ItemIndex := 2;
  Rotulo(Area.Barra, 'graus', 350, 122); eGraus := Campo(Area.Barra, '30', 392, 118, 44);

  Rotulo(Area.Barra, 'Shearing (matriz 4x4):', 450, 4).Width := 180;
  for i := 0 to 3 do
    for j := 0 to 3 do
    begin
      Shear[i, j] := Campo(Area.Barra, '0', 450 + j * 52, 24 + i * 28, 48);
      if i = j then Shear[i, j].Text := '1';
    end;

  Botao(Area.Barra, 'EXECUTA', 190, 156, 110, @Executa);
  Botao(Area.Barra, 'Reset', 310, 156, 90, @Reset);
  Rotulo(Area.Barra, 's>1 reduz, s<1 amplia', 420, 162).Width := 200;

  Reiniciar;
end;

procedure TfrmCasinha.Reiniciar;
var
  i: Integer;
begin
  SetLength(Obj, 10);
  for i := 0 to 9 do
  begin
    Obj[i].x := Vert[i, 0];
    Obj[i].y := Vert[i, 1];
    Obj[i].z := Vert[i, 2];
  end;
  Desenhar;
end;

function TfrmCasinha.MatrizDaOperacao: TMat4;
var
  c: TPonto;
  i, j: Integer;
  s: Double;
begin
  Result := MatIdentidade;
  case Op.ItemIndex of
    0: Result := MatEscalaLocal(Flt(eSx, 1), Flt(eSy, 1), Flt(eSz, 1));
    1:
      begin
        s := Flt(eS, 1);
        if s <> 0 then Result := MatEscalaGlobal(s);   // s = 0 dividiria por zero
      end;
    2: Result := MatTranslacao(Flt(eTx), Flt(eTy), Flt(eTz));
    3: Result := MatRot(Chr(Ord('X') + Eixo.ItemIndex), Flt(eGraus));
    4:
      begin
        c := CentroMedio(Obj);       // centro = media dos vertices ATUAIS
        Result := MatRotCentro(Chr(Ord('X') + Eixo.ItemIndex), Flt(eGraus), c.x, c.y, c.z);
      end;
    5:
      for i := 0 to 3 do
        for j := 0 to 3 do
          Result[i, j] := Flt(Shear[i, j], Result[i, j]);
  end;
end;

procedure TfrmCasinha.Executa(Sender: TObject);
begin
  AplicaLista(Obj, MatrizDaOperacao);   // cumulativo: Obj := Obj . M
  Desenhar;
end;

procedure TfrmCasinha.Reset(Sender: TObject);
begin
  Reiniciar;
end;

{ Projecao paralela ortogonal em z = 0: descarta z, usa so x e y.
  Janela (mundo) -> porta de visao (pixels) pela Aula 13; y e invertido no fim
  porque na tela y cresce para baixo. A janela fica centrada no centro inicial
  da casinha (50,75), entao o objeto aparece centralizado. }
procedure TfrmCasinha.Desenhar;
var
  W, H: Integer;
  Xmin, Xmax, Ymin, Ymax: Double;
  i: Integer;
  c: TPonto;

  function PX(x: Double): Integer;
  begin
    Result := Arred(JanelaPorta(x, Xmin, Xmax, 0, W - 1));
  end;

  function PY(y: Double): Integer;
  begin
    Result := (H - 1) - Arred(JanelaPorta(y, Ymin, Ymax, 0, H - 1));
  end;

begin
  W := Area.Largura;
  H := Area.Altura;
  Xmin := 50 - W / (2 * Escala);  Xmax := 50 + W / (2 * Escala);
  Ymin := 75 - H / (2 * Escala);  Ymax := 75 + H / (2 * Escala);

  Area.Limpar;
  // eixos x e y (cinza) passando pela origem do mundo
  RetaBresenham(0, PY(0), W - 1, PY(0), $C0C0C0, @Area.Plot);
  RetaBresenham(PX(0), 0, PX(0), H - 1, $C0C0C0, @Area.Plot);
  // arestas com o Bresenham da aba 4
  for i := 0 to High(Arest) do
    RetaBresenham(PX(Obj[Arest[i, 0]].x), PY(Obj[Arest[i, 0]].y),
                  PX(Obj[Arest[i, 1]].x), PY(Obj[Arest[i, 1]].y),
                  clBlack, @Area.Plot);
  c := CentroMedio(Obj);
  Area.Info := Format('centro do objeto = (%.1f, %.1f, %.1f)', [c.x, c.y, c.z]);
  Area.Atualizar;
end;

end.

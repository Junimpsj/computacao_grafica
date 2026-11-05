unit fZBuffer;
{ ABA 10 - Aula 17: Z-Buffer.
  Fundo preto. Para cada ponto das superficies (apos a rotacao do usuario),
  projecao ortogonal em z = 0; so grava o pixel se z < zbuffer[x,y]
  (menor z = mais proximo, como no slide). Rotacao reaproveita uMatriz.pas. }
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Graphics, Math,
  uCores, uUI, uAreaDesenho, uMatriz, uZBuffer;

type
  TfrmZBuffer = class(TFrame)
  private
    Area: TAreaDesenho;
    Eixo: TRadioGroup;
    eGraus, eZoom: TEdit;
    Chk: array[1..NUM_OBJETOS] of TCheckBox;
    ZB: TZBuffer;
    M: TMat4;              // rotacao acumulada (vetor linha x matriz)
    k, k0: Double;         // k = escala atual (pixels por unidade); k0 = escala que cabe tudo
    cx, cy: Double;        // origem do mundo no centro da area
    procedure Emite(x, y, z: Double; c: TColor);
    procedure Renderiza;
    procedure Rotaciona(Sender: TObject);
    procedure Reset(Sender: TObject);
    procedure Zoom(Sender: TObject);
    procedure MudouObjeto(Sender: TObject);
    procedure AoLimpar(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{$R *.lfm}

const
  Nomes: array[1..NUM_OBJETOS] of string =
    ('1 azul z=x2+y', '2 verm. plano', '3 amar. cone', '4 verde esfera', '5 branco cubo');

constructor TfrmZBuffer.Create(AOwner: TComponent);
var
  i: Integer;
  Todos: array[0..NUM_OBJETOS - 1] of Boolean;
  R: Double;
begin
  inherited Create(AOwner);
  Area := TAreaDesenho.Create(Self, 640, 480, clBlack, 80);
  Area.OnLimpar := @AoLimpar;
  ZB := TZBuffer.Create(Area.Largura, Area.Altura, clBlack);

  for i := 1 to NUM_OBJETOS do
  begin
    Chk[i] := TCheckBox.Create(Self);
    Chk[i].Parent := Area.Barra;
    Chk[i].Caption := Nomes[i];
    Chk[i].SetBounds(4 + (i - 1) * 126, 4, 124, 22);
    Chk[i].Checked := True;
    Chk[i].OnChange := @MudouObjeto;
  end;

  Eixo := TRadioGroup.Create(Self);
  Eixo.Parent := Area.Barra;
  Eixo.SetBounds(4, 30, 170, 46);
  Eixo.Caption := 'Eixo (rotacao na origem)';
  Eixo.Columns := 3;
  Eixo.Items.Text := 'X'#10'Y'#10'Z';
  Eixo.ItemIndex := 1;
  Rotulo(Area.Barra, 'graus', 186, 46); eGraus := Campo(Area.Barra, '20', 228, 42, 50);
  Botao(Area.Barra, 'Rotaciona', 290, 38, 100, @Rotaciona);
  Botao(Area.Barra, 'Reset', 396, 38, 70, @Reset);
  Rotulo(Area.Barra, 'zoom', 486, 46); eZoom := Campo(Area.Barra, '1', 524, 42, 50);
  Botao(Area.Barra, 'Aplicar zoom', 584, 38, 110, @Zoom);

  // escala que faz TODOS os objetos caberem: o raio maximo em relacao a origem
  // nao muda com a rotacao, entao a escala e fixa e nada sai da tela
  for i := 0 to NUM_OBJETOS - 1 do Todos[i] := True;
  R := RaioMaximo(Todos);
  k0 := Min(Area.Largura, Area.Altura) / 2 * 0.95 / R;
  k := k0;
  cx := Area.Largura / 2;
  cy := Area.Altura / 2;

  M := MatIdentidade;
  Renderiza;
end;

destructor TfrmZBuffer.Destroy;
begin
  ZB.Free;
  inherited Destroy;
end;

{ chamado para cada ponto 3D amostrado }
procedure TfrmZBuffer.Emite(x, y, z: Double; c: TColor);
var
  p: TPonto;
begin
  p.x := x; p.y := y; p.z := z;
  p := AplicaPonto(p, M);                       // rotacao
  // projecao ortogonal em z=0: ignora z na posicao; y para cima (tela para baixo)
  ZB.Ponto(Round(cx + p.x * k), Round(cy - p.y * k), p.z, c);
end;

procedure TfrmZBuffer.Renderiza;
var
  n: Integer;
begin
  ZB.Limpar(clBlack);                           // zbuffer = maior valor possivel
  for n := 1 to NUM_OBJETOS do
    if Chk[n].Checked then
      GeraObjeto(n, 0.6 / k, @Emite);           // passo <= 0.6 pixel: sem buracos
  Area.Colar(ZB.Cor, Area.Largura, Area.Altura);
end;

procedure TfrmZBuffer.Rotaciona(Sender: TObject);
begin
  M := MatMul(M, MatRot(Chr(Ord('X') + Eixo.ItemIndex), Flt(eGraus)));
  Renderiza;
end;

procedure TfrmZBuffer.Reset(Sender: TObject);
begin
  M := MatIdentidade;
  Renderiza;
end;

procedure TfrmZBuffer.Zoom(Sender: TObject);
var
  z: Double;
begin
  z := Flt(eZoom, 1);
  if z <= 0 then z := 1;
  k := k0 * z;           // zoom > 1 pode cortar objetos nas bordas da tela
  Renderiza;
end;

procedure TfrmZBuffer.MudouObjeto(Sender: TObject);
begin
  Renderiza;
end;

procedure TfrmZBuffer.AoLimpar(Sender: TObject);
begin
  ZB.Limpar(clBlack);       // tela preta; "Rotaciona" ou "Reset" redesenha
end;

end.

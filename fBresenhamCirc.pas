unit fBresenhamCirc;
{ ABA 6 - Aula 08: Bresenham para circunferencias (2a ordem + simetria de 8,
  e a versao de 1a ordem para comparacao). Herda a interface da aba 5. }
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Graphics, uCores, uCirculos, fCirculos;

type
  TfrmBresenhamCirc = class(TfrmCirculos)
  protected
    class function Itens: string; override;
    class function ComExtras: Boolean; override;
    procedure Desenha(xc, yc, R: Integer; cor: TColor); override;
  end;

implementation

{$R *.lfm}

class function TfrmBresenhamCirc.Itens: string;
begin
  Result := 'Bresenham 2a ordem (dE, dSE)'#10'Bresenham 1a ordem';
end;

class function TfrmBresenhamCirc.ComExtras: Boolean;
begin
  Result := False;
end;

procedure TfrmBresenhamCirc.Desenha(xc, yc, R: Integer; cor: TColor);
begin
  if Metodo.ItemIndex = 0 then
    CircBresenham(xc, yc, R, cor, @Area.Plot)
  else
    CircBresenham1(xc, yc, R, cor, @Area.Plot);
end;

end.

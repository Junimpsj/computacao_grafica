unit fBresenham;
{ ABA 4 - Aula 06: Bresenham para retas em todos os octantes.
  Reaproveita a interface da aba 3 (heranca de frame); so troca o metodo. }
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Graphics, uCores, uLinhas, fRetas;

type
  TfrmBresenham = class(TfrmRetas)
  protected
    class function Itens: string; override;
    procedure Desenha(x1, y1, x2, y2: Integer; cor: TColor); override;
  end;

implementation

{$R *.lfm}

class function TfrmBresenham.Itens: string;
begin
  Result := 'Bresenham (inteiros, 8 octantes)';
end;

procedure TfrmBresenham.Desenha(x1, y1, x2, y2: Integer; cor: TColor);
begin
  RetaBresenham(x1, y1, x2, y2, cor, @Area.Plot);
end;

end.

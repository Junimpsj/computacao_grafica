unit uUI;
{ Pequenos auxiliares para montar controles por codigo (posicao absoluta). }
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, ExtCtrls;

function Rotulo(Pai: TWinControl; const Txt: string; L, T: Integer): TLabel;
function Campo(Pai: TWinControl; const Txt: string; L, T, W: Integer): TEdit;
function Botao(Pai: TWinControl; const Txt: string; L, T, W: Integer;
  OnClk: TNotifyEvent): TButton;
{ le um real aceitando ponto ou virgula decimal }
function Flt(e: TEdit; Padrao: Double = 0): Double;

implementation

function Rotulo(Pai: TWinControl; const Txt: string; L, T: Integer): TLabel;
begin
  Result := TLabel.Create(Pai.Owner);
  Result.Parent := Pai;
  Result.Caption := Txt;
  Result.SetBounds(L, T, 60, 17);
end;

function Campo(Pai: TWinControl; const Txt: string; L, T, W: Integer): TEdit;
begin
  Result := TEdit.Create(Pai.Owner);
  Result.Parent := Pai;
  Result.Text := Txt;
  Result.SetBounds(L, T, W, 23);
end;

function Botao(Pai: TWinControl; const Txt: string; L, T, W: Integer;
  OnClk: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Pai.Owner);
  Result.Parent := Pai;
  Result.Caption := Txt;
  Result.SetBounds(L, T, W, 27);
  Result.OnClick := OnClk;
end;

function Flt(e: TEdit; Padrao: Double): Double;
var
  t: string;
begin
  t := Trim(e.Text);
  t := StringReplace(t, ',', DefaultFormatSettings.DecimalSeparator, []);
  t := StringReplace(t, '.', DefaultFormatSettings.DecimalSeparator, []);
  Result := StrToFloatDef(t, Padrao);
end;

end.

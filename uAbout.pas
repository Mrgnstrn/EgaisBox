unit uAbout;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.pngimage, Vcl.ExtCtrls,
  Vcl.StdCtrls, ShellApi;

type
  TfrmAbout = class(TForm)
    Label2: TLabel;
    lblStatus: TLabel;
    Image1: TImage;
    lblVersion: TLabel;
    memoChanges: TMemo;
    procedure LinkLabel1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmAbout: TfrmAbout;

implementation
uses uUpdater,uLogic;
{$R *.dfm}

procedure TfrmAbout.FormCreate(Sender: TObject);
begin
try
    lblVersion.Caption:= 'Версия: ' + TUpdater.GetCurrentVersion;
    if FileExists(strChangesListFile) then
        memoChanges.Lines.LoadFromFile(strChangesListFile)
    else begin
        memoChanges.Hide;
        Self.Height:= Self.Height - memoChanges.Height;
    end;
    lblStatus.Caption:= 'Незарегистрированная копия' + CrLf + 'Без ограничений';

finally

end;
end;

procedure TfrmAbout.LinkLabel1Click(Sender: TObject);
begin
    ShellExecute(handle,'open','http://egaisbox.ru',nil,nil,SW_SHOW);
end;

end.

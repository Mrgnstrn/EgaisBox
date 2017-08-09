unit uWBrequest;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmWBrequest = class(TForm)
    Label1: TLabel;
    Image1: TImage;
    txtWBIdentifier: TEdit;
    Label2: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure txtWBIdentifierChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmWBrequest: TfrmWBrequest;

implementation

{$R *.dfm}


procedure TfrmWBrequest.txtWBIdentifierChange(Sender: TObject);
begin
    btnOK.Enabled:= (Length(txtWBIdentifier.Text) = 10);
end;

end.

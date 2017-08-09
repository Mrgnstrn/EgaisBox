unit uFilter;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  uTypes;

type
  TfrmFilter = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    dtpStart: TDateTimePicker;
    dtpEnd: TDateTimePicker;
    btnResetFilter: TButton;
    btnOK: TButton;
    btnCancel: TButton;
    chkInbox: TCheckBox;
    chkAllDocuments: TCheckBox;
    chkOutbox: TCheckBox;
    constructor Create(AOwner: TComponent; tempFilter: TViewDocumentsFilter); reintroduce;
    procedure btnResetFilterClick(Sender: TObject);
    procedure chkAllDocumentsClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure chkOutboxClick(Sender: TObject);
    procedure chkInboxClick(Sender: TObject);
  private
    fFilter: TViewDocumentsFilter;
    procedure ReadFilter();
    procedure WriteFilter();
  public
    { Public declarations }
  end;

var
  frmFilter: TfrmFilter;

implementation

{$R *.dfm}

procedure TfrmFilter.btnResetFilterClick(Sender: TObject);
begin
    fFilter.Free;
    fFilter:= TViewDocumentsFilter.Create();
    ReadFilter();
end;

procedure TfrmFilter.btnOKClick(Sender: TObject);
begin
    WriteFilter();
end;

procedure TfrmFilter.chkAllDocumentsClick(Sender: TObject);
begin
    chkInbox.Enabled:= not chkAllDocuments.Checked;
    chkOutbox.Enabled:= not chkAllDocuments.Checked;
    if chkAllDocuments.Checked then begin
        chkInbox.Checked:= true;
        chkOutbox.Checked:=true;
    end else begin
        chkInbox.Checked:= true;
        chkOutbox.Checked:=false;
    end;

end;


procedure TfrmFilter.chkInboxClick(Sender: TObject);
begin
    btnOK.Enabled:= chkInbox.Checked or
        chkOutbox.Checked;
    if chkInbox.Checked and chkOutbox.Checked then
        chkAllDocuments.Checked:= True
end;

procedure TfrmFilter.chkOutboxClick(Sender: TObject);
begin
    btnOK.Enabled:= chkInbox.Checked or
        chkOutbox.Checked;
    if chkInbox.Checked and chkOutbox.Checked then
        chkAllDocuments.Checked:= True
end;

constructor TfrmFilter.Create(AOwner: TComponent; tempFilter: TViewDocumentsFilter);
begin
    inherited Create(AOwner);
    fFilter:= tempFilter;
    ReadFilter();
end;

procedure TfrmFilter.ReadFilter();
begin
    chkAllDocuments.Checked:= False;
    dtpStart.Date:= fFilter.DateStart;
    dtpEnd.Date:= fFilter.DateEnd;
    chkInbox.Checked:= fFilter.Inbox;
    chkOutbox.Checked:= fFilter.Outbox;

    if chkInbox.Checked and chkOutbox.Checked then
   chkAllDocuments.Checked:= True
end;

procedure TfrmFilter.WriteFilter();
begin
    fFilter.DateStart:= dtpStart.Date;
    fFilter.DateEnd:= dtpEnd.Date;
    fFilter.Inbox:= chkInbox.Checked;
    fFilter.Outbox:= chkOutbox.Checked;
end;

end.

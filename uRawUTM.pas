unit uRawUTM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, System.ImageList, Vcl.ImgList, Vcl.ToolWin,
  Generics.Collections, Generics.Defaults, ShellAPI;

type
  TfrmRawUTM = class(TForm)
    lvRawUTM: TListView;
    tbRawUTM: TToolBar;
    imlToolBar: TImageList;
    tbtnInbox: TToolButton;
    tbtnOutbox: TToolButton;
    tbtnDelete: TToolButton;
    tbtnDivider: TToolButton;
    tbtnDeleteByReplyID: TToolButton;
    imlLeds: TImageList;
    tbtnView: TToolButton;
    ToolButton1: TToolButton;
    procedure LoadLists();
    //procedure LoadInboxList();
    //procedure LoadOutboxList();
    procedure FormCreate(Sender: TObject);
    procedure tbtnOutboxClick(Sender: TObject);
    procedure tbtnInboxClick(Sender: TObject);
    procedure lvRawUTMResize(Sender: TObject);
    procedure tbtnDeleteClick(Sender: TObject);
    procedure tbtnDeleteByReplyIDClick(Sender: TObject);
    procedure lvRawUTMDblClick(Sender: TObject);
    procedure tbtnViewClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmRawUTM: TfrmRawUTM;

implementation
uses uUTM, uLogic;

{$R *.dfm}

procedure TfrmRawUTM.FormCreate(Sender: TObject);
begin
    LoadLists();
end;

procedure TfrmRawUTM.LoadLists();
var
    FileList: TList<TUTMstring>;
    UTMstr: TUTMstring;
    lvItem: TListItem;
begin
    if CheckUTMServer = False then begin
        Self.Caption := 'Списки УТМ [Транспортный модуль недоступен]';
        Exit;
    end;

    if tbtnInbox.Down then begin
        FileList:= GetInboxFileList();
        Self.Caption := 'Списки УТМ [Входящие файлы]';
    end else begin
        FileList:= GetOutboxFileList();
        Self.Caption := 'Списки УТМ [Исходящие файлы]';
    end;

    LockWindowUpdate(lvRawUTM.Handle);
    lvRawUTM.Clear;
    for UTMstr in FileList do begin
        lvItem:= lvRawUTM.Items.Add;
        lvItem.ImageIndex := Ord(GetUrlAddressType(UTMstr.Url));
        lvItem.Caption := UTMstr.Url;
        lvItem.SubItems.Add(UTMstr.ReplyID);
    end;
    LockWindowUpdate(0);
end;

procedure TfrmRawUTM.lvRawUTMDblClick(Sender: TObject);
var
    FileName: String;
begin
    if lvRawUTM.Selected = nil then begin
        MessageBox(Self.Handle, PWideChar('Нет выделенной строки'),
                    PWideChar('Просмотр файла'), MB_ICONINFORMATION);
        Exit;
    end;
    ClearFolder(strInboxFolder);
    FileName := 'Temp_' + GenerateGUID() + '.xml';
    LoadFileFromUTM(lvRawUTM.Selected.Caption, FileName);
    ShellExecute(Application.Handle, 'open', PWideChar(strInboxFolder + FileName), nil, nil, SW_NORMAL );
end;

procedure TfrmRawUTM.lvRawUTMResize(Sender: TObject);
begin
//    lvRawUTM.Columns[0].Width := lvRawUTM.Width div 2;
//    lvRawUTM.Columns[1].Width := lvRawUTM.Width div 2 - 20;
end;

procedure TfrmRawUTM.tbtnDeleteByReplyIDClick(Sender: TObject);
var
    Index: integer;
begin
    if MessageBox(Self.Handle, PWideChar('Удалить отмеченные объекты и все связанные по ReplyID?'),
                    PWideChar('Удаление по ReplyID'), MB_YESNO + MB_DEFBUTTON2 + MB_ICONWARNING) = mrNo then Exit;

    for Index := 0 to lvRawUTM.Items.Count - 1 do
    begin
        if lvRawUTM.Items[Index].Checked = True then
            DeleteUTMobjectByReplyId(lvRawUTM.Items[Index].SubItems[0]);
    end;
    LoadLists;
end;

procedure TfrmRawUTM.tbtnDeleteClick(Sender: TObject);
var
    Index: integer;
begin
    if MessageBox(Self.Handle, PWideChar('Удалить отмеченные объекты из УТМ?'),
                    PWideChar('Удаление'), MB_YESNO + MB_DEFBUTTON2 + MB_ICONWARNING) = mrNo then Exit;

    for Index := 0 to lvRawUTM.Items.Count - 1 do
    begin
        if lvRawUTM.Items[Index].Checked = True then
            DeleteUTMobject(lvRawUTM.Items[Index].Caption);
    end;
    LoadLists;
end;

procedure TfrmRawUTM.tbtnInboxClick(Sender: TObject);
begin
    tbtnOutbox.Down := False;
    if tbtnInbox.Down = True then begin
        LoadLists;
        Self.Resize;
    end else
        tbtnInbox.Down := True;

end;

procedure TfrmRawUTM.tbtnOutboxClick(Sender: TObject);
begin
    //if tbtnOutbox.Down = False then Exit;
    tbtnInbox.Down := False;
    if tbtnOutbox.Down = True then begin
        LoadLists;
        Self.Resize;
    end else
        tbtnOutbox.Down := True;
end;

procedure TfrmRawUTM.tbtnViewClick(Sender: TObject);
begin
    lvRawUTMDblClick(nil);
end;

end.

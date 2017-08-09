unit uActEdit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  System.ImageList, Vcl.ImgList, Vcl.Imaging.pngimage, Vcl.ExtCtrls,
  commctrl,
  uDocument, Vcl.Samples.Spin;

type
  TfrmActEdit = class(TForm)
    Label1: TLabel;
    lvContent: TListView;
    btnCancel: TButton;
    btnOK: TButton;
    Image1: TImage;
    imlWBviewTables: TImageList;
    txtEdit: TSpinEdit;
    constructor Create(AOwner: TComponent; Doc: TEgaisDocument); reintroduce;
    procedure FillData();
    procedure FormResize(Sender: TObject);
    procedure lvContentMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure txtEditChange(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    fDoc: TEgaisDocument;
    { Private declarations }
  public
    { Public declarations }
  end;

var
    frmActEdit: TfrmActEdit;
    Item:TListItem;
    Sub:Integer;

implementation

{$R *.dfm}

uses uTypes, uLog, uLogic;

procedure TfrmActEdit.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    if Self.ModalResult = mrCancel then
        CanClose:=(MessageBox(Self.Handle, PWideChar('Хотите отменить ввод акта расхождений'), PWideChar('Отмена'), MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) = mrYes)
end;

procedure TfrmActEdit.FormKeyPress(Sender: TObject; var Key: Char);
begin

if Ord(key) = 27 then
    if txtEdit.Visible = True then
        txtEdit.Visible:=False
    else
        Self.ModalResult:= mrCancel;
end;

procedure TfrmActEdit.FormResize(Sender: TObject);
begin
    //Resize Content
    txtEdit.Visible:=False;
    LockWindowUpdate(lvContent.Handle);
    lvContent.Columns[0].Width := lvContent.Width div 10;
    lvContent.Columns[1].Width := (lvContent.Width div 10) * 5 - 25;
    lvContent.Columns[2].Width := lvContent.Width div 10;
    lvContent.Columns[3].Width := lvContent.Width div 10;
    lvContent.Columns[4].Width := lvContent.Width div 10;
    lvContent.Columns[5].Width := lvContent.Width div 10;
    //lvContent.Columns[6].Width := lvContent.Width div 10;

    LockWindowUpdate(0);
end;

procedure TfrmActEdit.btnCancelClick(Sender: TObject);
begin
    Self.ModalResult:= mrCancel;
end;

procedure TfrmActEdit.btnOKClick(Sender: TObject);
var
    index: integer;
    flag: Boolean;
begin
    flag:= false;
    if MessageBox(Self.Handle, PWideChar('Отправить акт расхождения?'), PWideChar('Отправка'), MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) = mrNo then Exit;
    for index := 0 to fDoc.Content.Count - 1 do begin
        if QuantityToInt(fDoc.Content.Items[index].RealQuantity) <>
           QuantityToInt(lvContent.Items[index].SubItems[4]) then Flag:= True;

        fDoc.Content.Items[index].RealQuantity := lvContent.Items[index].SubItems[4];
    end;

    if not flag then begin
        MessageBox(Self.Handle, PWideChar('Не найдено измененных строк. Отправка акта отменена.'), PWideChar('Отправка'), MB_ICONWARNING + MB_OK);
        Exit;
    end;

    Self.ModalResult:= mrOk;

end;

procedure TfrmActEdit.lvContentMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
    R:TRect;
    ht:TLVHitTestInfo;
begin
        Item := lvContent.GetItemAt(2, Y);
        txtEdit.Visible:=False;
        if Item=nil then Exit;
        FillChar(ht,SizeOf(ht),0);
        ht.pt.x:=X;
        ht.pt.y:=Y;
        SendMessage(lvContent.Handle, LVM_SUBITEMHITTEST, 0, Integer(@ht));
        Sub:=ht.iSubItem;
        if Sub = 5 then begin
            ListView_GetSubItemRect(lvContent.Handle, Item.Index, Sub,LVIR_BOUNDS, @R);
            Offsetrect(R,lvContent.Left,lvContent.Top);
            txtEdit.SetBounds(R.Left ,R.Top -3,R.Right-R.Left + 8,R.Bottom-R.Top + 5);
            Dec(Sub);
            txtEdit.Text:=Item.SubItems[Sub];
            txtEdit.Visible:=True;
            txtEdit.MaxValue:= QuantityToInt(Item.SubItems[3]);
            txtEdit.MinValue:= 0;
        end;
end;

procedure TfrmActEdit.txtEditChange(Sender: TObject);
begin
    Item.SubItems[4]:= IntToStr(QuantityToInt(txtEdit.Text));
    if QuantityToInt(Item.SubItems[4]) <> QuantityToInt(Item.SubItems[3]) then
        Item.SubItemImages[4]:= 3
    else
        Item.SubItemImages[4]:= -1;

end;

constructor TfrmActEdit.Create(AOwner: TComponent; Doc: TEgaisDocument);
begin
    inherited Create(AOwner);
    log(Doc.Content.Count);
    fDoc:= Doc;
    Self.Caption:= Self.Caption + ' - ' + Doc.Shipper.ShortName + ' [' +Doc.ClientNumber + ']';
    FillData();
end;

procedure TfrmActEdit.FillData();

procedure AddContentItem(Position: TPositionType);
var lvItem: TListItem;
begin
    lvItem:= lvContent.Items.Add;
    lvItem.ImageIndex:=1;
    lvItem.Caption:= Position.Identity;
    lvItem.SubItems.Add(Position.Product.FullName);
    lvItem.SubItems.Add(Position.Product.Capacity);
    lvItem.SubItems.Add(Position.Product.AlcVolume);
    lvItem.SubItems.Add(IntToStr(QuantityToInt(Position.Quantity)));
    lvItem.SubItems.Add(Position.RealQuantity);
end;

var
    Position: TPositionType;
begin

    for Position in fDoc.Content do begin
        AddContentItem(Position);
    end;

end;

end.

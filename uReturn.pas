unit uReturn;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  System.ImageList, Vcl.ImgList, Vcl.Imaging.pngimage, Vcl.ExtCtrls,
  commctrl, uDocument, Vcl.Samples.Spin, Vcl.Buttons, uTypes;


type TListView = class(Vcl.ComCtrls.TListView)
    protected
        procedure WndProc(var Message: TMessage); override;
    end;
type
  TfrmReturn = class(TForm)
    pcWBview: TPageControl;
    TabSheet1: TTabSheet;
    lvData: TListView;
    TabSheet2: TTabSheet;
    lvContent: TListView;
    TabSheet3: TTabSheet;
    lvInform: TListView;
    pnlUp: TPanel;
    GroupBox2: TGroupBox;
    lblConsigneeFullName: TLabel;
    lblConsigneeINNKPP: TLabel;
    lblConsigneeAddress: TLabel;
    lblConsigneeFSRARID: TLabel;
    GroupBox1: TGroupBox;
    lblShipperFullName: TLabel;
    lblShipperINNKPP: TLabel;
    lblShipperAddress: TLabel;
    lblShipperFSRARID: TLabel;
    btnSendReturn: TButton;
    btnCancel: TButton;
    imlWBviewTables: TImageList;
    imlWBviewPages: TImageList;
    imlToolBar: TImageList;
    txtEdit: TSpinEdit;
    dtReturnDate: TDateTimePicker;
    Label1: TLabel;
    Label2: TLabel;
    txtReturnDocNumber: TEdit;
    constructor Create(AOwner: TComponent; Doc: TEgaisDocument); reintroduce;
    procedure btnCancelClick(Sender: TObject);
    procedure btnSendReturnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure lvContentMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure txtEditChange(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure lvContentResize(Sender: TObject);
    procedure txtEditExit(Sender: TObject);
  private
    fDoc: TEgaisDocument;
    procedure FillData;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmReturn: TfrmReturn;
  Item:TListItem;
  Sub:Integer;

implementation

{$R *.dfm}
uses uLog, uLogic;

procedure TListView.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    WM_HSCROLL, WM_VSCROLL: frmReturn.txtEdit.Visible:=false;
  end;
end;

procedure TfrmReturn.btnSendReturnClick(Sender: TObject);
var
    index: integer;
    flag: integer;
begin
    flag:= 0;
    for index := 0 to (lvContent.Items.Count - 1) do
        if QuantityToInt(lvContent.Items[index].SubItems[4]) <> 0 then inc(flag);

    if Trim(txtReturnDocNumber.Text) <> '' then fDoc.ClientNumber := Trim(txtReturnDocNumber.Text);
    if dtReturnDate.Date <> Date() then begin
        fDoc.DocumentDate:= dtReturnDate.Date;
        fDoc.ShippingDate:= dtReturnDate.Date;
    end;


    if flag = 0 then begin
        MessageBox(Self.Handle, PWideChar('Ни в одной строке не отмечено количество для возврата . Невозможно отправить возврат.'), PWideChar('Ошибка'), MB_ICONWARNING + MB_OK);
        Exit;
    end else if MessageBox(Self.Handle, PWideChar('Выбрано ' + IntToStr(flag) + ' позиций для возврата. Отправить возвратную накладную?'), PWideChar('Отправка'), MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) = mrNo then
        Exit;

    //Удаляем лишние строчки и устанавливаем количество
    for index := (lvContent.Items.Count - 1) downto 0 do
        if QuantityToInt(lvContent.Items[index].SubItems[4]) = 0 then
            fDoc.Content.Delete(index)
        else
            fDoc.Content.Items[index].Quantity:= lvContent.Items[index].SubItems[4];
    log(fDoc.Content.Count);
    Self.ModalResult:= mrOk;

end;

procedure TfrmReturn.btnCancelClick(Sender: TObject);
begin
    Self.ModalResult:=mrCancel;
end;

procedure TfrmReturn.FillData();
procedure AddDataItem(Parameter: String; Value: string);
var lvItem: TListItem;
begin
    lvItem:= lvData.Items.Add;
    lvItem.ImageIndex:= 0;
    lvItem.Caption:= Parameter;
    lvItem.SubItems.Add(Value);
end;

procedure AddContentItem(Position: TPositionType);
var lvItem: TListItem;
begin
    lvItem:= lvContent.Items.Add;
    lvItem.ImageIndex:= 1;
    lvItem.Caption:= Position.Product.FullName;
    lvItem.SubItems.Add(Position.Product.Capacity);
    lvItem.SubItems.Add(Position.Product.AlcVolume);
    lvItem.SubItems.Add(Position.Price);
    lvItem.SubItems.Add(IntToStr(QuantityToInt(Position.Quantity)));
    lvItem.SubItems.Add('');
end;

procedure AddInformItem(Position: TPositionType);
var lvItem: TListItem;
begin
    lvItem:= lvInform.Items.Add;
    lvItem.ImageIndex:= 2;
    lvItem.Caption:= Position.Product.FullName;
    lvItem.SubItems.Add(Position.InformA);
    lvItem.SubItems.Add(Position.NewInformB);
    lvItem.SubItems.Add(Position.InformB);

end;

var
    Position: TPositionType;
    Sum, Count, Cap: Currency;
begin
    lblShipperFullName.Caption      := fDoc.Shipper.FullName;
    lblShipperINNKPP.Caption        := 'ИНН/КПП: ' + fDoc.Shipper.INN + '/' + fDoc.Shipper.KPP;
    lblShipperFSRARID.Caption       := 'FSRARID: ' + fDoc.Shipper.ClientRegId;
    lblShipperAddress.Caption       := 'Адрес: ' + fDoc.Shipper.Address.Description;
    lblConsigneeFullName.Caption    := fDoc.Consignee.FullName;
    lblConsigneeINNKPP.Caption      := 'ИНН/КПП: ' + fDoc.Consignee.INN + '/' + fDoc.Consignee.KPP;
    lblConsigneeFSRARID.Caption     := 'FSRARID: ' + fDoc.Consignee.ClientRegId;
    lblConsigneeAddress.Caption     := 'Адрес: ' + fDoc.Consignee.Address.Description;

    AddDataItem('Тип документа', TEgaisDocument.GetHumanityDocTypeName(Ord(fDoc.DocumentType)) + ' [' + eWayBillTTNTypes[fDoc.TTNType] + ']');
    //AddDataItem('Статус документа', TEgaisDocument.GetHumanityStatusName(Ord(fDoc.DocumentStatus)));
    AddDataItem('Номер ТТН', fDoc.ClientNumber);
    AddDataItem('Дата накладной', DateToStr(fDoc.DocumentDate));
    //AddDataItem('Идентификатор ТТН в ЕГАИС', fDoc.REGINFO.WBRegId);
    //AddDataItem('Номер / дата фиксации в ЕГАИС', fDoc.REGINFO.FixNumber + ' / ' + DateToStr(fDoc.REGINFO.FixDate));
    //AddDataItem('Номер фиксации в ЕГАИС', fDoc.REGINFO.FixNumber);
    AddDataItem('Идентификатор поставщика', fDoc.Identity);
    //AddDataItem('Примечание системы', fDoc.SystemComment);

    Sum := 0;
    Count := 0;
    Cap := 0;
    FormatSettings.DecimalSeparator := '.';
    for Position in fDoc.Content do begin
        AddContentItem(Position);
        AddInformItem(Position);
        Sum := Sum + StrToCurr(Position.Price) * StrToCurr(Position.Quantity);
        Count := Count + StrToCurr(Position.Quantity);
        if Position.Product.Capacity = '' then
            Cap := Cap + StrToCurr(Position.Quantity) * 10
        else
            Cap := Cap + StrToCurr(Position.Product.Capacity) * StrToCurr(Position.Quantity);
    end;
    //AddSummItem(Sum, Count, Cap);

end;

procedure TfrmReturn.FormResize(Sender: TObject);
var wWidth: Integer;
begin
    //Resize Content
    //LockWindowUpdate(lvContent.Handle);
    wWidth:= lvContent.Width - 30;
    lvContent.Columns[0].Width := (wWidth div 2);
    lvContent.Columns[1].Width := wWidth div 10;
    lvContent.Columns[2].Width := wWidth div 10;
    lvContent.Columns[3].Width := wWidth div 10;
    lvContent.Columns[4].Width := wWidth div 10;
    lvContent.Columns[5].Width := wWidth div 10;

    lvInform.Columns[0].Width := (wWidth div 2);
    lvInform.Columns[1].Width := wWidth div 6;
    lvInform.Columns[2].Width := wWidth div 6;
    lvInform.Columns[3].Width := wWidth div 6;

    //LockWindowUpdate(0);
end;

procedure TfrmReturn.lvContentMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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
            ListView_GetSubItemRect(lvContent.Handle, Item.Index, Sub, LVIR_BOUNDS, @R);
            Offsetrect(R,lvContent.Left,lvContent.Top);
            txtEdit.SetBounds(R.Left ,R.Top -3,R.Right-R.Left + 8,R.Bottom-R.Top + 5);
            Dec(Sub);
            txtEdit.Text:=IntToStr(QuantityToInt(Item.SubItems[4]));
            txtEdit.Visible:=True;
            txtEdit.MaxValue:= QuantityToInt(Item.SubItems[3]);
            txtEdit.MinValue:= 0;
        end;
end;

procedure TfrmReturn.lvContentResize(Sender: TObject);
begin
txtEdit.Visible:= False;
end;

procedure TfrmReturn.txtEditChange(Sender: TObject);
begin
    if QuantityToInt(txtEdit.Text) = 0 then begin
         Item.SubItems[4]:= '';
         Item.SubItemImages[4]:= -1;
    end else begin
        Item.SubItems[4]:= IntToStr(QuantityToInt(txtEdit.Text));
        Item.SubItemImages[4]:= 3
    end

end;

procedure TfrmReturn.txtEditExit(Sender: TObject);
begin
txtEdit.Visible:= False;
end;

constructor TfrmReturn.Create(AOwner: TComponent; Doc: TEgaisDocument);
begin
    inherited Create(AOwner);
    fDoc:= Doc;
    Self.Caption:= Self.Caption + ' - ' + Doc.Shipper.ShortName + ' [' +Doc.ClientNumber + '] ';
    txtReturnDocNumber.Text:= fDoc.ClientNumber;
    dtReturnDate.Date:= Date();

    FillData();
end;

procedure TfrmReturn.FormCreate(Sender: TObject);
begin
    SetWindowLongPtr(pnlUp.Handle, GWL_EXSTYLE,
    GetWindowLongPtr(pnlUp.Handle, GWL_EXSTYLE) or WS_EX_COMPOSITED);
end;

procedure TfrmReturn.FormKeyPress(Sender: TObject; var Key: Char);
begin

if Ord(key) = 27 then
    if txtEdit.Visible = True then
        txtEdit.Visible:=False
    else
        Self.ModalResult:=mrCancel;
end;

procedure TfrmReturn.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    if Self.ModalResult = mrCancel then
        CanClose:= (MessageBox(Self.Handle, PWideChar('Хотите отменить ввод возвратной накладной?'), PWideChar('Отмена'), MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) = mrYes);

end;

end.

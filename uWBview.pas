unit uWBview;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  uDocument, uTypes, System.ImageList, Vcl.ImgList, Vcl.Buttons, StrUtils;

type
  TfrmWBview = class(TForm)
    pnlUp: TPanel;
    GroupBox2: TGroupBox;
    lblConsigneeFullName: TLabel;
    lblConsigneeINNKPP: TLabel;
    lblConsigneeAddress: TLabel;
    GroupBox1: TGroupBox;
    lblShipperFullName: TLabel;
    lblShipperINNKPP: TLabel;
    lblShipperAddress: TLabel;
    pcWBview: TPageControl;
    TabSheet1: TTabSheet;
    lvData: TListView;
    TabSheet2: TTabSheet;
    lvContent: TListView;
    TabSheet3: TTabSheet;
    lvInform: TListView;
    btnActAcept: TButton;
    btnActEdit: TButton;
    btnActReject: TButton;
    btnClose: TButton;
    imlWBviewPages: TImageList;
    TabSheet4: TTabSheet;
    lblConsigneeFSRARID: TLabel;
    lblShipperFSRARID: TLabel;
    imlWBviewTables: TImageList;
    lvTransport: TListView;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    btnReturn: TButton;
    constructor Create(AOwner: TComponent; Doc: TEgaisDocument); reintroduce;
    procedure FillData();
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure lvContentClick(Sender: TObject);
    procedure lvInformClick(Sender: TObject);
    procedure btnActAceptClick(Sender: TObject);
    procedure btnActEditClick(Sender: TObject);
    procedure btnActRejectClick(Sender: TObject);
    procedure btnReturnClick(Sender: TObject);
  private
    fDoc: TEgaisDocument;

    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmWBview: TfrmWBview;

implementation

{$R *.dfm}
uses uLog, uLogic;

procedure TfrmWBview.btnActAceptClick(Sender: TObject);
begin
    if MessageBox(Self.Handle, PWideChar('Подтверждаем накладную поставщику?'), PWideChar('Подтверждение'), MB_OKCANCEL + MB_ICONQUESTION + MB_DEFBUTTON2) = mrCancel then Exit;

    Self.ModalResult:= mrYesToAll;
end;

procedure TfrmWBview.btnActEditClick(Sender: TObject);
begin
    Self.ModalResult:= mrNoToAll;
end;

procedure TfrmWBview.btnActRejectClick(Sender: TObject);
begin
    if MessageBox(Self.Handle, PWideChar('Вы уверены, что хотите отказаться от накладной?'), PWideChar('Отказ'), MB_OKCANCEL + MB_ICONQUESTION + MB_DEFBUTTON2) = mrCancel then Exit;

    Self.ModalResult:= mrNo;
end;

procedure TfrmWBview.btnCloseClick(Sender: TObject);
begin
    Self.Close;
end;

procedure TfrmWBview.btnReturnClick(Sender: TObject);
begin
    if MessageBox(Self.Handle, PWideChar('Оформить возврат на основании этой накладной?'), PWideChar('Возврат...'), MB_OKCANCEL + MB_ICONQUESTION + MB_DEFBUTTON2) = mrCancel then Exit;

    Self.ModalResult:= mrRetry;
end;

constructor TfrmWBview.Create(AOwner: TComponent; Doc: TEgaisDocument);
begin
    inherited Create(AOwner);
    fDoc:= Doc;
    if (fDoc.DocumentType = edtOutbox) and (fDoc.TTNType = IndexStr('WBReturnFromMe', eWayBillTTNTypes)) then
        Self.Caption:= 'Возврат: ' + Doc.Shipper.ShortName + ' [' +Doc.ClientNumber + '] : ' + TEgaisDocument.GetHumanityStatusName(Ord(Doc.DocumentStatus))
    else if (fDoc.DocumentType = edtInbox) and (fDoc.TTNType = IndexStr('WBInvoiceFromMe', eWayBillTTNTypes)) then
        Self.Caption:= 'Накладная: ' + Doc.Shipper.ShortName + ' [' +Doc.ClientNumber + '] : ' + TEgaisDocument.GetHumanityStatusName(Ord(Doc.DocumentStatus));

    if {not bOnlineMode or} (Doc.DocumentStatus <> eEgaisDocumentStatus.edsLoaded) then begin
        btnActAcept.Enabled:= False;
        btnActReject.Enabled:= False;
        btnActEdit.Enabled:= False;
    end;

    if {not bOnlineMode or} (Doc.DocumentStatus <> eEgaisDocumentStatus.edsClosed) or (Doc.DocumentType <> eEgaisDocumentType.edtInbox) then
        btnReturn.Enabled:= False;

    FillData();
end;

procedure TfrmWBview.FillData();
procedure AddDataItem(Parameter: String; Value: string);
var lvItem: TListItem;
begin
    lvItem:= lvData.Items.Add;
    lvItem.ImageIndex:= 0;
    lvItem.Caption:= Parameter;
    lvItem.SubItems.Add(Value);
end;

procedure AddTransportItem(Parameter: String; Value: string);
var lvItem: TListItem;
begin
    lvItem:= lvTransport.Items.Add;
    lvItem.ImageIndex:= 4;
    lvItem.Caption:= Parameter;
    lvItem.SubItems.Add(Value);
end;

procedure AddContentItem(Position: TPositionType);
var lvItem: TListItem;
begin
    lvItem:= lvContent.Items.Add;
    lvItem.ImageIndex:=1;
    lvItem.Caption:= Position.Identity;
    lvItem.SubItems.Add(Position.Product.FullName);
    lvItem.SubItems.Add(Position.Price);
    lvItem.SubItems.Add(Position.Quantity);
    lvItem.SubItems.Add(Position.Product.Capacity);
    lvItem.SubItems.Add(Position.Product.AlcVolume);
    lvItem.SubItems.Add(Position.Product.ProductVCode);

end;

procedure AddInformItem(Position: TPositionType);
var lvItem: TListItem;
begin
    lvItem:= lvInform.Items.Add;
    lvItem.ImageIndex:=2;
    lvItem.Caption:= Position.Identity;
    lvItem.SubItems.Add(Position.Product.FullName);
    lvItem.SubItems.Add(Position.InformA);
    lvItem.SubItems.Add(Position.NewInformB);
    lvItem.SubItems.Add(Position.InformB);

end;

procedure AddSummItem(Sum, Count, Cap: Currency);
var lvItem: TListItem;
begin
    lvItem:= lvContent.Items.Add;
    lvItem.ImageIndex:= 3;
    lvItem.Caption:= '';
    lvItem.SubItems.Add('Итого');
    lvItem.SubItems.Add(Format('%.2f', [Sum]) + ' р');
    lvItem.SubItems.Add(Format('%.3f', [Count]));
    lvItem.SubItems.Add(Format('%.3f', [Cap]) + ' л');
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
    AddDataItem('Статус документа', TEgaisDocument.GetHumanityStatusName(Ord(fDoc.DocumentStatus)));
    AddDataItem('Номер ТТН', fDoc.ClientNumber);
    AddDataItem('Дата накладной / отгрузки', DateToStr(fDoc.DocumentDate) + ' / ' + DateToStr(fDoc.ShippingDate));
    AddDataItem('Идентификатор ТТН в ЕГАИС', fDoc.REGINFO.WBRegId);
    AddDataItem('Номер / дата фиксации в ЕГАИС', fDoc.REGINFO.FixNumber + ' / ' + DateToStr(fDoc.REGINFO.FixDate));
    //AddDataItem('Номер фиксации в ЕГАИС', fDoc.REGINFO.FixNumber);
    AddDataItem('Идентификатор поставщика', fDoc.Identity);
    AddDataItem('Примечание системы', fDoc.SystemComment);

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
    AddSummItem(Sum, Count, Cap);

    //AddTransportItem('Тип', fDoc.Transport.TRAN_TYPE);
    AddTransportItem('Компания', fDoc.Transport.TRAN_COMPANY);
    AddTransportItem('Машина', fDoc.Transport.TRAN_CAR);
    AddTransportItem('Кузов', fDoc.Transport.TRAN_TRAILER);
    AddTransportItem('Заказчик', fDoc.Transport.TRAN_CUSTOMER);
    AddTransportItem('Водитель', fDoc.Transport.TRAN_DRIVER);
    AddTransportItem('Экспедитор', fDoc.Transport.TRAN_FORWARDER);
    AddTransportItem('Загрузка', fDoc.Transport.TRAN_LOADPOINT);
    AddTransportItem('Выгрузка', fDoc.Transport.TRAN_UNLOADPOINT);
    //AddTransportItem('Направление', fDoc.Transport.TRAN_REDIRECT);
end;

procedure TfrmWBview.FormCreate(Sender: TObject);
begin
    SetWindowLongPtr(pnlUp.Handle, GWL_EXSTYLE,
    GetWindowLongPtr(pnlUp.Handle, GWL_EXSTYLE) or WS_EX_COMPOSITED);

end;

procedure TfrmWBview.FormResize(Sender: TObject);
begin
    //Resize Content
    //LockWindowUpdate(lvContent.Handle);
    lvContent.Columns[0].Width := lvContent.Width div 16;
    lvContent.Columns[1].Width := (lvContent.Width div 2)  -  lvContent.Columns[0].Width - 25;
    lvContent.Columns[2].Width := lvContent.Width div 10;
    lvContent.Columns[3].Width := lvContent.Width div 10;
    lvContent.Columns[4].Width := lvContent.Width div 10;
    lvContent.Columns[5].Width := lvContent.Width div 10;
    lvContent.Columns[6].Width := lvContent.Width div 10;

    lvInform.Columns[0].Width := lvInform.Width div 16;
    lvInform.Columns[1].Width := (lvInform.Width div 2)  -  lvInform.Columns[0].Width - 25;
    lvInform.Columns[2].Width := lvInform.Width div 6;
    lvInform.Columns[3].Width := lvInform.Width div 6;
    lvInform.Columns[4].Width := lvInform.Width div 6;

    //LockWindowUpdate(0);
end;

procedure TfrmWBview.lvContentClick(Sender: TObject);
begin
    if (lvContent.Selected = nil) or (not lvContent.Visible) then Exit;
    if lvContent.Selected.Index >= lvInform.Items.Count then
        lvInform.Selected:= lvInform.Items[lvInform.Items.Count - 1]
    else
        lvInform.Selected:= lvInform.Items[lvContent.Selected.Index];
    lvInform.Selected.MakeVisible(True);
end;

procedure TfrmWBview.lvInformClick(Sender: TObject);
begin
    if (lvInform.Selected = nil) or (not lvInform.Visible) then Exit;
    lvContent.Selected:= lvContent.Items[lvInform.Selected.Index];
    lvContent.Selected.MakeVisible(True);
end;

end.

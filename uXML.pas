unit uXML;
interface

uses
    Windows,SysUtils,
    Generics.Collections, Generics.Defaults,
    Classes,
    Xml.xmldom, Xml.XMLIntf, Xml.Win.msxmldom, Xml.XMLDoc,
    StrUtils,
    Variants,
    uDocument,
    uTypes,
    uUTM
    ;
procedure LogNodeInfo(Node: IXMLNode; Msg: String='');
function ParseInboxList(InboxStream: TMemoryStream; InboxList: TList<TUTMstring>): Boolean;
function GetAttribute(Node: IXMLNode; attrName: String): String;
function SetAttribute(Node: IXMLNode; attrName: String; attrValue: String): Boolean;
function RemoveAttribute(Node: IXMLNode; attrName: String) : Boolean;
function Parse_WayBill(FullFileName: String): TEgaisDocument;
function Parse_Act(FullFileName: String): TAct;
function Parse_FORMBREGINFO(FullFileName: String; Doc: TEgaisDocument = nil): TEgaisDocument;
function FindXMLNode(Node: IXMLNode; NameToFind: String): IXMLNode;
function GetXMLValue(Node: IXMLNode): String;
function Parse_Contragent(ContragentNode: IXMLNode): TContragent;
function Fill_ContragentNode_ByDoc(ContragentNode: IXMLNode; Contragent: TContragent): Boolean;
function Parse_Address(AddressNode: IXMLNode): TAddress;
function Parse_Transport(TransportNode: IXMLNode): TTransport;
function Parse_Position(PositionNode: IXMLNode): TPositionType;
function Parse_Product(ProductNode: IXMLNode): TProduct;
function Fill_ProductNode_ByDoc(ProductNode: IXMLNode; Product: TProduct): Boolean;
function CreateAcceptAct(Doc: TEgaisDocument): TMemoryStream;
function CreateReturnAct(Doc: TEgaisDocument): TMemoryStream;
function CreateRejectAct(Doc: TEgaisDocument): TMemoryStream;
function CreateEditAct(Doc: TEgaisDocument): TMemoryStream;
function CreateWBRequest(Identifier: String): TMemoryStream;
function ParseServerAnswer(AnswerString: String): String;
function Parse_Ticket(FullFileName: String): TTicket;

implementation
uses uLog,uLogic, uDatabase;

function ParseInboxList(InboxStream: TMemoryStream; InboxList: TList<TUTMstring>): Boolean;
var xmlListDoc: IXMLDocument;
    xmlDocNode: iXMLNode;
    xmlItemNode: iXMLNode;
    ReplyID: String;
    Index: Integer;
    UTMString: TUTMstring;
begin
    xmlListDoc:= TXMLDocument.Create(nil);
    xmlListDoc.LoadFromStream(InboxStream);
    xmlDocNode:= xmlListDoc.ChildNodes.FindNode('A');
    //LogNodeInfo(xmlDocNode);
    if xmlDocNode = nil then Exit;
    for UTMString in InboxList do
        if UTMString <> nil then
            UTMString.Free;
    InboxList.Clear;

    for Index := 0 to xmlDocNode.ChildNodes.Count - 1 do begin
        xmlItemNode:= xmlDocNode.ChildNodes.Get(Index);
        if xmlItemNode.NodeName = 'url' then begin
            UTMString:= TUTMstring.Create;
            UTMString.ReplyID := GetAttribute(xmlItemNode, 'replyId');
            UTMString.Url:= xmlItemNode.Text;
            InboxList.Add(UTMString);
        end;
    end;
    Result:= True;
end;

procedure LogNodeInfo(Node: IXMLNode; Msg: String ='');
//Подробная информация об узле
var isTVal: iXMLnode;
Vl: String;
begin
if Node = nil then begin
    Log('NodeInfo: Node is nil!');
    Exit;
end;

if Node.IsTextElement then Vl:=Node.Text;
Log(Msg + ': NodeInfo: Title= ' + Node.NodeName + ':');
Log('       Value  = ' +  Vl);
Log('       @ =' + IntToStr(NativeInt(Node)));
Log('       Childs = ' + IntToStr(Node.ChildNodes.Count));
Log('       isText = ' + BoolToStr(Node.IsTextElement, True));
end;

function GetAttribute(Node: IXMLNode; attrName: String): String;
//Чтение атрибута в узле
begin
	result:=VarToStr(Node.Attributes[attrName]);
end;

function SetAttribute(Node: IXMLNode; attrName: String; attrValue: String): Boolean;
//Установка-добавление атрибута в узле
begin
    	Node.Attributes[attrName]:=attrValue;
        result:=True;
end;

function RemoveAttribute(Node: IXMLNode; attrName: String) : Boolean;
//Удаление атрибута у узла
var
    attr: iXMLNode;
begin
    attr:= Node.AttributeNodes.FindNode(attrName);
    if attr <> nil then begin
        Node.AttributeNodes.Remove(attr);
        result:=True;
    end else result:= False;
end;

function Parse_WayBill(FullFileName: String): TEgaisDocument;
var
    Doc: TEgaisDocument;
    XML: IXMLDocument;
    Index: integer;
    RootNode,DocumentNode,WayBillNode,
    IdentityNode,HeaderNode,ContentNode,
    ShipperNode, ConsigneeNode, TransportNode,
    PositionNode: IXMLNode;
begin
    Log('Парсинг WB...');
    XML:= TXMLDocument.Create(nil);
    XML.LoadFromFile(FullFileName);
    XML.Active:= True;
    Doc:=TEgaisDocument.Create;
    RootNode:= FindXMLNode(XML.Node, 'Documents');

    DocumentNode:= FindXMLNode(RootNode, 'Document');
    WayBillNode:= FindXMLNode(DocumentNode, 'WayBill');
    IdentityNode:= FindXMLNode(WayBillNode, 'Identity');
    HeaderNode:= FindXMLNode(WayBillNode, 'Header');

    Doc.Identity        := GetXMLValue(IdentityNode);

    Doc.ClientNumber    := GetXMLValue(FindXMLNode(HeaderNode, 'NUMBER'));
    Doc.DocumentDate    := ParseDateNoTime(GetXMLValue(FindXMLNode(HeaderNode, 'Date')));
    Doc.ShippingDate    := ParseDateNoTime(GetXMLValue(FindXMLNode(HeaderNode, 'ShippingDate')));

    Doc.TTNType         := IndexStr(GetXMLValue(FindXMLNode(HeaderNode, 'Type')), eWayBillTTNTypes);
    Doc.UnitType        := IndexStr(GetXMLValue(FindXMLNode(HeaderNode, 'UnitType')), eWayBillUnitTypes);

    Doc.Transport       := Parse_Transport(FindXMLNode(HeaderNode, 'Transport'));

    ShipperNode         := FindXMLNode(HeaderNode, 'Shipper');
    Doc.Shipper         := Parse_Contragent(ShipperNode);
    ConsigneeNode       := FindXMLNode(HeaderNode, 'Consignee');
    Doc.Consignee       := Parse_Contragent(ConsigneeNode);

    Doc.Content         := TList<TPositionType>.Create;
    ContentNode         := FindXMLNode(WayBillNode, 'Content');
    for Index := 0 to ContentNode.ChildNodes.Count - 1 do begin
        PositionNode:= Contentnode.ChildNodes[Index];
        Doc.Content.Add(Parse_Position(PositionNode));
    end;
    Log('Парсинг WB ...OK');
    Result              := Doc;
end;

function Parse_FORMBREGINFO(FullFileName: String; Doc: TEgaisDocument = nil): TEgaisDocument;
var
    //Doc: TEgaisDocument;
    XML: IXMLDocument;
    Index: integer;
    Position: TPositionType;
    RootNode,DocumentNode,RegInfoNode,
    HeaderNode,ContentNode,
    ShipperNode, ConsigneeNode,
    PositionNode: IXMLNode;
begin
    Log('Парсинг FORMBREGINFO...');
    XML:= TXMLDocument.Create(nil);
    XML.LoadFromFile(FullFileName);
    XML.Active:= True;

    if Doc = nil then
        Doc:=TEgaisDocument.Create;

    RootNode:= FindXMLNode(XML.Node, 'Documents');
    DocumentNode:= FindXMLNode(RootNode, 'Document');
    RegInfoNode:= FindXMLNode(DocumentNode, 'TTNInformBReg');
    //IdentityNode:= FindXMLNode(WayBillNode, 'Identity');
    HeaderNode:= FindXMLNode(RegInfoNode, 'Header');

    Doc.REGINFO.Identity        := GetXMLValue(FindXMLNode(HeaderNode, 'Identity'));
    Doc.REGINFO.WBRegId         := GetXMLValue(FindXMLNode(HeaderNode, 'WBRegId'));
    Doc.REGINFO.FixNumber       := GetXMLValue(FindXMLNode(HeaderNode, 'EGAISFixNumber'));
    Doc.REGINFO.FixDate         := ParseDateNoTime(GetXMLValue(FindXMLNode(HeaderNode, 'EGAISFixDate')));
    Doc.REGINFO.WBNUMBER        := GetXMLValue(FindXMLNode(HeaderNode, 'WBNUMBER'));
    Doc.REGINFO.WBDate          := ParseDateNoTime(GetXMLValue(FindXMLNode(HeaderNode, 'WBDate')));
    //LOg(Doc.REGINFO.WBRegId);

    ShipperNode                 := FindXMLNode(HeaderNode, 'Shipper');
    Doc.Shipper                 := Parse_Contragent(ShipperNode);
    ConsigneeNode               := FindXMLNode(HeaderNode, 'Consignee');
    Doc.Consignee               := Parse_Contragent(ConsigneeNode);

    ContentNode                 := FindXMLNode(RegInfoNode, 'Content');
    if Doc.Content.Count = 0 then
        for Index := 0 to ContentNode.ChildNodes.Count - 1 do begin
            PositionNode            := ContentNode.ChildNodes[Index];
            Position                := TPositionType.Create;
            Position.Identity       := GetXMLValue(FindXMLNode(PositionNode, 'Identity'));
            Position.NewInformB     := GetXMLValue(FindXMLNode(PositionNode, 'InformBRegId'));
            Doc.Content.Add(Position);
        end
    else
        for Index := 0 to ContentNode.ChildNodes.Count - 1 do begin
            PositionNode            := ContentNode.ChildNodes[Index];
            Position                := Doc.Content.Items[Index];
            Position.Identity       := GetXMLValue(FindXMLNode(PositionNode, 'Identity'));
            Position.NewInformB     := GetXMLValue(FindXMLNode(PositionNode, 'InformBRegId'));
        end;

    Result              := Doc;
    Log('Парсинг FORMBREGINFO ...OK');
end;

function Parse_Act(FullFileName: String): TAct;
begin
    //
end;

function Parse_Contragent(ContragentNode: IXMLNode): TContragent;
var
    Client: TContragent;
begin
    Log('Парсинг OrgInfo...');
    //LogNodeInfo(ContragentNode);
    if ContragentNode = nil then begin
        Result:= nil;
        Exit;
    end;
    Client:= TContragent.Create;
    Client.ClientRegId:= GetXMLValue(FindXMLNode(ContragentNode, 'ClientRegId'));
    Client.FullName:= GetXMLValue(FindXMLNode(ContragentNode, 'FullName'));
    Client.ShortName:= GetXMLValue(FindXMLNode(ContragentNode, 'ShortName'));
    Client.INN:= GetXMLValue(FindXMLNode(ContragentNode, 'INN'));
    Client.KPP:= GetXMLValue(FindXMLNode(ContragentNode, 'KPP'));
    Client.UNP:= GetXMLValue(FindXMLNode(ContragentNode, 'UNP'));
    Client.RNN:= GetXMLValue(FindXMLNode(ContragentNode, 'RNN'));
    Client.Address:= Parse_Address(FindXMLNode(ContragentNode, 'Address'));

    Result:=Client;
    Log('Парсинг OrgInfo ...OK');
end;

function Parse_Address(AddressNode: IXMLNode): TAddress;
var
    Address: TAddress;
begin
    Address:= TAddress.Create;
    Address.Country     :=GetXMLValue(FindXMLNode(AddressNode, 'Country'));
    Address.Index       :=GetXMLValue(FindXMLNode(AddressNode, 'Index'));
    Address.RegionCode  :=GetXMLValue(FindXMLNode(AddressNode, 'RegionCode'));
    Address.Area        :=GetXMLValue(FindXMLNode(AddressNode, 'area'));
    Address.City        :=GetXMLValue(FindXMLNode(AddressNode, 'city'));
    Address.Place       :=GetXMLValue(FindXMLNode(AddressNode, 'place'));
    Address.Street      :=GetXMLValue(FindXMLNode(AddressNode, 'street'));
    Address.House       :=GetXMLValue(FindXMLNode(AddressNode, 'house'));
    Address.Building    :=GetXMLValue(FindXMLNode(AddressNode, 'building'));
    Address.Liter       :=GetXMLValue(FindXMLNode(AddressNode, 'liter'));
    Address.Description :=GetXMLValue(FindXMLNode(AddressNode, 'description'));
    Result:=Address;
end;

function Parse_Transport(TransportNode: IXMLNode): TTransport;
var
    Transport: TTransport;
begin
    Transport:= TTransport.Create;
    Transport.TRAN_TYPE      :=GetXMLValue(FindXMLNode(TransportNode, 'TRAN_TYPE'));
    Transport.TRAN_COMPANY      :=GetXMLValue(FindXMLNode(TransportNode, 'TRAN_COMPANY'));
    Transport.TRAN_CAR      :=GetXMLValue(FindXMLNode(TransportNode, 'TRAN_CAR'));
    Transport.TRAN_TRAILER      :=GetXMLValue(FindXMLNode(TransportNode, 'TRAN_TRAILER'));
    Transport.TRAN_CUSTOMER      :=GetXMLValue(FindXMLNode(TransportNode, 'TRAN_CUSTOMER'));
    Transport.TRAN_DRIVER      :=GetXMLValue(FindXMLNode(TransportNode, 'TRAN_DRIVER'));
    Transport.TRAN_LOADPOINT      :=GetXMLValue(FindXMLNode(TransportNode, 'TRAN_LOADPOINT'));
    Transport.TRAN_UNLOADPOINT      :=GetXMLValue(FindXMLNode(TransportNode, 'TRAN_UNLOADPOINT'));
    Transport.TRAN_REDIRECT      :=GetXMLValue(FindXMLNode(TransportNode, 'TRAN_REDIRECT'));
    Transport.TRAN_FORWARDER      :=GetXMLValue(FindXMLNode(TransportNode, 'TRAN_FORWARDER'));
    Result:=Transport;
end;

function FindXMLNode(Node: IXMLNode; NameToFind: String): IXMLNode;
var
  Index: Integer;
begin
    if Node = nil then Exit;

    for Index := 0 to Node.ChildNodes.Count - 1 do begin
        if LowerCase(NameToFind) = LowerCase(Node.ChildNodes[Index].LocalName) then begin
            Result:= Node.ChildNodes[Index];
            Exit;
        end;
    end;
    Result:= nil;
end;

function GetXMLValue(Node: IXMLNode): String;
begin
    if Node = nil then Exit;
    if Node.IsTextElement then Result:= Node.Text;
end;

function Parse_Product(ProductNode: IXMLNode): TProduct;
var
    Product: TProduct;
begin
    Log('Парсинг ProductInfo...');
    //LogNodeInfo(ProductNode);
    Product:=TProduct.Create;
    Product.FullName        :=GetXMLValue(FindXMLNode(ProductNode, 'FullName'));
    Product.ShortName       :=GetXMLValue(FindXMLNode(ProductNode, 'ShortName'));
    Product.Capacity        :=GetXMLValue(FindXMLNode(ProductNode, 'Capacity'));
    Product.AlcVolume       :=GetXMLValue(FindXMLNode(ProductNode, 'AlcVolume'));
    Product.ProductVCode    :=GetXMLValue(FindXMLNode(ProductNode, 'ProductVCode'));
    Product.AlcCode         :=GetXMLValue(FindXMLNode(ProductNode, 'AlcCode'));
    Product.Producer        :=Parse_Contragent(FindXMLNode(ProductNode, 'Producer'));
    Product.Importer        :=Parse_Contragent(FindXMLNode(ProductNode, 'Importer'));
    Result                  :=Product;
    Log('Парсинг ProductInfo ...OK');
end;

function Fill_ContragentNode_ByDoc(ContragentNode: IXMLNode; Contragent: TContragent): Boolean;
var
    xmlAddress: IXMLNode;
begin
    try
        Log('Заполнение ветки клиента...' + Contragent.ClientRegId);
        Result:= false;

        ContragentNode.AddChild('oref:ClientRegId').Text := Contragent.ClientRegId;
        ContragentNode.AddChild('oref:FullName').Text := Contragent.FullName;

        if not Contragent.ShortName.IsEmpty then
            ContragentNode.AddChild('oref:ShortName').Text := Contragent.ShortName;

        if not Contragent.INN.IsEmpty then
            ContragentNode.AddChild('oref:INN').Text := Contragent.INN;

        if not Contragent.KPP.IsEmpty then
            ContragentNode.AddChild('oref:KPP').Text := Contragent.KPP;

        xmlAddress:= ContragentNode.AddChild('oref:address');

        xmlAddress.AddChild('oref:Country').Text:= Contragent.Address.Country;
        xmlAddress.AddChild('oref:description').Text:= Contragent.Address.Description;

        Result:= true;
        Log('...OK');
    except
        on e: Exception do ErrorLog(e, 'FillContragentByDoc', True);
    end;
end;

function Fill_ProductNode_ByDoc(ProductNode: IXMLNode; Product: TProduct): Boolean;
var
    xmlProducer, xmlImporter: IXMLNode;
begin
    try
        Log('Заполнение ветки продукта...' + Product.AlcCode);
        Result:= false;

        ProductNode.AddChild('pref:AlcCode').Text := Product.AlcCode;
        ProductNode.AddChild('pref:FullName').Text := Product.FullName;

        if not Product.ShortName.IsEmpty then
            ProductNode.AddChild('pref:ShortName').Text := Product.ShortName;

        if not Product.Capacity.IsEmpty then
            ProductNode.AddChild('pref:Capacity').Text := Product.Capacity;

        if not Product.AlcVolume.IsEmpty then
            ProductNode.AddChild('pref:AlcVolume').Text := Product.AlcVolume;

        if not Product.ProductVCode.IsEmpty then
            ProductNode.AddChild('pref:ProductVCode').Text := Product.ProductVCode;

        if Product.Producer <> nil then
            begin
            xmlProducer:= ProductNode.AddChild('pref:Producer');
            if not Fill_ContragentNode_ByDoc(xmlProducer, Product.Producer) then Exit
            end;

        if Product.Importer <> nil then
            begin
            xmlImporter:= ProductNode.AddChild('pref:Importer');
            if not Fill_ContragentNode_ByDoc(xmlImporter, Product.Importer) then Exit
            end;


        Log('...OK');
        Result:= true;
    except
        on e: Exception do ErrorLog(e, 'FillContragentByDoc', True);
    end;
end;

function Parse_Position(PositionNode: IXMLNode): TPositionType;
var
    Position: TPositionType;
    i:Double;
begin
    Log('Парсинг PositionType...');
    //LogNodeInfo(PositionNode);
    Position:=TPositionType.Create;
    Position.Identity       :=GetXMLValue(FindXMLNode(PositionNode, 'Identity'));
    Position.Pack_ID        :=GetXMLValue(FindXMLNode(PositionNode, 'Pack_ID'));
    Position.Quantity       :=GetXMLValue(FindXMLNode(PositionNode, 'Quantity'));
    Position.RealQuantity   := IntToStr(QuantityToInt(Position.Quantity));
    Position.Price          :=GetXMLValue(FindXMLNode(PositionNode, 'Price'));
    Position.Party          :=GetXMLValue(FindXMLNode(PositionNode, 'Party'));
    Position.Product        :=Parse_Product(FindXMLNode(PositionNode, 'Product'));

    Position.InformA        :=GetXMLValue(FindXMLNode(FindXMLNode(PositionNode, 'InformA'), 'RegId'));
    Position.InformB        :=GetXMLValue(FindXMLNode(FindXMLNode(FindXMLNode(PositionNode, 'InformB'), 'InformBItem'), 'BregId'));
    Result                  :=Position;
    Log('Парсинг PositionType ...OK');
end;

function CreateAcceptAct(Doc: TEgaisDocument): TMemoryStream;
var
    xmlDoc: IXMLDocument;
    xmlRootNode, xmlOwnerNode, xmlDocumentNode,
    xmlActNode, xmlHeaderNode: IXMLNode;
    FSRARID: String;
begin
    xmlDoc:= NewXMLDocument; //TXMLDocument.Create(nil);
    xmlDoc.Options := [doNodeAutoCreate, doNodeAutoIndent, doAttrNull, doNamespaceDecl];
    xmlDoc.NodeIndentStr := #9;
    xmlDoc.Encoding:= 'UTF-8';
    xmlRootNode:= xmlDoc.AddChild('ns:Documents', 'http://fsrar.ru/WEGAIS/WB_DOC_SINGLE_01');
    xmlRootNode.DeclareNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
    xmlRootNode.DeclareNamespace('wa', 'http://fsrar.ru/WEGAIS/ActTTNSingle');
    xmlRootNode.SetAttributeNS('Version','', '1.0');

    FSRARID:= GetOurFSRARID();
    if FSRARID.IsEmpty then Exit;
    xmlRootNode.AddChild('ns:Owner').AddChild('ns:FSRAR_ID').Text:= FSRARID;

    xmlActNode:= xmlRootNode.AddChild('ns:Document').AddChild('ns:WayBillAct');
    xmlActNode.AddChild('wa:Identity').Text:= GenerateGUID();

    xmlHeaderNode:= xmlActNode.AddChild('wa:Header');
    xmlHeaderNode.AddChild('wa:IsAccept').Text:= 'Accepted';
    xmlHeaderNode.AddChild('wa:ACTNUMBER').Text:= '1';//GenerateGUID();
    xmlHeaderNode.AddChild('wa:ActDate').Text:= GetDateNoTime(Date);
    xmlHeaderNode.AddChild('wa:WBRegId').Text:= Doc.REGINFO.WBRegId;
    xmlHeaderNode.AddChild('wa:Note').Text:= 'Подтверждаем накладную...';

    xmlActNode.AddChild('wa:Content').Text:='';
    Result:= TMemoryStream.Create;
    xmlDoc.SaveToStream(Result);
    Result.Position:=0;

end;

function CreateRejectAct(Doc: TEgaisDocument): TMemoryStream;
var
    xmlDoc: IXMLDocument;
    xmlRootNode, xmlOwnerNode, xmlDocumentNode,
    xmlActNode, xmlHeaderNode: IXMLNode;
    FSRARID: String;
begin
    xmlDoc:= NewXMLDocument; //TXMLDocument.Create(nil);
    xmlDoc.Options := [doNodeAutoCreate, doNodeAutoIndent, doAttrNull, doNamespaceDecl];
    xmlDoc.NodeIndentStr := #9;
    xmlDoc.Encoding:= 'UTF-8';
    xmlRootNode:= xmlDoc.AddChild('ns:Documents', 'http://fsrar.ru/WEGAIS/WB_DOC_SINGLE_01');
    xmlRootNode.DeclareNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
    xmlRootNode.DeclareNamespace('wa', 'http://fsrar.ru/WEGAIS/ActTTNSingle');
    xmlRootNode.SetAttributeNS('Version','', '1.0');

    FSRARID:= GetOurFSRARID();
    if FSRARID.IsEmpty then Exit;
    xmlRootNode.AddChild('ns:Owner').AddChild('ns:FSRAR_ID').Text:= FSRARID;

    xmlActNode:= xmlRootNode.AddChild('ns:Document').AddChild('ns:WayBillAct');
    xmlActNode.AddChild('wa:Identity').Text:= GenerateGUID();

    xmlHeaderNode:= xmlActNode.AddChild('wa:Header');
    xmlHeaderNode.AddChild('wa:IsAccept').Text:= 'Rejected';
    xmlHeaderNode.AddChild('wa:ACTNUMBER').Text:= '1';//GenerateGUID();
    xmlHeaderNode.AddChild('wa:ActDate').Text:= GetDateNoTime(Date);
    xmlHeaderNode.AddChild('wa:WBRegId').Text:= Doc.REGINFO.WBRegId;
    xmlHeaderNode.AddChild('wa:Note').Text:= 'Отказ от накладной';

    xmlActNode.AddChild('wa:Content').Text:='';
    Result:= TMemoryStream.Create;
    xmlDoc.SaveToStream(Result);
    Result.Position:= 0;
end;

function CreateReturnAct(Doc: TEgaisDocument): TMemoryStream;
var
    xmlDoc: IXMLDocument;
    xmlRootNode, xmlOwnerNode, xmlDocumentNode,
    xmlRetNode, xmlHeaderNode, xmlContentNode, xmlPositionNode,
    xmlShipper, xmlConsignee, xmlProduct: IXMLNode;
    Position: TPositionType;
    FSRARID: String;
begin
    xmlDoc:= NewXMLDocument; //TXMLDocument.Create(nil);
    xmlDoc.Options := [doNodeAutoCreate, doNodeAutoIndent, doAttrNull, doNamespaceDecl];
    xmlDoc.NodeIndentStr := #9;
    xmlDoc.Encoding:= 'UTF-8';
    xmlRootNode:= xmlDoc.AddChild('ns:Documents', 'http://fsrar.ru/WEGAIS/WB_DOC_SINGLE_01');
    xmlRootNode.DeclareNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
    xmlRootNode.DeclareNamespace('wb', 'http://fsrar.ru/WEGAIS/TTNSingle');
    xmlRootNode.DeclareNamespace('c', 'http://fsrar.ru/WEGAIS/Common');
    xmlRootNode.DeclareNamespace('oref', 'http://fsrar.ru/WEGAIS/ClientRef');
    xmlRootNode.DeclareNamespace('pref', 'http://fsrar.ru/WEGAIS/ProductRef');
    xmlRootNode.SetAttributeNS('Version','', '1.0');

    FSRARID:= GetOurFSRARID();
    if FSRARID.IsEmpty then Exit;
    xmlRootNode.AddChild('ns:Owner').AddChild('ns:FSRAR_ID').Text:= FSRARID;

    xmlRetNode:= xmlRootNode.AddChild('ns:Document').AddChild('ns:WayBill');
    xmlRetNode.AddChild('wb:Identity').Text:= Doc.Identity;

    xmlHeaderNode:= xmlRetNode.AddChild('wb:Header');
    xmlHeaderNode.AddChild('wb:NUMBER').Text:= Doc.ClientNumber;
    xmlHeaderNode.AddChild('wb:Date').Text:= GetDateNoTime(Doc.DocumentDate);
    xmlHeaderNode.AddChild('wb:ShippingDate').Text:= GetDateNoTime(Doc.DocumentDate);
    xmlHeaderNode.AddChild('wb:Type').Text:= eWayBillTTNTypes[Doc.TTNType];
    xmlHeaderNode.AddChild('wb:UnitType').Text:= eWayBillUnitTypes[Doc.UnitType];
    xmlShipper:=        xmlHeaderNode.AddChild('wb:Shipper');
    xmlConsignee:=      xmlHeaderNode.AddChild('wb:Consignee');

    if not Fill_ContragentNode_ByDoc(xmlShipper, Doc.Shipper) then begin
        Log('Ошибка заполнения ветки контрагента' + Doc.Shipper.ClientRegId);
        Exit;
    end;

     if not Fill_ContragentNode_ByDoc(xmlConsignee, Doc.Consignee) then begin
        Log('Ошибка заполнения ветки контрагента' + Doc.Consignee.ClientRegId);
        Exit;
    end;

    xmlHeaderNode.AddChild('wb:Transport');

    xmlContentNode:= xmlRetNode.AddChild('wb:Content');
    for Position in Doc.Content do begin
        xmlPositionNode:= xmlContentNode.AddChild('wb:Position');
        xmlPositionNode.AddChild('wb:Identity').Text:= Position.Identity;
        xmlPositionNode.AddChild('wb:Quantity').Text:= Position.Quantity;
        xmlPositionNode.AddChild('wb:Price').Text:= Position.Price;

        xmlProduct:= xmlPositionNode.AddChild('wb:Product');
        if not Fill_ProductNode_ByDoc(xmlProduct, Position.Product) then Exit;

        xmlPositionNode.AddChild('wb:InformA').AddChild('pref:RegId').Text:= Position.InformA;
        xmlPositionNode.AddChild('wb:InformB').AddChild('pref:InformBItem').AddChild('pref:BRegId').Text:= Position.NewInformB;
    end;

    Result:= TMemoryStream.Create;
    xmlDoc.SaveToStream(Result);
    Result.Position:=0;
end;

function CreateEditAct(Doc: TEgaisDocument): TMemoryStream;
var
    xmlDoc: IXMLDocument;
    xmlRootNode, xmlOwnerNode, xmlDocumentNode,
    xmlActNode, xmlHeaderNode, xmlContentNode, xmlPositionNode: IXMLNode;
    Position: TPositionType;
    FSRARID: String;
begin
    xmlDoc:= NewXMLDocument; //TXMLDocument.Create(nil);
    xmlDoc.Options := [doNodeAutoCreate, doNodeAutoIndent, doAttrNull, doNamespaceDecl];
    xmlDoc.NodeIndentStr := #9;
    xmlDoc.Encoding:= 'UTF-8';
    xmlRootNode:= xmlDoc.AddChild('ns:Documents', 'http://fsrar.ru/WEGAIS/WB_DOC_SINGLE_01');
    xmlRootNode.DeclareNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
    xmlRootNode.DeclareNamespace('wa', 'http://fsrar.ru/WEGAIS/ActTTNSingle');
    xmlRootNode.SetAttributeNS('Version','', '1.0');

    FSRARID:= GetOurFSRARID();
    if FSRARID.IsEmpty then Exit;
    xmlRootNode.AddChild('ns:Owner').AddChild('ns:FSRAR_ID').Text:= FSRARID;

    xmlActNode:= xmlRootNode.AddChild('ns:Document').AddChild('ns:WayBillAct');
    xmlActNode.AddChild('wa:Identity').Text:= GenerateGUID();

    xmlHeaderNode:= xmlActNode.AddChild('wa:Header');
    xmlHeaderNode.AddChild('wa:IsAccept').Text:= 'Accepted';
    xmlHeaderNode.AddChild('wa:ACTNUMBER').Text:= '1';//GenerateGUID();
    xmlHeaderNode.AddChild('wa:ActDate').Text:= GetDateNoTime(Date);
    xmlHeaderNode.AddChild('wa:WBRegId').Text:= Doc.REGINFO.WBRegId;
    xmlHeaderNode.AddChild('wa:Note').Text:= 'Подтверждаем частично';

    xmlContentNode:= xmlActNode.AddChild('wa:Content');
    for Position in Doc.Content do begin
        xmlPositionNode:= xmlContentNode.AddChild('wa:Position');
        xmlPositionNode.AddChild('wa:Identity').Text:= Position.Identity;
        xmlPositionNode.AddChild('wa:InformBRegId').Text:= Position.NewInformB;
        xmlPositionNode.AddChild('wa:RealQuantity').Text:= Position.RealQuantity;
    end;

    Result:= TMemoryStream.Create;
    xmlDoc.SaveToStream(Result);
    Result.Position:=0;
end;

function CreateWBRequest(Identifier: String): TMemoryStream;
var
    xmlDoc: IXMLDocument;
    xmlRootNode, xmlOwnerNode, xmlDocumentNode,
    xmlParNode: IXMLNode;
    Position: TPositionType;
    FSRARID: String;
begin
    xmlDoc:= NewXMLDocument; //TXMLDocument.Create(nil);
    xmlDoc.Options := [doNodeAutoCreate, doNodeAutoIndent, doAttrNull, doNamespaceDecl];
    xmlDoc.NodeIndentStr := #9;
    xmlDoc.Encoding:= 'UTF-8';
    xmlRootNode:= xmlDoc.AddChild('ns:Documents', 'http://fsrar.ru/WEGAIS/WB_DOC_SINGLE_01');
    xmlRootNode.DeclareNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
    xmlRootNode.DeclareNamespace('qp', 'http://fsrar.ru/WEGAIS/QueryParameters');
    xmlRootNode.SetAttributeNS('Version','', '1.0');

    FSRARID:= GetOurFSRARID();
    if FSRARID.IsEmpty then Exit;
    xmlRootNode.AddChild('ns:Owner').AddChild('ns:FSRAR_ID').Text:= FSRARID;

    xmlParNode:= xmlRootNode.AddChild('ns:Document').AddChild('ns:QueryResendDoc').AddChild('qp:Parameters').AddChild('qp:Parameter');

    xmlParNode.AddChild('qp:Name').Text := 'WBREGID';
    xmlParNode.AddChild('qp:Value').Text := Identifier;

    Result:= TMemoryStream.Create;
    xmlDoc.SaveToStream(Result);
    Result.Position:=0;
end;

function ParseServerAnswer(AnswerString: String): String;
var
    Doc: IXMLDocument;
    RootNode: IXMLNode;
begin
    //						Образец
	//<?xml version="1.0" encoding="UTF-8" standalone="no"?>
	//	<A>
	//		<url>d2ca01c9-cff4-4c29-ad5f-fe247acd55f5</url>
	///		<sign>895398F4827BE8B19E06C0F1414DA8B835AACE7956119A5CEFCB033069D1DDA88541
	//		DBA525CE00D58A48EE2354B9DC6F8C4F040533DAFC5D159FB2E81DE46FBF</sign>
	//		<ver>2</ver>
	//	</A>
    try
        Doc:= TXMLDocument.Create(nil);
        Doc.LoadFromXML(AnswerString);
        RootNode:= FindXMLNode(Doc.Node, 'A');
        Result:= FindXMLNode(RootNode, 'url').Text;
    finally
        Doc._Release;
    end;
end;

function Parse_Ticket(FullFileName: String): TTicket;
var
    Ticket: TTicket;
    XML: IXMLDocument;
    Index: integer;
    RootNode,DocumentNode,TicketNode,
    OperationResultNode, ResultNode,
    PositionNode: IXMLNode;
begin
    Log('Парсинг Ticket...');
    XML:= TXMLDocument.Create(nil);
    XML.LoadFromFile(FullFileName);
    XML.Active:= True;
    Ticket:=TTicket.Create;
    RootNode:= FindXMLNode(XML.Node, 'Documents');
    DocumentNode:= FindXMLNode(RootNode, 'Document');
    TicketNode:= FindXMLNode(DocumentNode, 'Ticket');
    Ticket.TicketDate:= GetXMLValue(FindXMLNode(TicketNode, 'TicketDate'));
    Ticket.Identity:= GetXMLValue(FindXMLNode(TicketNode, 'Identity'));
    Ticket.DocId:= GetXMLValue(FindXMLNode(TicketNode, 'DocId'));
    Ticket.TransportId:= GetXMLValue(FindXMLNode(TicketNode, 'TransportId'));
    Ticket.RegId:= GetXMLValue(FindXMLNode(TicketNode, 'RegID'));
    Ticket.DocHash:= GetXMLValue(FindXMLNode(TicketNode, 'DocHash'));
    Ticket.DocType:= GetXMLValue(FindXMLNode(TicketNode, 'DocType'));

    ResultNode:= FindXMLNode(TicketNode, 'Result');
    if ResultNode <> nil then begin
        Ticket.Result:= TTicket.TTicketResultType.Create;
        Ticket.Result.Conclusion:= GetXMLValue(FindXMLNode(ResultNode, 'Conclusion'));
        Ticket.Result.ConclusionDate:= GetXMLValue(FindXMLNode(ResultNode, 'ConclusionDate'));
        Ticket.Result.Comments:= GetXMLValue(FindXMLNode(ResultNode, 'Comments'));
    end;

    OperationResultNode:= FindXMLNode(TicketNode, 'OperationResult');
    if OperationResultNode <> nil then begin
        Ticket.OperationResult:= TTicket.TOperationResultType.Create;
        Ticket.OperationResult.OperationName:= GetXMLValue(FindXMLNode(OperationResultNode, 'OperationName'));
        Ticket.OperationResult.OperationResult:= GetXMLValue(FindXMLNode(OperationResultNode, 'OperationResult'));
        Ticket.OperationResult.OperationDate:= GetXMLValue(FindXMLNode(OperationResultNode, 'OperationDate'));
        Ticket.OperationResult.OperationComment:= GetXMLValue(FindXMLNode(OperationResultNode, 'OperationComment'));
    end;

    Result:= Ticket;
end;

end.

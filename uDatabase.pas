unit uDatabase;
interface
uses uLogic, uTypes, uDocument, DB, ADODB, SysUtils;

function SetBaseQuery(DS:TADODataSet; DBQuery: String): Boolean;
function Save_WayBill(WayBill: TEgaisDocument; var FileName: String): eReturnStatus;
function Save_FORMBREGINFO(RegInfo: TEgaisDocument; var FileName: String): eReturnStatus;
function Save_Product(Product: TProduct): Integer;
function Save_Client(Client: TContragent): Integer;
function Save_ReplyID(WayBill: TEgaisDocument): eReturnStatus;
function Save_Ticket(Ticket: TTicket): eReturnStatus;

implementation
uses uLog;

function SetBaseQuery(DS:TADODataSet; DBQuery: String): Boolean;
begin
    Log('SQL: ' + DBQuery);
    if DS.Active then DS.Close;
    DS.CommandType:=cmdText;
    DS.CommandText:=DBQuery;
    DS.Open;
end;

function Save_WayBill(WayBill: TEgaisDocument; var FileName: String): eReturnStatus;
var
    sDocDate: TDate;
    sIdentity: String;
    sShipperRegId: String;
    sClientNumber: String;
    iCurId: Integer;
    Position: TPositionType;
    Product: TProduct;
begin
    Log('Запись WB...');
    //Ищем аналогичную запись
    sShipperRegId:= WayBill.Shipper.ClientRegId;
    sIdentity:= WayBill.Identity;
    sDocDate:= WayBill.DocumentDate;
    sClientNumber:= WayBill.ClientNumber;
    SetBaseQuery(DataSet, 'select * from Documents where DocumentDate = CDate(''' + DateToStr(sDocDate) +
                                        ''') and ShipperRegId = ''' + sShipperRegId +
                                        ''' and ClientNumber = ''' + sClientNumber +
                                        ''' and Identity = ''' + sIdentity + '''');
    //Если запись нашлась выход
    if DataSet.RecordCount > 0 then begin
        Log('Этот документ уже загружался...');
        if DataSet['DocStatus'] = Ord(eEgaisDocumentStatus.edsClosed) then begin
            Log('Документ уже закрыт, удаляем его из УТМ...');
            Result:= eReturnStatus.rsDelete;
            Exit;
        end else if DataSet['DocStatus'] = Ord(eEgaisDocumentStatus.edsLoaded) then begin
            Log('Документ уже загружен, удаляем его из УТМ...');
            Result:= eReturnStatus.rsDeleteOne;
            Exit;
        end else begin
            Log('Возврат...');
            Result:= eReturnStatus.rsAlready;
            Exit;
        end;
    end;

    FileName:= 'WayBill_' + FormatDateTime('yyyymmdd', WayBill.DocumentDate) +
                '_' + GenerateGUID() + '.xml';
    DataSet.Append;
    DataSet['DocName'] := WayBill.Shipper.ShortName + ' [' + WayBill.ClientNumber + ']';
    if WayBill.DocumentType = eEgaisDocumentType.edtOutbox then begin

        WayBill.REGINFO.WBRegId := 'TTN-' + UpperCase(Copy(GenerateGUID(),1,8));
        DataSet['WBRegId'] := WayBill.REGINFO.WBRegId;
        DataSet['DocType'] := Ord(eEgaisDocumentType.edtOutbox);
        DataSet['DocStatus'] := Ord(WayBill.DocumentStatus);
        DataSet['LastComment']  := WayBill.SystemComment;
        DataSet['ReplyID'] := WayBill.ReplyID;
    end else begin
        DataSet['DocType'] := Ord(eEgaisDocumentType.edtInbox);
        DataSet['DocStatus'] := Ord(eEgaisDocumentStatus.edsNew);
        DataSet['LastComment']  := 'Документ частично загружен';
    end;


    DataSet['Identity'] := WayBill.Identity;
    DataSet['ShipperRegId'] := WayBill.Shipper.ClientRegId;
    DataSet['ConsigneeRegId'] := WayBill.Consignee.ClientRegId;
    DataSet['ConsigneeID'] := Save_Client(WayBill.Consignee);
    DataSet['ShipperID'] := Save_Client(WayBill.Shipper);
    DataSet['ClientNumber'] := WayBill.ClientNumber;
    DataSet['FileName'] := FileName;
    DataSet['TTNType'] := WayBill.TTNType;
    DataSet['UnitType'] := WayBill.UnitType;
    DataSet['DocumentDate'] := WayBill.DocumentDate;
    DataSet['ShippingDate'] := WayBill.ShippingDate;
    iCurId := DataSet.FieldByName('ID').AsInteger;
    DataSet.Post;
    SetBaseQuery(DataSetPositions, 'select * from Positions');
    for Position in WayBill.Content do begin
        Log('Запись позиции: ' + Position.Product.FullName);
        DataSetPositions.Append;
        DataSetPositions['DocID']:= DataSet['ID'];
        DataSetPositions['ProductID']:= Save_Product(Position.Product);
        DataSetPositions['Quantity']:= Position.Quantity;
        DataSetPositions['Identity']:= Position.Identity;
        DataSetPositions['Pack_ID']:= Position.Pack_ID;
        DataSetPositions['Price']:= Position.Price;
        DataSetPositions['InformA']:= Position.InformA;
        DataSetPositions['InformB']:= Position.InformB;
        DataSetPositions.Post;
    end;
    //Log(FormatDateTime('yyyymmdd', WayBill.DocumentDate));

    Result:= eReturnStatus.rsOK;
    Log('Запись WB ...OK');
end;

function Save_FORMBREGINFO(RegInfo: TEgaisDocument; var FileName: String): eReturnStatus;
var
    sDocDate: TDate;
    sIdentity: String;
    sShipperRegId: String;
    sClientNumber: String;
    iCurId: Integer;
    Position: TPositionType;
    Product: TProduct;
begin
    Log('Запись FORMBREGINFO...');
    //Ищем аналогичную запись
    sShipperRegId:= RegInfo.Shipper.ClientRegId;
    sIdentity:= RegInfo.REGINFO.Identity;
    sDocDate:= RegInfo.REGINFO.WBDate;
    sClientNumber:= RegInfo.REGINFO.WBNUMBER;
    SetBaseQuery(DataSet, 'select * from Documents where DocumentDate = CDate(''' + DateToStr(sDocDate) +
                                        ''') and ShipperRegId = ''' + sShipperRegId +
                                        ''' and ClientNumber = ''' + sClientNumber +
                                        ''' and Identity = ''' + sIdentity + '''');

    if DataSet.RecordCount = 0 then begin
        Log('В базе не найдена запись WB соответствующая REGINFO!');
        Log('Возможно документ ещё не загружен...');
        Result:= eReturnStatus.rsNext;
        Exit;
    end;
    Log('Найден соответствующий документ WB для записи...');
    //TODO Впихнуть сюда проверку на идентификатор

    if not DataSet.FieldByName('WBRegId').IsNull then begin
        Log('Для этого файла уже записывалась FORMBREGINFO...');
       //TODO Проверить структуру регинфо и соответствие записанного

        if DataSet['DocStatus'] = Ord(eEgaisDocumentStatus.edsClosed) then begin
            Log('Документ уже закрыт, удаляем его из УТМ...');
            Result:= eReturnStatus.rsDelete;
            Exit;
        end else if DataSet['DocStatus'] = Ord(eEgaisDocumentStatus.edsLoaded) then begin
            Log('Документ уже загружен, удаляем его из УТМ...');
            Result:= eReturnStatus.rsDeleteOne;
            Exit;
        end else begin
            Log('Возврат...');
            Result:= eReturnStatus.rsAlready;
            Exit;
        end;
    end;

    FileName:= 'FORMBREGINFO_' + FormatDateTime('yyyymmdd', RegInfo.REGINFO.WBDate) +
                '_' + GenerateGUID() + '.xml';

    DataSet.Edit;
    DataSet['WBRegId']      := RegInfo.REGINFO.WBRegId;
    DataSet['FixNumber']    := RegInfo.REGINFO.FixNumber;
    DataSet['FixDate']      := RegInfo.REGINFO.FixDate;
    DataSet['DocStatus']    := Ord(eEgaisDocumentStatus.edsLoaded);
    DataSet['RegInfoName']  := FileName;
    DataSet['LastComment']  := 'Документ успешно загружен';
    DataSet.Post;

    iCurId := DataSet.FieldByName('ID').AsInteger;
    for Position in RegInfo.Content do begin
        SetBaseQuery(DataSetPositions, 'select * from Positions where DocID = ' + IntToStr(iCurId) +
                                        ' and Identity = ''' + Position.Identity + '''' );
        DataSetPositions.Edit;
        DataSetPositions['NewInformB']:= Position.newInformB;
        DataSetPositions.Post;
    end;

    Result:= eReturnStatus.rsOK;
    Log('Запись FORMBREGINFO ...OK');
end;

function Save_Product(Product: TProduct): Integer;
begin
    Log('Запись ProductInfo...');
    if Product = nil then begin
        Result:= 0;
        Exit;
    end;

    SetBaseQuery(DataSetProducts, 'select * from Products where AlcCode = '''+ Product.AlcCode + '''');
    if DataSetProducts.RecordCount > 0 then begin
        //        DataSetProducts.First;
        Result:= DataSetProducts['ID'];
        Exit;
    end;

    DataSetProducts.Append;
    DataSetProducts['AlcCode']:= Product.AlcCode;
    DataSetProducts['FullName']:= Product.FullName;
    DataSetProducts['ShortName']:= Product.ShortName;
    DataSetProducts['Capacity']:= Product.Capacity;
    DataSetProducts['AlcVolume']:= Product.AlcVolume;
    DataSetProducts['ProductVCode']:= Product.ProductVCode;
    DataSetProducts['ProducerID']:= Save_Client(Product.Producer);
    if not (Product.Importer = nil) then begin
        Log(Assigned(Product.Importer));
        DataSetProducts['ImporterID']:= Save_Client(Product.Importer);
    end;
    DataSetProducts.Post;
    Result:=DataSetProducts.FieldByName('ID').AsInteger;
    Log('Запись ProductInfo ...OK');
end;

function Save_Client(Client: TContragent): Integer;
begin
    Log('Запись OrgInfo...');
    if Client = nil then begin
        Result:= 0;
        Exit;
    end;

    SetBaseQuery(DataSetClients, 'select * from Clients where ClientRegId = '''+ Client.ClientRegId + '''');
    if DataSetClients.RecordCount > 0 then begin
        //        DataSetProducts.First;
        Result:= DataSetClients['ID'];
        Exit;
    end;

    DataSetClients.Append;
    DataSetClients['ClientRegId']:= Client.ClientRegId;
    DataSetClients['FullName']:= Client.FullName;
    DataSetClients['ShortName']:= Client.ShortName;
    DataSetClients['INN']:= Client.INN;
    DataSetClients['KPP']:= Client.KPP;
    DataSetClients['UNP']:= Client.UNP;
    DataSetClients['RNN']:= Client.RNN;
    DataSetClients['AdrCountry']:= Trim(Client.Address.Country);
    DataSetClients['AdrIndex']:= Client.Address.Index;
    DataSetClients['AdrRegionCode']:= Client.Address.RegionCode;
    DataSetClients['AdrArea']:= Client.Address.Area;
    DataSetClients['AdrCity']:= Client.Address.City;
    DataSetClients['AdrPlace']:= Client.Address.Place;
    DataSetClients['AdrStreet']:= Client.Address.Street;
    DataSetClients['AdrHouse']:= Client.Address.House;
    DataSetClients['AdrBuilding']:= Client.Address.Building;
    DataSetClients['AdrLiter']:= Client.Address.Liter;
    DataSetClients['AdrDescription']:= Client.Address.Description;
    DataSetClients.Post;
    Result:=DataSetClients.FieldByName('ID').AsInteger;
    Log('Запись OrgInfo ...OK');
end;

function Save_ReplyID(WayBill: TEgaisDocument): eReturnStatus;
begin
    Log('Запись ReplyID...');
    SetBaseQuery(DataSet, 'select * from Documents where WBRegId = ''' + WayBill.REGINFO.WBRegId + '''');
    if DataSet.RecordCount = 0 then begin
        Log('Накладная с номером ' + WayBill.REGINFO.WBRegId + ' не найдена');
        Result:= eReturnStatus.rsError;
        Exit;
    end;

    DataSet.Edit;
    DataSet['ReplyID']      := WayBill.ReplyID;
    DataSet['DocStatus']    := Ord(WayBill.DocumentStatus);
    DataSet['DocResult']    := Ord(WayBill.DocumentResult);
    DataSet['LastComment']  := WayBill.SystemComment;
    DataSet.Post;

    Result:= eReturnStatus.rsOK;
    Log('Запись ReplyID ...OK');
end;

function Save_ActTicket(Ticket: TTicket): eReturnStatus;
var
    sReplyID: String;
    sDocumentRegId: String;

begin
    if Ticket.Result = nil then begin
        Result:= eReturnStatus.rsError;
        Exit;
    end;

    sDocumentRegId := Ticket.RegID;
    sReplyID := Ticket.TransportId;
    SetBaseQuery(DataSet, 'select * from Documents where ReplyID = ''' +
      sReplyID + ''' or WBRegId = ''' + sDocumentRegId + '''');
    if DataSet.RecordCount = 0 then
    begin
        Log('В базе не найдена запись WB соответствующая ReplyID!');
        Log('Возможно документ ещё не загружен...');
        Result := eReturnStatus.rsNext;
        Exit;
    end;

    Log('Получена квитанция для акта от накладной ' + DataSet.FieldByName('DocName').AsString);

    if DataSet.FieldByName('DocStatus').AsInteger = Ord(eEgaisDocumentStatus.edsNew) then begin
        Log('Накладная еще в статусе частичной загрузки. Вернемся к квитанции позже...');
        Result:= eReturnStatus.rsNext;
        Exit;
    end;

    if DataSet.FieldByName('DocStatus').AsInteger = Ord(eEgaisDocumentStatus.edsClosed) then begin
        Log('Накладная уже закрыта, обработка не требуется. Квитанция будет удалена.');
        Result:= eReturnStatus.rsDeleteOne;
        Exit;
    end;

    if DataSet.FieldByName('DocStatus').AsInteger = Ord(eEgaisDocumentStatus.edsRejected) then begin
        Log('Накладная отменена, обработка не требуется. Квитанция будет удалена.');
        Result:= eReturnStatus.rsDeleteOne;
        Exit;
    end;

    if Ticket.Result.Conclusion = 'Accepted' then begin
        Log('Акт принят системой c комментарием:');
        Log('= ' + Ticket.Result.Comments);
        DataSet.Edit;

        if DataSet.FieldByName('DocStatus').Value = Ord(eEgaisDocumentStatus.edsLoaded) then begin
            Log('Странная квитанция, мы актов не отправляли, видимо кто-то другой. Ну что ж...');
            Log('Перевод накладной в состояние "Акт принят"');
            DataSet.FieldByName('DocStatus').Value := Ord(eEgaisDocumentStatus.edsActAccepted);
            DataSet.FieldByName('LastComment').Value := Ticket.Result.Comments;
            Result:= eReturnStatus.rsOK_noSave;
        end

        else if DataSet.FieldByName('DocStatus').Value = Ord(eEgaisDocumentStatus.edsActAccepted) then begin
            Log('Запись о принятии акта уже производилась. Действий не требуется...');
            Result:= eReturnStatus.rsAlready;
        end

        else if DataSet.FieldByName('DocStatus').Value = Ord(eEgaisDocumentStatus.edsActUploaded) then begin
            Log('Накладная в ожидании подтверждения акта. Перевод накладной в состояние "Акт принят"');
            DataSet.FieldByName('DocStatus').Value := Ord(eEgaisDocumentStatus.edsActAccepted);
            DataSet.FieldByName('LastComment').Value := Ticket.Result.Comments;
            Result:= eReturnStatus.rsOK_noSave;
        end;

        DataSet.Post;
    end

    else if Ticket.Result.Conclusion = 'Rejected' then begin
        Log('Акт отвергнут системой c комментарием:');
        Log('= ' + Ticket.Result.Comments);

        DataSet.Edit;
        //        //Акт выслан повторно и ошибочно, лучше конечно комментарии разбирать
        //if Pos('Акт для данной накладной уже существует', Ticket.Result.Comments) > 0 then begin
        //            Log('Кто-то повторно отправлял акт для накладной');
        //            Log('Действий для накладной не требуется, квитанция удаляется');
        //            Result:= eReturnStatus.rsDeleteOne;
        //        end
        //
        //        else begin
        //            Log('Не могу сообразить что делать. Перемещаем квитанцию в карантин...');
        //
        //            //Другие варианты отказа от акта в дальнейшем добавятся
        //end;
        Result:= eReturnStatus.rsDeleteOne;        //Нет смысла хранить цепочку
        DataSet.FieldByName('DocStatus').Value := Ord(eEgaisDocumentStatus.edsRejected);
        DataSet.FieldByName('LastComment').Value := Ticket.Result.Comments;
        DataSet.Post;
    end;
end;

function Save_WBTicket(Ticket: TTicket): eReturnStatus;
function Save_WBTicket_T1Accepted(Ticket: TTicket): eReturnStatus;
var
    DocType: eEgaisDocumentType;
    DocStatus: eEgaisDocumentStatus;
begin
    Log('Получена квитанция подтверждения...');
    DocType := eEgaisDocumentType(DataSet.FieldByName('DocType').AsInteger);
    DocStatus:= eEgaisDocumentStatus(DataSet.FieldByName('DocStatus').AsInteger);

    if DocType = edtInbox then
        begin
        if (DocStatus = edsClosed) or (DocStatus = edsPosted) then
            begin
            Log('Документ уже закрыт или проведен, удаляем все связанные тикеты');
            Result:= eReturnStatus.rsDeleteOne;
            Exit;
            end;

        if DocStatus = edsRejected then
            begin
            Log('Накладная отменена, обработка не требуется. Квитанция будет удалена.');
            Result:= eReturnStatus.rsDeleteOne;
            Exit;
            end;

        if DocStatus <> edsUploaded then
            begin
            Log('Накладная не в статусе edsUploaded, странно...');
            Result:= eReturnStatus.rsAlready;
            Exit;
            end;

        DataSet.Edit;
        DataSet.FieldByName('DocStatus').Value := Ord(eEgaisDocumentStatus.edsUploadedChecked);
        DataSet.FieldByName('LastComment').Value := Ticket.Result.Comments;
        DataSet.Post;
        Log('Документ подтвержден c комментарием: ');
        Log(Ticket.Result.Comments);
        Result:= eReturnStatus.rsDeleteOne;
        end
end;

function Save_WBTicket_T1Rejected(Ticket: TTicket): eReturnStatus;
var
    DocType: eEgaisDocumentType;
    DocStatus: eEgaisDocumentStatus;
begin
    Log('Получена квитанция подтверждения с ошибкой...');
    DocType := eEgaisDocumentType(DataSet.FieldByName('DocType').AsInteger);
    DocStatus:= eEgaisDocumentStatus(DataSet.FieldByName('DocStatus').AsInteger);
    Log('111');

    if DocStatus = edsError then
            begin
            Log('Накладная уже отменена, обработка не требуется. Квитанция будет удалена.');
            Result:= eReturnStatus.rsDeleteOne;
            Exit;
            end;

    if DocStatus <> edsUploaded then
            begin
            Log('Накладная не в статусе edsUploaded, странно...');
            Result:= eReturnStatus.rsAlready;
            Exit;
            end;

    DataSet.Edit;
    DataSet.FieldByName('DocStatus').Value := Ord(eEgaisDocumentStatus.edsError);
    DataSet.FieldByName('LastComment').Value := Ticket.Result.Comments;
    DataSet.Post;
    Log('Ошибка подтверждения c комментарием: ');
    Log(Ticket.Result.Comments);
    Result:= eReturnStatus.rsDeleteOne;
end;

function Save_WBTicket_T2ConfirmAccepted(Ticket: TTicket): eReturnStatus;
var
    DocType: eEgaisDocumentType;
    DocStatus: eEgaisDocumentStatus;
begin
    Log('Получена квитанция о проведении...');
    DocType := eEgaisDocumentType(DataSet.FieldByName('DocType').AsInteger);
    DocStatus:= eEgaisDocumentStatus(DataSet.FieldByName('DocStatus').AsInteger);

    if DocType = edtInbox then
        begin
        if DocStatus = edsClosed then
            begin
            Log('Документ уже закрыт, удаляем все связанные тикеты');
            Result:= eReturnStatus.rsDelete;
            Exit;
            end;

        if Ord(DocStatus) < Ord(eEgaisDocumentStatus.edsActAccepted)  then
            begin
            Log('Документ ещё не имеет подтвержденного акта. Вернемся к нему позже.');
            Result:= eReturnStatus.rsNext;
            Exit;
            end;

        if DocStatus = edsRejected then
            begin
            Log('Накладная отменена, обработка не требуется. Квитанция будет удалена.');
            Result:= eReturnStatus.rsDelete;
            Exit;
            end;
        DataSet.Edit;
        DataSet.FieldByName('DocStatus').Value := Ord(eEgaisDocumentStatus.edsClosed);
        DataSet.FieldByName('DocResult').Value := Ord(eEgaisDocumentResult.edrAccepted);
        DataSet.FieldByName('LastComment').Value := Ticket.OperationResult.OperationComment;
        DataSet.Post;
        Log('Документ проведен и закрыт c комментарием: ');
        Log(Ticket.OperationResult.OperationComment);
        Result:= eReturnStatus.rsDelete;
        end
    else
        begin
        if DocStatus = edsPosted then
            begin
            Log('Документ уже проведен, удаляем все связанные тикеты');
            Result:= eReturnStatus.rsDelete;
            Exit;
            end;
        DataSet.Edit;
        DataSet.FieldByName('DocStatus').Value := Ord(eEgaisDocumentStatus.edsPosted);
        DataSet.FieldByName('LastComment').Value := Ticket.OperationResult.OperationComment;
        DataSet.Post;
        Log('Документ проведен, ожидается ответ получателя: ');
        Log(Ticket.OperationResult.OperationComment);
        Result:= eReturnStatus.rsDelete;
        end;
end;

function Save_WBTicket_T2ConfirmRejected(Ticket: TTicket): eReturnStatus;
var
    DocType: eEgaisDocumentType;
    DocStatus: eEgaisDocumentStatus;
begin
    Log('Получена квитанция об ошибке распроведения...');
    DocType := eEgaisDocumentType(DataSet.FieldByName('DocType').AsInteger);
    DocStatus:= eEgaisDocumentStatus(DataSet.FieldByName('DocStatus').AsInteger);

    DataSet.Edit;
    DataSet.FieldByName('DocStatus').Value := Ord(eEgaisDocumentStatus.edsError);
    DataSet.FieldByName('LastComment').Value := Ticket.OperationResult.OperationComment;
    DataSet.Post;
    Log('Произошла ошибка проведения: ');
    Log(Ticket.OperationResult.OperationComment);

    Result:= eReturnStatus.rsDelete;
end;

function Save_WBTicket_T2UnconfirmAccepted(Ticket: TTicket): eReturnStatus;
var
    DocType: eEgaisDocumentType;
    DocStatus: eEgaisDocumentStatus;
begin
    Log('Получена квитанция о распроведении...');
    DocType := eEgaisDocumentType(DataSet.FieldByName('DocType').AsInteger);
    DocStatus:= eEgaisDocumentStatus(DataSet.FieldByName('DocStatus').AsInteger);


        if DocStatus = edsRejected then
            begin
            Log('Накладная отменена, обработка не требуется. Квитанция будет удалена.');
            Result:= eReturnStatus.rsDelete;
            Exit;
            end;

        DataSet.Edit;
        DataSet.FieldByName('DocStatus').Value := Ord(eEgaisDocumentStatus.edsRejected);
        DataSet.FieldByName('LastComment').Value := Ticket.OperationResult.OperationComment;
        DataSet.Post;
        Log('Документ распроведен c комментарием: ');
        Log(Ticket.OperationResult.OperationComment);
        Result:= eReturnStatus.rsDelete;
end;

function Save_WBTicket_T2UnconfirmRejected(Ticket: TTicket): eReturnStatus;
var
    DocType: eEgaisDocumentType;
    DocStatus: eEgaisDocumentStatus;
begin
    Log('Получена квитанция об ошибке распроведения...');
    DocType := eEgaisDocumentType(DataSet.FieldByName('DocType').AsInteger);
    DocStatus:= eEgaisDocumentStatus(DataSet.FieldByName('DocStatus').AsInteger);

    if DocStatus = edsError then
        begin
        Log('Накладная отменена, обработка не требуется. Квитанция будет удалена.');
        Result:= eReturnStatus.rsDelete;
        Exit;
        end;

    DataSet.Edit;
    DataSet.FieldByName('DocStatus').Value := Ord(eEgaisDocumentStatus.edsError);
    DataSet.FieldByName('LastComment').Value := Ticket.OperationResult.OperationComment;
    DataSet.Post;
    Log('Ошибка распроведения c комментарием: ');
    Log(Ticket.OperationResult.OperationComment);
    Result:= eReturnStatus.rsDelete;
end;

var
    sReplyID: String;
    sDocumentRegId: String;
begin

    sDocumentRegId := Ticket.RegID;
    sReplyID := Ticket.TransportId;

    SetBaseQuery(DataSet, 'select * from Documents where ReplyID = ''' +
      sReplyID + ''' or WBRegId = ''' + sDocumentRegId + '''');
    if DataSet.RecordCount = 0 then
    begin
        Log('В базе не найдена запись WB соответствующая ReplyID!');
        Log('Возможно документ ещё не загружен...');
        Result := eReturnStatus.rsNext;
        Exit;
    end;

    Log('Определен документ: ' + DataSet.FieldByName('WBRegId').AsString);

    if Ticket.Result <> nil then
        begin
        if Ticket.Result.Conclusion = 'Accepted' then
            Result:= Save_WBTicket_T1Accepted(Ticket)
        else if Ticket.Result.Conclusion = 'Rejected' then
            Result:= Save_WBTicket_T1Rejected(Ticket);
        end
    else if Ticket.OperationResult <> nil then
        begin

        if (Ticket.OperationResult.OperationName = 'Confirm') AND
            (Ticket.OperationResult.OperationResult = 'Accepted') then
                Result:= Save_WBTicket_T2ConfirmAccepted(Ticket)

        else if (Ticket.OperationResult.OperationName = 'Confirm') AND
            (Ticket.OperationResult.OperationResult = 'Rejected') then
                Result:= Save_WBTicket_T2ConfirmRejected(Ticket)

        else if (Ticket.OperationResult.OperationName = 'UnConfirm') AND
            (Ticket.OperationResult.OperationResult = 'Rejected') then
                Result:= Save_WBTicket_T2UnconfirmRejected(Ticket)

            else if (Ticket.OperationResult.OperationName = 'UnConfirm') AND
              (Ticket.OperationResult.OperationResult = 'Accepted') then
                Result := Save_WBTicket_T2UnconfirmAccepted(Ticket)
        end;

    end;

function Save_Ticket(Ticket: TTicket): eReturnStatus;
    begin
        Log('Запись Ticket...');
        // Раскидываем по типам
        if Ticket.DocType = 'WayBillAct' then
            Result := Save_ActTicket(Ticket)
        else if (Ticket.DocType = 'WAYBILL') or (Ticket.DocType = 'WayBill') then
            Result := Save_WBTicket(Ticket)
        else if Ticket.DocType = 'QueryResendDoc' then
            Result := eReturnStatus.rsDeleteOne
        else
            Result := eReturnStatus.rsMoveToQuarantine;
        Log();
end;

end.

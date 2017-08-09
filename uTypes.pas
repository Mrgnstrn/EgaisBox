unit uTypes;

interface
uses SysUtils, Classes;

    type eReturnStatus =   (rsUnknown,
                            rsOK,
                            rsOK_noSave,
                            rsError,
                            rsStop,
                            rsNotFound,
                            rsAlready,
                            rsDelete,
                            rsDeleteOne,
                            rsNext,
                            rsMoveToQuarantine);

    type eUrlType = (utWayBill,utFORMBREGINFO,utTicket,utWayBillAct,utUnknown);

    //type eReturnCode = (rcOK, rcError, rcNotFound, rcAlreadyRXed, rcAlreadyTXed, rcStop, rcNext, rcDeleteObj, rcUnknown);

    type TAddress = class
        Country: String;
        Index: String;
        RegionCode: String;
        Area: String;
        City: String;
        Place: String;
        Street: String;
        House: String;
        Building: String;
        Liter: String;
        Description: String;
        procedure Assign(Source: TAddress);
    end;

    type TContragent = class
        ClientRegId: String;
        FullName: String;
        ShortName: String;
        INN: String;
        KPP:String;
        UNP: String;
        RNN:String;
        Address: TAddress;
        procedure Assign(Source: TContragent);
    end;

    type TTransport = class
        TRAN_TYPE: String;
        TRAN_COMPANY: String;
        TRAN_CAR: String;
        TRAN_TRAILER: String;
        TRAN_CUSTOMER: String;
        TRAN_DRIVER:String;
        TRAN_LOADPOINT: String;
        TRAN_UNLOADPOINT: String;
        TRAN_REDIRECT: String;
        TRAN_FORWARDER: String;
    end;

    type TProduct = class
        FullName: String;
        ShortName: String;
        Capacity: String;
        AlcVolume: String;
        ProductVCode: String;
        AlcCode: String;
        Producer: TContragent;
        Importer: TContragent;
    end;

    type TPositionType = class
        Identity: String;
        Pack_ID: String;
        Quantity: String;
        RealQuantity: String;
        Price: String;
        Party:String;
        Product: TProduct;
        InformA: String;
        InformB: String;
        NewInformB: String;
    end;

    type TViewDocumentsFilter = class(TPersistent)
    public
        DateStart: TDate;
        DateEnd: TDate;
        Inbox: Boolean;
        Outbox: Boolean;
        constructor Create;
        procedure Assign(Source: TPersistent); override;
        procedure ClearFilter();
    end;

    type TLicenseData = packed record
        RegId: array [0 .. 9] of String[12];
        EndDate: TDate;
        Key: String[32];
    end;

    type TCryptedLicense = packed record
        ver:byte;
        data: array[0..170] of byte;
        sign: array[0..83] of byte;
    end;

implementation

constructor TViewDocumentsFilter.Create();
begin
    Self.DateStart:= Date - 30;
    Self.DateEnd:= Date;
    Self.Inbox:= True;
    Self.Outbox:= True;
end;

procedure TViewDocumentsFilter.Assign(Source: TPersistent);
begin
    if not (Source is TViewDocumentsFilter) then Exit;
    Self.DateStart:= (Source as TViewDocumentsFilter).DateStart;
    Self.DateEnd:= (Source as TViewDocumentsFilter).DateEnd;
    Self.Inbox:=  (Source as TViewDocumentsFilter).Inbox;
    Self.Outbox:=  (Source as TViewDocumentsFilter).Outbox;
end;

procedure TViewDocumentsFilter.ClearFilter();
begin
    Self.Inbox:= False;
    Self.Outbox:= False;
end;

procedure TContragent.Assign(Source: TContragent);
begin
    if not (Source is TContragent) then Exit;
    Self.ClientRegId:= (Source as TContragent).ClientRegId;
    Self.FullName:= (Source as TContragent).FullName;
    Self.ShortName:= (Source as TContragent).ShortName;
    Self.INN:= (Source as TContragent).INN;
    Self.KPP:= (Source as TContragent).KPP;
    Self.UNP:= (Source as TContragent).UNP;
    if not Assigned(Self.Address) then Self.Address:= TAddress.Create;
    Self.Address.Assign((Source as TContragent).Address);
end;

procedure TAddress.Assign(Source: TAddress);
begin
    Self.Country:= (Source as TAddress).Country;
    Self.Description:= (Source as TAddress).Description;
end;

end.

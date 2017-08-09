unit uDocument;
interface

uses SysUtils, Windows, Classes, XMLIntf, XMLDoc, uTypes, Generics.Collections, Generics.Defaults;

type eEgaisDocumentType = (edtUnknown,
                            edtInbox,
                            edtOutbox);

const eWayBillTTNTypes: array[0..3] of String = ('WBInvoiceFromMe',
                                                'WBInvoiceToMe',
                                                'WBReturnFromMe',
                                                'WBReturnToMe');

const eWayBillUnitTypes: array[0..1] of String = ('Packed','Unpacked');

type eEgaisDocumentDirectionType =(WBInvoiceFromMe,
                            WBInvoiceToMe,
                            WBReturnFromMe,
                            WBReturnToMe);


type eEgaisDocumentStatus =(edsUnknown,
                            edsNew,
                            edsLoaded,
                            edsActUploaded,
                            edsActAccepted,
                            edsClosed,
                            edsRejected,
                            edsUploaded,
                            edsUploadedChecked,
                            edsPosted,
                            edsError);

type eEgaisDocumentResult =(edrNone,
                            edrActAccept,
                            edrActEdit,
                            edrActReject,
                            edrAccepted,
                            edrChipperReject);
type
    TEgaisDocument = class

    type TRegInfo = class
        Identity: String;
        WBRegId: String;
        FixNumber: String;
        FixDate: TDate;
        WBNUMBER: String;
        WBDate: TDate;
    end;

    public
        DocumentType: eEgaisDocumentType;
        DocumentStatus: eEgaisDocumentStatus;
        DocumentResult: eEgaisDocumentResult;
        SystemComment: String;
        Identity: String;
        ClientNumber: String;
        DocumentDate: TDate;
        ShippingDate: TDate;
        TTNType: Integer;
        UnitType: Integer;
        Shipper: TContragent;
        Consignee: TContragent;
        Content: TList<TPositionType>;
        Transport: TTransport;
        ReplyID: String;
        REGINFO: TRegInfo;
        class function GetHumanityStatusName(EnumIndex:Integer): String;
        class function GetHumanityDocTypeName(EnumIndex:Integer): String;
        class function GetHumanityeDocResultName(EnumIndex:Integer): String;
    private
        docPassword: String;
        fileStream: TFileStream;
    published
        constructor Create; overload;
end;

type
    TTicket = class
        type TTicketResultType = class
            Conclusion: string;
            ConclusionDate: string;
            Comments: string;
        end;

        type TOperationResultType = class
            OperationName: string;
            OperationResult: string;
            OperationDate: string;
            OperationComment: string;
        end;
    public
        Owner: string;
        TicketDate: String;
        Identity: String;
        DocId: String;
        TransportId: String;
        RegID: string;
        DocHash: string;
        DocType: string;
        Result: TTicketResultType;
        OperationResult: TOperationResultType;
    end;

type
    TAct = class
        type TActType = (artNone, artAccepted, artRejected, artEdit);
    public
        Owner: string;
        ActType: TActType;
        Date: TDate;
        Number: string;
        WBRegId: String;
        Note: String;
        Content: TList<TPositionType>;
    end;

implementation
uses uLog, uCrypt;

constructor TEgaisDocument.Create;
begin
    REGINFO:= TRegInfo.Create;
    Content:= TList<TPositionType>.Create;
end;

class function TEgaisDocument.GetHumanityStatusName(EnumIndex:Integer): String;
begin
    case EnumIndex of
        0: Result:= '����������';
        1: Result:= '�����';
        2: Result:= '��������';
        3: Result:= '��� ���������';
        4: Result:= '��� �����������';
        5: Result:= '������';
        6: Result:= '�������';
        7: Result:= '���������';
        8: Result:= '��������';
        9: Result:= '��������';
        10:Result:= '������';
    end;
end;

class function TEgaisDocument.GetHumanityDocTypeName(EnumIndex:Integer): String;
begin
    case EnumIndex of
        0: Result:= '����������';
        1: Result:= '��������';
        2: Result:= '���������';
    end;
end;

class function TEgaisDocument.GetHumanityeDocResultName(EnumIndex:Integer): String;
begin
    case EnumIndex of
        0: Result:= '���';
        1: Result:= '�����������';
        2: Result:= '�����������';
        3: Result:= '�����';
        4: Result:= '�������';
        5: Result:= '����� ����.';
    end;
end;
end.

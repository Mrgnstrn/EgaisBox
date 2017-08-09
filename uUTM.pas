unit uUTM;
interface
uses Classes, SysUtils, StrUtils, uLog, IdHTTP, uLogic,
     Generics.Collections, Generics.Defaults;

type
    TUTMstring = class
        Url: String;
        ReplyID: String;
    end;
var
    InboxUTMList: TList<TUTMstring>;
    OutboxUTMList: TList<TUTMstring>;

function CheckUTMServer(aAddress: String = ''): Boolean;
function LoadStringFromUTM(RequestURL: String; out ResultString: String): Boolean;

function LoadStreamFromUTM(RequestURL: String; ResultStream: TStream): Boolean;
function LoadFileFromUTM(RequestURL: String; FileName: String): Boolean;

function SendStreamToUTM(DestinationURL: String; InboxStream: TMemoryStream; out ServerAnswer: String): Boolean;
//function SendFileToUTM(DestinationURL: String; FileName: String; out ServerAnswer: String): Boolean;
function GetInboxFileList(): TList<TUTMstring>;
function GetOutboxFileList(): TList<TUTMstring>;
function DeleteUTMobject(Url: string): Boolean;
function DeleteUTMObjectByReplyID(ReplyID: string): Boolean;

implementation
uses uXML;

function CheckUTMServer(aAddress: String = ''): Boolean;
var
    HTTP: TIdHTTP;
begin
    if aAddress = '' then aAddress:= GetUTMaddress();
    try
        HTTP:= TIdHTTP.Create(nil);
        HTTP.Head(aAddress);
        Result:= True;
        HTTP.Free;
    Except on E:Exception do begin
        HTTP.Free;
        Result:= False;
        end;
    end;
end;

function LoadStringFromUTM(RequestURL: String; out ResultString: String): Boolean;
var
    HTTP: TIdHTTP;
begin
    try
        HTTP:= TIdHTTP.Create(nil);
        ResultString:= HTTP.Get(RequestURL);
        Result:= True;
        HTTP.Free;
    Except on E:Exception do begin
        ErrorLog(e, 'LoadStreamFromUTM' , False);
        Log('Неудачная загрузка данных, статус возврата: ' + HTTP.ResponseCode.ToString() );
        Log('Ответ сервера: ' + HTTP.ResponseText);
        HTTP.Free;
        Result:= False;
        end;
    end;
end;

function LoadStreamFromUTM(RequestURL: String; ResultStream: TStream): Boolean;
var
    HTTP: TIdHTTP;
begin
    try
        HTTP:= TIdHTTP.Create(nil);
        HTTP.Get(RequestURL, ResultStream);
        Result:= True;
        HTTP.Free;
    Except on E:Exception do begin
        ErrorLog(e, 'LoadStreamFromUTM' , False);
        Log('Неудачная загрузка данных, статус возврата: ' + HTTP.ResponseCode.ToString() );
        Log('Ответ сервера: ' + HTTP.ResponseText);
        HTTP.Free;
        Result:= False;
        end;
    end;
end;

function LoadFileFromUTM(RequestURL: String; FileName: String): Boolean;
var Stream: TFileStream;
begin
    try
        Stream:= TFileStream.Create(strInboxFolder + FileName, fmCreate);
        Result:= LoadStreamFromUTM(RequestURL, Stream);
        if Result then
            Log('Загружен файл ' + FileName)
        else
            Log('Ошибка загрузки файла из УТМ');
    finally
        Stream.Free;
    end;
end;

function SendStreamToUTM(DestinationURL: String; InboxStream: TMemoryStream; out ServerAnswer: String): Boolean;
var
    HTTP: TIdHTTP;
    Boundary: String;
    SendStream: TStringStream;
begin
    try
        HTTP:= TIdHTTP.Create(nil);
        SendStream:= TStringStream.Create('', TEncoding.UTF8);

        Boundary:= '--------------------' + LeftStr(GenerateGuid(), 20);
        HTTP.Request.ContentType := 'multipart/form-data;boundary=' + Boundary + CrLf;

        SendStream.WriteString('--' + Boundary + CrLf
            + 'Content-Disposition: form-data;name="xml_file";filename="file.xml"' + CrLf
            + 'Content-Type:application/xml' + CrLf + CrLf);
        SendStream.CopyFrom(InboxStream, InboxStream.Size);
        SendStream.WriteString(CrLf+ '--' + Boundary  + '--');

        ServerAnswer:= HTTP.Post(DestinationURL, SendStream);
        Result:= True;
        SendStream.Free;
        HTTP.Free;
    Except on E:EIdHTTPProtocolException do begin
        ErrorLog(e, 'SendStreamToUTM', true);
        Log('Неудачная загрузка данных на сервер, статус возврата: ' + HTTP.ResponseCode.ToString() );
        Log('Ответ сервера: ' + HTTP.ResponseText);
        Log(e.Message);
        Log(e.ErrorMessage);
        HTTP.Free;
        Result:= False;
        end;
    end;
end;

function GetInboxFileList(): TList<TUTMstring>;
var InboxStream: TMemoryStream;
begin
    InboxStream:= TMemoryStream.Create;
    LoadStreamFromUTM(GetUTMaddress + constInboxList, InboxStream);
    Result:= TList<TUTMstring>.Create;
    ParseInboxList(InboxStream, Result);
end;

function GetOutboxFileList(): TList<TUTMstring>;
var OutboxStream: TMemoryStream;
begin
    OutboxStream:= TMemoryStream.Create;
    LoadStreamFromUTM(GetUTMaddress + constOutboxList, OutboxStream);
    Result:= TList<TUTMstring>.Create;
    ParseInboxList(OutboxStream, Result);
end;

function DeleteUTMobject(Url: string): Boolean;
var
    HTTP: TIdHTTP;
begin
    if StrToBool(xmlCfg.GetValue('DontDeleteUTM', False)) = True then begin
        Log('Удаление объектов из УТМ запрещено в настройках!');
        Exit;
    end;

    try
        HTTP:= TIdHTTP.Create(nil);
        Log('Удаление: ' + Url);
        HTTP.Delete(Url);
        if HTTP.ResponseCode = 200 then
            Result:= True
        else
            Result:= False;
        HTTP.Free;
    Except on E:Exception do begin
        ErrorLog(e, 'DeleteUTMobject' , False);
        Log('Ошибка при попытке удаления: ' + HTTP.ResponseCode.ToString() );
        Log('Ответ сервера: ' + HTTP.ResponseText);
        HTTP.Free;
        Result:= False;
        end;
    end;
end;

function DeleteUTMObjectByReplyID(ReplyID: string): Boolean;
var
    UTMstr: TUTMstring;
    InboxList: TList<TUTMstring>;
    OutboxList: TList<TUTMstring>;
begin
    try
        if ReplyID.Length = 0 then Exit;
        InboxList:= GetInboxFileList();
//        OutboxList:= GetOutboxFileList();
        for UTMstr in InboxList do begin
            if UTMstr.ReplyID = ReplyID then
                DeleteUTMobject(UTMstr.Url);
        end;

//        for UTMstr in OutboxList do begin
//            if UTMstr.ReplyID = ReplyID then
//                DeleteUTMobject(UTMstr.Url);
//        end;
    finally
        InboxList.Free;
        //OutboxList.Free;
    end;
end;

end.

unit uUpdater;

interface

uses
    System.Classes, SysUtils, WinApi.Windows, IdHTTP, Forms, ShellAPI,
    Xml.xmldom, Xml.XMLIntf, Xml.Win.msxmldom, Xml.XMLDoc,
     IdServerIOHandler, IdServerIOHandlerSocket,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL;

    const
        strUpdaterExeName: string   = 'Updater.exe';
        strUpdaterDLUrl: string     = 'https://github.com/Egaisbox/Updater/releases/download/Latest/Updater.exe';
        VersionFileURL: string      = 'https://github.com/Egaisbox/Version/releases/download/Latest/Version.xml';
                                    // https://github.com/Egaisbox/Version/releases/download/Latest/Version.xml
        VersionFileURLalt: string   = 'https://github.com/EBres/Version/releases/download/Latest/Version.xml';
    type
        TUpdater = class(TThread)
    private
        fVersionURL: String;
        fVersionAltURL: String;
        fSilent: Boolean;
        type TUpdateStructure = class
            Version: String;
            Forced:Boolean;
            UrlList: TStringList;
        end;
    protected
        procedure Execute; override;
        class function DownloadFileToStream(URL: string; DestStream: TStream): Boolean;
        function ParseVersionStream(VersionStream: TMemoryStream; UpStruct: TUpdateStructure): Boolean;
        procedure CantLoadFile();
        procedure NeedRestartForUpdateForced();
        procedure NeedRestartForUpdate();
        function ExtractFileNameFromURL(aURL: string): string;
    published
        class function GetCurrentVersion(): String;
        property VersionURL: string write fVersionURL;
        property VersionAltURL: string write fVersionAltURL;
        property Silent: Boolean write fSilent;
    end;

    var
        thUpdater: TUpdater;
    procedure CheckUpdates();
    procedure StartUpdater();
    procedure CheckUpdater();
    procedure StopUpdateProcess();

implementation

uses uMain, uLogic, uLog, uXML;

procedure CheckUpdates();
begin
    Log('Запуск процесса проверки обновлений...');
    thUpdater:=TUpdater.Create(true);
    thUpdater.fVersionURL:= VersionFileURL;
    thUpdater.fVersionAltURL:= VersionFileURLalt;
    thUpdater.Silent:= False;
    thUpdater.Priority:= tpLowest;
    thUpdater.Resume;
end;

procedure CheckUpdater();
var
    Stream: TMemoryStream;
begin
try
    Stream := TMemoryStream.Create();
    if not FileExists(strUpdaterExeName) then
    begin
        TUpdater.DownloadFileToStream(strUpdaterDLUrl, Stream);
        Stream.SaveToFile(strUpdaterExeName);
    end;
finally
    Stream.Free;
end;
end;

procedure StartUpdater();
begin
try
    CheckUpdater();
    ShellExecute(Application.Handle, nil, 'updater.exe', nil, nil, SW_HIDE);
except
    on e:Exception do begin
        ErrorLog(e, 'StartUpdater', False);
    end;
end;
end;

procedure StopUpdateProcess();
begin
    if thUpdater <> nil then begin
        if not thUpdater.Terminated then begin
            thUpdater.Terminate();
            thUpdater.WaitFor();
        end;
        FreeAndNil(thUpdater);
    end;
end;

procedure TUpdater.Execute;
var
    thStream:TMemoryStream;
    r: TStringList;
    UpStructure: TUpdateStructure;
    index: Integer;
begin
try
    //Sleep(60000);
    thStream:= TMemoryStream.Create();
        if DownloadFileToStream(fVersionURL, thStream) OR DownloadFileToStream(fVersionAltURL, thStream) then begin
            Log('Файл версии загружен...');
            UpStructure:= TUpdateStructure.Create();
            UpStructure.UrlList:= TStringList.Create();
            if ParseVersionStream(thStream, UpStructure) then begin
                if UpStructure.Version <> GetCurrentVersion() then begin
                    Log('Актуальная версия: ' + UpStructure.Version);
                    if UpStructure.UrlList.Count > 0 then begin
                        Log('Файлов для обновления:', UpStructure.URLList.Count);
                        for index := 0 to UpStructure.URLList.Count - 1 do begin
                            thStream.Clear;
                            if DownloadFileToStream(UpStructure.URLList[index], thStream) then
                                thStream.SaveToFile(ExtractFileNameFromURL(UpStructure.URLList[index]));
                        end;
                        Log('Необходима перезагрузка программы для обновления');
                        if not Self.Terminated then begin
                            if UpStructure.Forced then
                                Synchronize(NeedRestartForUpdateForced)
                            else Synchronize(NeedRestartForUpdate);
                            CheckUpdater;
                        end else Log('Поток отменен');
                        bNeedUpdate:= True;
                    end;
                end else begin
                    Log('Установлена актуальная версия программы...');
                end
            end else begin
                Log('Ошибка парсинга файла обновления!');
                Exit;
            end;
        end else begin
            Synchronize(CantLoadFile);
        end;
        Log('Проверка обновлений завершена');
finally
    thStream.Free;
    if UpStructure <> nil then begin
        UpStructure.UrlList.Free;
        UpStructure.Free;
    end;
end;

end;

procedure TUpdater.CantLoadFile();
begin
    Log('Не удается загрузить файл для обновления...');
    if not self.fSilent then
    MessageBox(Application.Handle, PWideChar('Модуль обновления не смог загрузить необходимые файлы'
               + CrLf + 'Пожалуйста, проверьте настройки и доступность интернета.'),
                PWideChar('Ошибка обновления'), MB_OK + MB_ICONWARNING + MB_APPLMODAL + MB_TOPMOST);
end;

function TUpdater.ParseVersionStream(VersionStream: TMemoryStream; UpStruct: TUpdateStructure): Boolean;
var
    xmlDoc: IXMLDocument;
    RootNode, VersionNode, ForceNode, FileListNode, FileNode: IXMLNode;
    i: Integer;
begin
try
    xmlDoc:= NewXMLDocument;
    xmlDoc.LoadFromStream(VersionStream);
    RootNode:=xmlDoc.ChildNodes.FindNode('Version');
    VersionNode:= RootNode.ChildNodes.FindNode('Current');
    UpStruct.Version:= VersionNode.Text;
    ForceNode:= RootNode.ChildNodes.FindNode('Forced');
    UpStruct.Forced:= StrToBool(ForceNode.Text);
    FileListNode:= RootNode.ChildNodes.FindNode('Files');
    for i := 0 to FileListNode.ChildNodes.Count - 1 do begin
        FileNode:= FileListNode.ChildNodes.Get(i);
        UpStruct.UrlList.Add(FileNode.Text);
    end;
    Result:= True;
finally
    //
end;
end;

class function TUpdater.GetCurrentVersion(): String;
type
    TVerInfo=packed record
    Nevazhno: array[0..47] of byte; // ненужные нам 48 байт
    Minor,Major,Build,Release: word; // а тут версия
    end;
var
    s:TResourceStream;
    v:TVerInfo;
begin
    result:='';
    try
        s:=TResourceStream.Create(HInstance,'#1',RT_VERSION); // достаём ресурс
        if s.Size > 0 then begin
            s.Read(v, SizeOf(v)); // читаем нужные нам байты
            Result:= IntToStr(v.Major) + '.' + Format('%.3d', [v.Minor]);
        end;
        s.Free;
    except;
end; end;

class function TUpdater.DownloadFileToStream(URL: string; DestStream: TStream): Boolean;
var
    HTTP: TIdHTTP;
    IdSSLIOHandlerSocket1: TIdSSLIOHandlerSocketOpenSSL;
    Answer: String;
    NewLocation:String;
begin
    try
        //Log('Загрузка: ' + URL);
        HTTP := TIdHTTP.Create(nil);
//            IdSSLIOHandlerSocket1:=TIdSSLIOHandlerSocketOpenSSL.Create(HTTP);
//            IdSSLIOHandlerSocket1.SSLOptions.Method := sslvTLSv1;
//            IdSSLIOHandlerSocket1.SSLOptions.Mode := sslmUnassigned;
//            HTTP.IOHandler:=IdSSLIOHandlerSocket1;
//            HTTP.Request.ContentType := 'text/html';
        HTTP.Request.Accept := 'text/html, */*';
        HTTP.Request.BasicAuthentication := False;
        HTTP.Request.UserAgent := 'Mozilla/4.0 (compatible; MSIE 6.0; MSIE 5.5;) ';
        //HTTP.RedirectMaximum := 15;
        HTTP.HandleRedirects := True;
        //HTTP.ConnectTimeout := 5;
        try
            HTTP.Get(URL, DestStream);
            Result:= True;
        except
            on e: Exception do begin
                if (e is EIDHttpProtocolException) then begin
                    if (e as EIDHttpProtocolException).ErrorCode = 302 then begin
                        NewLocation:= HTTP.Response.Location;
                        //Log('DL redirect to ' + NewLocation);
                        try
                            HTTP.Get(NewLocation, DestStream);
                            Result:= True;
                        except
                            on x: Exception do
                            ErrorLog(x, 'DownloadEx', False);
                        end;
                    end else begin
                        ErrorLog(e, 'Download', False);
                    end;
                end else ErrorLog(e, 'Download', False);
            end;
        end;
    finally
    HTTP.Free;
    end;
end;

function TUpdater.ExtractFileNameFromURL(aURL: string): string;
var
    i: Integer;
begin
    i := LastDelimiter('/', aURL);
    Result := Copy(aURL, i + 1, Length(aURL) - (i));
end;

procedure TUpdater.NeedRestartForUpdateForced();
begin
    //
end;

procedure TUpdater.NeedRestartForUpdate();
begin
    if not Self.fSilent then
    MessageBox(Application.Handle, PWideChar('Загружена новая версия программы.'
               + CrLf + 'Она будет установлена при следующем запуске.'
               //+ CrLf
               //+ CrLf + 'При необходимости используйте пункт меню'
               //+ CrLf + '"?"->"Отменить обновление"'
               ),
                PWideChar('Обновление программы'), MB_OK + MB_ICONINFORMATION + MB_APPLMODAL + MB_TOPMOST);
end;


end.

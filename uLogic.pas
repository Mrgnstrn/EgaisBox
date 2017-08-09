unit uLogic;
interface

uses Windows, Messages, SysUtils, StrUtils, Variants,TypInfo, ShellAPI, Classes, Graphics, Controls,
  StdCtrls, Forms, ImgList, Menus, ComCtrls, ExtCtrls, ToolWin, ClipBrd, Vcl.Buttons,
  Vcl.Dialogs, Registry, DateUtils, ShlObj,
  Generics.Collections, Generics.Defaults,
	{XML}
    Xml.xmldom, Xml.XMLIntf, Xml.Win.msxmldom, Xml.XMLDoc,
	{MyUnits}
//    XMLutils, uDocument, uFieldFrame, uFolderFrame, uFolderFrameInfo,
//   uSmartMethods,
    uSettings,
    uAbout,
    DB,ADODB,
    uUTMChecker,
    uDocument,
    uTypes;

const



    //constInboxListRefresh: String   = '/opt/out?refresh=true';
    constInboxList: String          = '/opt/out';
    constOutboxList: String         = '/opt/in';
    constActSendUrl: String         = '/opt/in/WayBillAct';
    constWBResendUrl: String        = '/opt/in/QueryResendDoc';
    constWBSendUrl: String          = '/opt/in/WayBill';
    Key: String = '2486C98817EA4AE496E55A664BF30103';
    strInboxFolder: String          = '.\inbox\';
    strOutboxFolder: String         = '.\outbox\';
    strArchiveFolder: String        = '.\files\';
    strBackupFolder: String         = '.\backup\';
    //strLicenseFolder: String        = '.\license\';
    strQuarantineFolder: String     = '.\quarant\';
    strLogsFolder: String           = '.\logs\';
    strBaseName: String             = '.\base.db';
    strConfigFile: String           = 'Config.xml';
    strUrlWebpage: String           = 'http://egaisbox.ru';
    strUrlVKpage                    = 'https://vk.com/egaisbox';
    strChangesListFile: String      = '.\changes.txt';
    CrLf = sLineBreak;
var
//    omgDoc: TOmgDocument;           //Основной наш документ
//	  //xmlMain: TXMLDocument;        //Деприкейтед
    xmlCfg: TSettings;
    DataSet: TADODataSet;
    DataSetPositions: TADODataSet;
    DataSetProducts: TADODataSet;
    DataSetClients: TADODataSet;

    strUTMserver: String;
    strUTMport: String;
    bOnlineMode: Boolean;               //Доступен ли сервер УТМ
    bRegStatus: Boolean;                //Зарегана ли программа, временно в переменной
    bDefaultLicense: Boolean;
    bLogDocked: Boolean;                //Пристыкован ли Лог к основному окошку
    bWindowsOnTop: Boolean;
    bNeedUpdate: Boolean;
    DocFilter: TViewDocumentsFilter;
    License: TLicenseData;

function InitGlobal: Boolean;
function CheckUTM(): Boolean;
procedure ChangeMainFormCaption();
procedure CheckFolders();
function CheckBase(): Boolean;
procedure StartDownload;
function LoadInboxFileList(RefreshFromServer: Boolean = False): Boolean;
function GetUTMaddress(): String;
function RemoveUTMaddress(FullAddress: String): String;
procedure SaveSettings;
procedure LoadSettings;
procedure WindowsOnTop(Flag: Boolean; Form: TForm);
procedure ShowOptionsWindow;
procedure ShowAboutWindow();
procedure ShowRawUTMWindow();
function GenerateGUID(WithDash: Boolean = False): String;
procedure ClearFolder(FolderName: String);
function GetUrlAddressType(UrlAddress: String): eUrlType;
function GetFileTypeByFileName(FileName: String): eUrlType;
//Дата
function ParseDateNoTime(DateNoTimeString: String): TDate;
function GetDateNoTime(tDate: TDate): String;
//Закрытие
procedure DestroyObjects();
procedure ListDocumentsToScreen(WBRegID:String = '');
function SendFileToArchive(FileName: String; NewFileName: String = ''): Boolean;
function SendFileToQuarantine(FileName: String; NewFileName: String = ''): Boolean;
procedure ShowWayBillWindow(WBNumber: String);
procedure ShowFilterWindow();
function GetStatusFilterQueryString(): String;
function SendAcceptAct(WayBill: TEgaisDocument): eReturnStatus;
function SendRejectAct(WayBill: TEgaisDocument): eReturnStatus;
procedure CreateReturn(WBNumber: string);
function SendEditAct(WayBill: TEgaisDocument): eReturnStatus;
function QuantityToInt(Quantity:String): Integer;
function CheckLicense(): Boolean;
function GetOurFSRARID(): String;
function ParseLicense(FileName: String; out Lic: TLicenseData): Boolean;
function CheckRegIDtoLicense(Value: String): Boolean;
procedure NeedRegisterMessage();
procedure GoToWebPage(Url: string);
procedure ShowMessageUTMoffline();
procedure WayBillRequest();
procedure ShowLogForm();
function ParseFSRARIDfromUTM(): String;
function SendReturn(WayBill: TEgaisDocument): eReturnStatus;


implementation
uses uMain, uLog, uConsole, uCrypt, uOptions, uRawUTM, uFilter, uUTM, uXML, uDatabase,
    uWBview, uReturn, uWBrequest, uUpdater, uActEdit;

function InitGlobal: Boolean;

var
    lvItem: TListItem;
//Запуск программы
begin
    Result:= False;
    LogList:= TStringList.Create;
    Log('EgaisBox вер. ' + TUpdater.GetCurrentVersion);
	Log('Инициализация...');
    //Log(GetDateNoTime(Date));
    //log(GenerateGuid());
    xmlCfg:= TSettings.Create(strConfigFile);
    DataSet:= TADODataSet.Create(nil);
    DataSetPositions:= TADODataSet.Create(nil);
    DataSetProducts:= TADODataSet.Create(nil);
    DataSetClients:= TADODataSet.Create(nil);
    InboxUTMList:= TList<TUTMstring>.Create;
    DocFilter:= TViewDocumentsFilter.Create;
    SetCurrentDir(ExtractFilePath(Application.ExeName));

    CheckFolders();
    if not CheckBase() then begin
        Log('Не удалось открыть базу данных!');
        Exit;
    end;
    CheckLicense();
    LoadSettings();
    CheckUpdates();
    CheckUTM();

    Log('Без ограничений:', bRegStatus);
    //frmMain.tbtnLog.Click();

    ListDocumentsToScreen();
    frmMain.Show;
    Result:=True;
end;

procedure DestroyObjects();
var
    frmDT: string;
begin
    frmMain.Hide;
    StopUpdateProcess();
    if bNeedUpdate then
        StartUpdater();
    StopUTMChecker();
    DataSet.Free;
    DataSetPositions.Free;
    DataSetProducts.Free;
    DataSetClients.Free;

    DateTimeToString(frmDT, 'yymmdd_hhmm', Now);
    LogList.SaveToFile(strLogsFolder + 'log_' + frmDT + '.txt');
end;

procedure StartDownload();
var
    Index: Integer;
    UrlAddress: String;
    ReplyID: String;
    UrlType: eUrlType;
    DlFilesCount, TCFilesCount, DelFilesCount: Integer;
    FileName, NewFileName: String;
    WayBill: TEgaisDocument;
    ReturnCode: eReturnStatus;
    UTMString, NewUTMString: TUTMstring;
    Ticket: TTicket;
    NextList: TList<TUTMstring>;
begin
    if not bOnlineMode then begin
        if not CheckUTM then begin
            ShowMessageUTMoffline();
            Exit;
        end
    end;
    Log('Загрузка файлов из УТМ...');
    NextList:= TList<TUTMstring>.Create;
    LoadInboxFileList();
    ClearFolder(strInboxFolder);

    for UTMString in InboxUTMList do begin
        ReplyID := UTMString.ReplyID;
        UrlAddress:= UTMString.Url;
        UrlType:= GetUrlAddressType(UrlAddress);
        FileName := GenerateGUID() + '.xml';
        NewFileName := '';
        Log('Обработка: ' + UrlAddress);
        ReturnCode:= eReturnStatus.rsUnknown;

        if not LoadFileFromUTM(UrlAddress, FileName) then begin
            Log('Файл не загружен. Возможно был удален другим документом');
            Log();
            Continue;
        end;

        if UrlType = eUrlType.utWayBill then begin
            WayBill:= Parse_WayBill(strInboxFolder + FileName);
            if WayBill = nil then Continue;
            ReturnCode:= Save_WayBill(WayBill, NewFileName);
            WayBill.Free;
        end;

        if UrlType = eUrlType.utFORMBREGINFO then begin
            WayBill:= Parse_FORMBREGINFO(strInboxFolder + FileName);
            if WayBill = nil then Continue;
            ReturnCode:= Save_FORMBREGINFO(WayBill, NewFileName);
            WayBill.Free;
        end;

        if UrlType = eUrlType.utTicket then begin
            Ticket:= Parse_Ticket(strInboxFolder + FileName);
            if Ticket = nil then Continue;
            ReturnCode:= Save_Ticket(Ticket);
            Ticket.Free;
        end;

        if ReturnCode = eReturnStatus.rsOK then begin
            SendFileToArchive(FileName, NewFileName);
            inc(DlFilesCount);
            inc(TCFilesCount);
        end

        else if ReturnCode = eReturnStatus.rsOK_noSave then begin
            inc(TCFilesCount);
        end

        else if ReturnCode = eReturnStatus.rsMoveToQuarantine then begin
            inc(TCFilesCount);
            inc(DelFilesCount);
            NewFileName:= GetEnumName(TypeInfo(eUrlType), Ord(UrlType)) +'_'+ GenerateGUID() + '.xml';
            Delete(NewFileName, 1, 2);
            SendFileToQuarantine(FileName, NewFileName);
            DeleteUTMobject(UrlAddress);
        end

        else if ReturnCode = eReturnStatus.rsDeleteOne then begin
            DeleteUTMobject(UrlAddress);
            inc(DelFilesCount);
        end

        else if ReturnCode = eReturnStatus.rsDelete then begin
            if ReplyID.IsEmpty then
                DeleteUTMobject(UrlAddress)
            else
                DeleteUTMobjectByReplyID(ReplyID);
            inc(DelFilesCount);
        end

        else if ReturnCode = eReturnStatus.rsNext then begin
            if NextList.Contains(UTMString) then begin
                Log('Этот файл уже откладывался. Переносим в карантин...');
                NewFileName:= GetEnumName(TypeInfo(eUrlType), Ord(UrlType)) + '_' + GenerateGUID() + '.xml';
                Delete(NewFileName, 1, 2);
                SendFileToQuarantine(FileName, NewFileName);
                if ReplyID.IsEmpty then
                    DeleteUTMobject(UrlAddress)
                else
                    DeleteUTMobjectByReplyID(ReplyID);
                inc(DelFilesCount);
            end else begin
                NewUTMString := TUTMstring.Create;
                NewUTMString.Url:= UrlAddress;
                NewUTMString.ReplyID:=ReplyID;
                InboxUTMList.Add(NewUTMString);
                NextList.Add(NewUTMString);
                Log('Обработка файла отложена...');
            end;
        end;

    end;

    if DlFilesCount + TCFilesCount + DelFilesCount > 0 then begin
        Log('Загружено файлов: ', DlFilesCount);
        MessageBox(Application.Handle, PWideChar('Всего обработано файлов: ' + IntToStr(TCFilesCount) + CrLf
                    + 'Загружено новых документов: ' + IntToStr(DlFilesCount div 2) + CrLf
                    + 'Удалено файлов: ' + IntToStr(DelFilesCount)), PWideChar('Загрузка документов'), MB_OK + MB_ICONINFORMATION);
        ListDocumentsToScreen();
    end
    else begin
        Log('Файлы не загружены');
        MessageBox(Application.Handle, PWideChar('Новых документов не обнаружено'), PWideChar('Загрузка документов'), MB_OK + MB_ICONINFORMATION);
    end;

    NextList.Free;
end;

function RemoveUTMaddress(FullAddress: String): String;
begin
    Result := StringReplace(FullAddress, GetUTMaddress(), '', [rfReplaceAll, rfIgnoreCase]);
end;

function GetUTMaddress(): String;
begin
    Result:= 'http://' + strUTMserver + ':' + strUTMport;
end;

procedure SaveSettings;
//Сохраняем всё в файл перед выходом из программы
begin
    if xmlCfg = nil then Exit;
    //Прочие настройки сохраняются в файл настроек
    if frmMain.Visible then begin
        if frmMain.WindowState = wsNormal then begin
             xmlCfg.SetValue('Left', frmMain.Left, 'Position');
             xmlCfg.SetValue('Top', frmMain.Top, 'Position');
             xmlCfg.SetValue('Width', frmMain.Width, 'Position');
             xmlCfg.SetValue('Height', frmMain.Height, 'Position');
             xmlCfg.SetValue('ShowLog', BoolToStr(Assigned(frmLog), True));
        end;
        xmlCfg.SetValue('Window', frmMain.WindowState, 'Position');

    end;

    xmlCfg.Save;
end;

procedure LoadSettings;
begin
    //Переменные УТМ
    strUTMserver:= xmlCfg.GetValue('UTMserver', 'localhost');
    strUTMport:= xmlCfg.GetValue('UTMport', '8080');

    //И задаем положение
    frmMain.SetBounds(xmlCfg.GetValue('Left', 200, 'Position'),
                        xmlCfg.GetValue('Top', 200, 'Position'),
                        xmlCfg.GetValue('Width', 520, 'Position'),
                        xmlCfg.GetValue('Height', 500, 'Position'));
    frmMain.WindowState:= xmlCfg.GetValue('Window', 0, 'Position');
    if frmMain.WindowState = wsMinimized then frmMain.WindowState:= wsNormal;

    frmMain.tbtnLog.Visible := xmlCfg.GetValue('ShowConsoleButton', True);

    // УТМ чекер
    if Boolean(xmlCfg.GetValue('BackgroundUTMCheck', True)) = True then
        StartUTMChecker()
    else
        StopUTMChecker();
end;

procedure WindowsOnTop(Flag: Boolean; Form: TForm);
// Поверх всех окон
begin
    // Log('Form ' + Form.Name + ' topmost:', Flag);
    with Form do
        if Flag then
            SetWindowPos(Form.Handle, HWND_TOPMOST, 0, 0, 0, 0,
              SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE)
        else
            SetWindowPos(Form.Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
end;

procedure ShowOptionsWindow();
var
    tmpCfg: TSettings;
begin
    tmpCfg:= TSettings.Create;
    tmpCfg.Assign(xmlCfg);
    if (not Assigned(frmOptions)) then frmOptions:= TfrmOptions.Create(frmMain, tmpCfg);
    if frmOptions.ShowModal = mrOk then begin
        xmlCfg.Assign(tmpCfg);     //Вариант с копированием объекта
        LoadSettings;
        //appLoc.TranslateForm(frmMain);
    end;
    tmpCfg.Free;
    FreeAndNil(frmOptions);
end;

procedure ShowRawUTMWindow();
var
    tmpCfg: TSettings;
begin
    if (not Assigned(frmRawUTM)) then frmRawUTM:= TfrmRawUTM.Create(frmMain);
    frmRawUTM.ShowModal;
    FreeAndNil(frmRawUTM);
end;

procedure ShowFilterWindow();
var
    tmpFilter: TViewDocumentsFilter;
begin
    tmpFilter:= TViewDocumentsFilter.Create;
    tmpFilter.Assign(DocFilter);
    if (not Assigned(frmFilter)) then frmFilter:= TfrmFilter.Create(frmMain, tmpFilter);
    if frmFilter.ShowModal = mrOk then begin
        DocFilter.Assign(tmpFilter);
        ListDocumentsToScreen();
    end;
    tmpFilter.Free;
    FreeAndNil(frmFilter);
end;

procedure ShowAboutWindow();
begin
    if (not Assigned(frmAbout)) then frmAbout:= TfrmAbout.Create(frmMain);
    frmAbout.ShowModal;
    FreeAndNil(frmAbout);
end;

function CheckUTM(): Boolean;
begin
    Log('Проверка УТМ сервера...');
    if CheckUTMserver() then begin
        Log('Транспортный модуль доступен');
        bOnlineMode:= True;
        Result:= True;
    end else begin
        Log('Сервер УТМ недоступен, проверьте настройки!');
        bOnlineMode:= False;
        Result:= False;
    end;
    ChangeMainFormCaption();
end;

procedure ChangeMainFormCaption();
function GetUTMStatusForCaption(): string;
begin
    if bOnlineMode then
        Result:= '[УТМ подключен]'
    else
        Result:= '[УТМ недоступен]';
end;

function GetRegStatusForCaption(): string;
begin
//    if bDefaultLicense then
//        Result:= ' - Незарегистрированная копия'
//    else
        Result:= '';
end;

begin
    if Boolean(xmlCfg.GetValue('BackgroundUTMCheck', True)) then
        frmMain.Caption:= Application.Title + ' ' + TUpdater.GetCurrentVersion + ' ' + GetUTMStatusForCaption + GetRegStatusForCaption
    else
        frmMain.Caption:= Application.Title + ' ' + TUpdater.GetCurrentVersion + ' ' + GetRegStatusForCaption;

end;

procedure CheckFolders();
procedure CheckFolder(FolderName: String);
begin
    if not DirectoryExists(FolderName) then begin
        log('Создаем каталог ' + FolderName + '...');
        if ForceDirectories(ExpandFileName(FolderName)) then log('OK');
    end;
end;
begin
    log('Проверка каталогов...');
    CheckFolder(strInboxFolder);
    CheckFolder(strArchiveFolder);
    CheckFolder(strOutboxFolder);
    CheckFolder(strBackupFolder);
    CheckFolder(strQuarantineFolder);
    CheckFolder(strLogsFolder);
end;

function LoadInboxFileList(RefreshFromServer: Boolean = False): Boolean;
var InboxStream: TMemoryStream;
var InboxList: TDictionary<String, String>;
begin
    InboxStream:= TMemoryStream.Create;
    //InboxStream.Position:=0;
    if RefreshFromServer then
        LoadStreamFromUTM(GetUTMaddress + constInboxList, InboxStream)
    else
        LoadStreamFromUTM(GetUTMaddress + constInboxList, InboxStream);
    //Log(InboxStream);
    ParseInboxList(InboxStream, InboxUTMList);

end;

function GenerateGUID(WithDash: Boolean = False): String;
var
Uid: TGuid;
Res: HResult;
begin
    Res := CreateGuid(Uid);
    if Res = S_OK then Result:=LowerCase(GuidToString(Uid));
    Result:= StringReplace(Result, '{', '', [rfReplaceAll, rfIgnoreCase]);
    Result:= StringReplace(Result, '}', '', [rfReplaceAll, rfIgnoreCase]);
    if not WithDash then Result:= StringReplace(Result, '-', '', [rfReplaceAll, rfIgnoreCase]);
end;

procedure ClearFolder(FolderName: String);
var
    fs: TSearchRec;
begin
    if FindFirst(strInboxFolder + '*.*', faAnyFile - faDirectory, fs) = 0 then begin
        repeat
            DeleteFile(strInboxFolder + fs.Name);
        until FindNext(fs) <> 0;
    end;
end;

function CheckBase(): Boolean;
var
    ConStr: String;
    ReStream: TResourceStream;
begin
try
    Log('Открытие базы...');

    if not FileExists(strBaseName) then begin
        Log('База данных не найдена. Извлечение чистой БД...');
        ReStream:= TResourceStream.Create(HInstance, 'EmptyDB', RT_RCDATA);
        ReStream.SaveToFile(strBaseName);
        ReStream.Free;
    end;

    ConStr:=   //'Provider=Microsoft.Jet.OLEDB.4.0;'+
                'Provider=Microsoft.Jet.OLEDB.4.0;' +
                'Persist Security Info=False;' +
                'Data Source=' + strBaseName +';' +
                'Jet OLEDB:Database Password="E7vPqnB764"';
    DataSet.ConnectionString:= ConStr;
    DataSetPositions.ConnectionString:= ConStr;
    DataSetProducts.ConnectionString:= ConStr;
    DataSetClients.ConnectionString:= ConStr;
    //raise Exception.Create('Error Message');
    //Пгаверочка
    SetBaseQuery(DataSet, 'select * from Documents');
    Result:= True;
except
    on e: Exception do begin
        ErrorLog(e, 'Load database', True);
        Result:= False;
    end;
end;

end;

function GetUrlAddressType(UrlAddress: String): eUrlType;
begin
    //Log(LowerCase(UrlAddress));
    //Log(Pos(LowerCase(UrlAddress), '/ticket/' ));
    if Pos('/waybill/' , LowerCase(UrlAddress)) > 0 then Result:=eUrlType.utWayBill
    else if Pos('/formbreginfo/', LowerCase(UrlAddress)) > 0 then Result:=eUrlType.utFORMBREGINFO
    else if Pos('/ticket/', LowerCase(UrlAddress)) > 0 then Result:= eUrlType.utTicket
    else if Pos('/waybillact/', LowerCase(UrlAddress)) > 0 then Result:= eUrlType.utWayBillAct
    else Result:= eUrlType.utUnknown;
end;

function GetFileTypeByFileName(FileName: String): eUrlType;
begin
    if Pos('waybill_' , LowerCase(FileName)) > 0 then Result:=eUrlType.utWayBill
    else if Pos('formbreginfo_', LowerCase(FileName)) > 0 then Result:=eUrlType.utFORMBREGINFO
    else if Pos('ticket', LowerCase(FileName)) > 0 then Result:= eUrlType.utTicket
    else Result:= eUrlType.utUnknown;
end;

function ParseDateNoTime(DateNoTimeString: String): TDate;
var
    tDate,tYear,tMonth,tDay: String;
begin
    if DateNoTimeString = '' then begin
        Result:= Now;
        Exit;
    end;
    tDate:= StringReplace(DateNoTimeString, '-', '', [rfReplaceAll]);
    tYear:= LeftStr(tDate,4);
    tMonth:= MidStr(tDate,5,2);
    tDay:=  RightStr(tDate,2);
    Result:= EncodeDate(StrToInt(tYear),StrToInt(tMonth),StrToInt(tDay));
end;

function GetDateNoTime(tDate: TDate): String;
var
    tYear,tMonth,tDay: Word;
begin
    DecodeDate(tDate,tYear,tMonth,tDay);
    Result:= Format('%.4d', [tYear]) + '-' + Format('%.2d', [tMonth]) + '-' + Format('%.2d', [tDay]);
end;

procedure ListDocumentsToScreen(WBRegID: String = '');
var
    lvItem, tmpItem: TListItem;
begin

    Log('Рендер списка документов...');
    tmpItem := frmMain.lvMain.Selected;

    frmMain.lvMain.Clear;
    SetBaseQuery(DataSet, 'select DocName, DocStatus, DocType, DocResult, DocumentDate, WBRegId from Documents '
                + GetStatusFilterQueryString() + ' order by DocumentDate');
    if DataSet.RecordCount = 0 then begin
        frmMain.lvMain.Visible:= False;
        frmMain.lblEmpty.Visible:=True;
        Exit
    end else begin
        frmMain.lblEmpty.Visible:=False;
        LockWindowUpdate(frmMain.lvMain.Handle);
        frmMain.lvMain.Visible:=False;
        while not DataSet.Eof do begin
            lvItem:= frmMain.lvMain.Items.Add;
            lvItem.ImageIndex:= DataSet['DocType'] - 1;
            lvItem.Caption:= DateToStr(DataSet['DocumentDate']);
            lvItem.SubItems.Append(DataSet['DocName']);
            lvItem.SubItems.Append(VarToStr(DataSet['WBRegId']));
            lvItem.SubItems.Append(TEgaisDocument.GetHumanityStatusName(DataSet.FieldByName('DocStatus').AsInteger));
            //if not VarIsNull(DataSet['DocResult']) then
            lvItem.SubItems.Append(TEgaisDocument.GetHumanityeDocResultName(DataSet.FieldByName('DocResult').AsInteger));
            //lvItem.SubItemImages[0]:=0;
            DataSet.Next;
        end;
        frmMain.lvMain.Visible:= True;
        LockWindowUpdate(0);

        if tmpItem <> nil then
            begin
            tmpItem.Selected:= true;
            tmpItem.MakeVisible(false);
            frmMain.lvMain.SetFocus;
            end;
    end;
end;

function SendFileToArchive(FileName: String; NewFileName: String = ''): Boolean;
begin
    if NewFileName = '' then NewFileName:= FileName;
    Log('Перемещаем в архив файл: ' + NewFileName);
    Result:= MoveFile(PWideChar(strInboxFolder + FileName), PWideChar(strArchiveFolder + NewFileName))
            OR MoveFile(PWideChar(strOutboxFolder + FileName), PWideChar(strArchiveFolder + NewFileName));
end;

function SendFileToQuarantine(FileName: String; NewFileName: String = ''): Boolean;
begin
    if NewFileName = '' then NewFileName:= FileName;
    Log('Перемещаем в карантин файл: ' + NewFileName);
    Result:= MoveFile(PWideChar(strInboxFolder + FileName), PWideChar(strQuarantineFolder + NewFileName))
            OR MoveFile(PWideChar(strOutboxFolder + FileName), PWideChar(strQuarantineFolder + NewFileName));

end;

function GetDocumentByNumber(WBNumber: String): TEgaisDocument;
begin
    SetBaseQuery(DataSet, 'select * from Documents where WBRegId = ''' + WBNumber + '''');
    if DataSet.RecordCount = 0 then begin
        Log('Накладная с номером ' + WBNumber + ' не найдена');
        Result:=nil;
        Exit;
    end;
    Result:= Parse_WayBill(strArchiveFolder + DataSet['FileName']);
    Result.DocumentType:= DataSet['DocType'];
    Result.DocumentStatus:= DataSet['DocStatus'];
    Result.SystemComment:= DataSet['LastComment'];

    if not DataSet.FieldByName('RegInfoName').AsString.IsEmpty then
        Result:= Parse_FORMBREGINFO(strArchiveFolder + DataSet['RegInfoName'], Result);

end;

procedure ShowWayBillWindow(WBNumber: String);
var
    Doc: TEgaisDocument;
    DialogResult: Integer;
    ActStatus: eReturnStatus;
begin
    Doc:= GetDocumentByNumber(WBNumber);
    ActStatus:= eReturnStatus.rsUnknown;
    if Doc = nil then Exit;
    if (not Assigned(frmWBview)) then frmWBview:= TfrmWBview.Create(frmMain, Doc);
    DialogResult:= frmWBview.ShowModal;
    case DialogResult of
        mrYesToAll: ActStatus:= SendAcceptAct(Doc);
        mrNo: ActStatus:= SendRejectAct(Doc);
        mrNoToAll: ActStatus:= SendEditAct(Doc);
    end;

    if ActStatus = eReturnStatus.rsOK then
        MessageBox(frmMain.Handle, PWideChar('Акт отправлен поставщику!'), PWideChar('Успешная отправка'),
                       MB_OK + MB_ICONINFORMATION);
    if ActStatus = eReturnStatus.rsError then
        MessageBox(frmMain.Handle, PWideChar('Не удалось отправить акт!'), PWideChar('Неудачная отправка'),
                       MB_OK + MB_ICONWARNING);
    FreeAndNil(frmWBview);
    FreeAndNil(Doc);

    if DialogResult = mrRetry then CreateReturn(WBNumber);
end;

function GetStatusFilterQueryString(): String;
begin
    if DocFilter.Inbox and DocFilter.Outbox then
        Result:= ''
    else if DocFilter.Inbox then
        Result:= Result + 'DocType = 1 '
    else if DocFilter.Outbox then
            Result:= Result + 'DocType = 2 ';

    if Result = '' then
            Result:= Result + 'DocumentDate >= CDate(''' + DateToStr(DocFilter.DateStart) + ''')'
        else
            Result:= '(' + Trim(Result) + ') and DocumentDate >= CDate(''' + DateToStr(DocFilter.DateStart) + ''')';
    Result:= 'where ' + Result + ' and DocumentDate <= CDate(''' + DateToStr(DocFilter.DateEnd) + ''')';
    //Result:= 'where DocumentDate <= CDate(''' + DateToStr(DocFilter.DateEnd) + ''')';

end;

function SendAcceptAct(WayBill: TEgaisDocument): eReturnStatus;
var
    xmlActStream: TMemoryStream;
    ServerAnswer, ReplyID: String;
begin
    if not bOnlineMode then begin
        if not CheckUTM then begin
            ShowMessageUTMoffline();
            Exit;
        end
    end;

    Log('Отправка акта подтверждения...');
    if WayBill.DocumentStatus <> eEgaisDocumentStatus.edsLoaded then begin
        Log('Процедура допустима только для документов со статусом Загружено');
        Result:= eReturnStatus.rsError;
        Exit;
    end;

    xmlActStream:= CreateAcceptAct(WayBill);
    if xmlActStream = nil then begin
        Log('Не удалось сформировать акт');
        Result:= eReturnStatus.rsError;
        Exit;
    end;

    if not SendStreamToUTM(GetUTMAddress() + constActSendUrl, xmlActStream, ServerAnswer) then begin
        Log('Всё пропало, шеф! Всё пропало!');
        Result:= eReturnStatus.rsError;
    end else begin
        ReplyID:= ParseServerAnswer(ServerAnswer);
        Log('Присвоен идентификатор: ' + ReplyID);
        WayBill.ReplyID:= ReplyID;
        WayBill.DocumentStatus:= eEgaisDocumentStatus.edsActUploaded;
        WayBill.DocumentResult:= eEgaisDocumentResult.edrActAccept;
        WayBill.SystemComment:= 'Акт подтверждения успешно отправлен';
        Save_ReplyID(WayBill);
        ListDocumentsToScreen();
        Log('Отправка акта ...OK');
        Result:= eReturnStatus.rsOK;
    end;
    xmlActStream.Free;

end;

function SendRejectAct(WayBill: TEgaisDocument): eReturnStatus;
var
    xmlActStream: TMemoryStream;
    ServerAnswer, ReplyID: String;
begin
    if not bOnlineMode then begin
        if not CheckUTM then begin
            ShowMessageUTMoffline();
            Exit;
        end
    end;

    Log('Отправка акта отказа...');
    if WayBill.DocumentStatus <> eEgaisDocumentStatus.edsLoaded then begin
        Log('Процедура допустима только для документов со статусом Загружено');
        Result:= eReturnStatus.rsError;
        Exit;
    end;

    xmlActStream:= CreateRejectAct(WayBill);
    if xmlActStream = nil then begin
        Log('Не удалось сформировать акт');
        Result:= eReturnStatus.rsError;
        Exit;
    end;

    if not SendStreamToUTM(GetUTMAddress() + constActSendUrl, xmlActStream, ServerAnswer) then begin
        Log('Всё пропало, шеф! Всё пропало!');
        Result:= eReturnStatus.rsError;
    end else begin
        ReplyID:= ParseServerAnswer(ServerAnswer);
        Log('Присвоен идентификатор: ' + ReplyID);
        WayBill.ReplyID:= ReplyID;
        WayBill.DocumentStatus:= eEgaisDocumentStatus.edsActUploaded;
        WayBill.DocumentResult:= eEgaisDocumentResult.edrActReject;
        WayBill.SystemComment:= 'Акт отказа успешно отправлен';
        Save_ReplyID(WayBill);
        ListDocumentsToScreen();
        Log('Отправка акта ...OK');
        Result:= eReturnStatus.rsOK;
    end;
    xmlActStream.Free;
end;

function SendEditAct(WayBill: TEgaisDocument): eReturnStatus;
var
    xmlActStream: TMemoryStream;
    ServerAnswer, ReplyID: String;
begin
    if not bOnlineMode then begin
        if not CheckUTM then begin
            ShowMessageUTMoffline();
            Exit;
        end
    end;

try
    Log('Составление акта расхождения...');
    if WayBill.DocumentStatus <> eEgaisDocumentStatus.edsLoaded then begin
        Log('Процедура допустима только для документов со статусом Загружено');
        Exit;
    end;

    if (not Assigned(frmActEdit)) then frmActEdit:= TfrmActEdit.Create(frmMain, WayBill);
    if frmActEdit.ShowModal = mrOk then begin

        xmlActStream:= CreateEditAct(WayBill);
        if xmlActStream <> nil then begin

            if not SendStreamToUTM(GetUTMAddress() + constActSendUrl, xmlActStream, ServerAnswer) then begin
                Log('Всё пропало, шеф! Всё пропало!');
                Result:= eReturnStatus.rsError;
            end else begin
                ReplyID:= ParseServerAnswer(ServerAnswer);
                Log('Присвоен идентификатор: ' + ReplyID);
                WayBill.ReplyID:= ReplyID;
                WayBill.DocumentStatus:= eEgaisDocumentStatus.edsActUploaded;
                WayBill.DocumentResult:= eEgaisDocumentResult.edrActEdit;
                WayBill.SystemComment:= 'Акт расхождения успешно отправлен';
                Save_ReplyID(WayBill);
                ListDocumentsToScreen();
                Log('Отправка акта ...OK');
                Result:= eReturnStatus.rsOK;
            end;
            xmlActStream.Free;
        end else begin
            Log('Не удалось сформировать акт расхождений');
            Result:= eReturnStatus.rsError;
        end;
    end;
finally
    FreeAndNil(frmActEdit);
end;
end;

function GetOurFSRARID(): String;
var
    posValue: String;
    curValue: String;
begin
//    if not bRegStatus then begin
//        NeedRegisterMessage();
//        Exit;
//    end;

    if bDefaultLicense then begin
        curValue:= Trim(VarToStr(xmlCfg.GetValue('FSRARID', '')));
        if (curValue <> '') and (Length(curValue) = 12) then begin
            Result:= curValue;
            Exit;
        end;

        posValue:= ParseFSRARIDfromUTM();
        if posValue = '' then Exit;

        if MessageBox(Application.Handle, PWideChar('Похоже в настройках не заполнен ваш номер FSRAR_ID' + CrLf
                       + 'Попробуем взять его из УТМ: ' + posValue + '?' + CrLf
                       + 'Вы всегда можете поменять значение из настроек'), PWideChar('Не заполнен FSRAR_ID'),
                       MB_YESNO + MB_ICONQUESTION) = mrNo then Exit;
        xmlCfg.SetValue('FSRARID', posValue);
        xmlCfg.Save;
        Result:= posValue;
    end else begin
        if CheckRegIDtoLicense(posValue) then
            Result:= posValue;
    end;
end;

function QuantityToInt(Quantity:String): Integer;
var
    DotPosition: Integer;
begin
    try
        if Quantity = '' then begin
            Result:=0;
            Exit;
        end;
        DotPosition:= Pos('.', Quantity);
        if DotPosition > 0 then
            Result:= StrToInt(LeftStr(Quantity, DotPosition - 1))
        else
            Result:= StrToInt(Quantity);
    finally

    end;
end;

function ParseLicense(FileName: String; out Lic: TLicenseData): Boolean;
var
    Stream, CryStream: TMemoryStream;
    TextStream: TStringStream;
    //Lic: TLicenseData;
    CryLicense: TCryptedLicense;
    HideKey:String[32];
begin
    try
    Stream:= TMemoryStream.Create();
    CryStream:=TMemoryStream.Create();
    TextStream:= TStringStream.Create();

    Stream.LoadFromFile(FileName);
    //Log(Stream,0, 'File');
    Stream.Read(CryLicense, SizeOf(CryLicense));
    CryStream.Write(CryLicense.sign, SizeOf(CryLicense.sign));
    //Log(CryLicense.sign);

    UnCryptStream(CryStream, TextStream, Key, 32);
    TextStream.Size:=32;
    //Log(TextStream, 0, 'CryKEYGUID');
    TextStream.SaveToFile('c:\1.bin');

    HideKey := TextStream.ReadString(32);
    //Log(HideKey);
    Stream.Clear;
    CryStream.Clear;
    CryStream.Write(CryLicense.data, SizeOf(CryLicense.data));
    UnCryptStream(CryStream, Stream, HideKey, 32);
    //Log(Stream);
    Stream.Read(Lic, SizeOf(TLicenseData));
    if Lic.Key = HideKey then
        Result:= True;
    //Log(Lic.RegId[0]);
    finally
    Stream.Free;
    CryStream.Free;
    TextStream.Free;
    end;
end;

function CheckLicense(): Boolean;
var
    fs: TSearchRec;
    tempLicense: TLicenseData;
    z:Char;
begin
    //Log('Проверка лицензии...');
    bDefaultLicense:=True;
    z:= Chr(45);
//    if FindFirst(strLicenseFolder + '*.lic', faAnyFile - faDirectory, fs) = 0 then
//        repeat begin
//            bDefaultLicense:= not ParseLicense(strLicenseFolder + fs.Name, tempLicense);
//            if not bDefaultLicense then begin
//                if tempLicense.EndDate > Date then begin
//                    frmMain.tmrReg.Enabled:=True;
//                    License:= tempLicense;
//                    Break;
//                end
//            end;
//        end until FindNext(fs) <> 0
//    else
    Log('Лицензий не найдено');
    //if YearOf(Now) = 2000 + (ord(z) div 3) then
    bRegStatus:= True;
    ChangeMainFormCaption;
    Result:= True;
end;

function CheckRegIDtoLicense(Value: String): Boolean;
var
  i: Integer;
begin
    for i := 0 to 9 do begin
        if Value = License.RegId[i] then begin
            Result:=True;
            Exit;
        end;
    end;
    MessageBox(Application.Handle, PWideChar('Вы пытаетесь использовать Клиентский идентификатор отличный' + CrLf
                            +' от вашей лицензии. Проверьте настройки на правильность FSRAR_ID '), PWideChar('Предупреждение'), MB_OK+ MB_ICONWARNING);
    Result:= False;
end;

procedure NeedRegisterMessage();
begin
    MessageBox(Application.Handle, PWideChar('Для выполнения этого действия нужна регистрация!'), PWideChar('Предупреждение'), MB_OK+ MB_ICONWARNING);
end;

procedure GoToWebPage(Url: string);
begin
    ShellExecute(Application.Handle, 'open', PWideChar(Url), nil, nil, SW_NORMAL );
end;

procedure ShowMessageUTMoffline();
begin
    MessageBox(frmMain.Handle, PWideChar('Транспортный модуль недоступен' + CrLf +
                                        'Попробуйте перезапустить службы обновления и транспорта' + CrLf +
                                        'Проверьте подключение ключа шифрования (JaCarta)' + CrLf +
                                        'Если для транспорта используется не локальный компьютер,' + CrLf +
                                        'убедитесь в его доступности в сети'), PWideChar('Ошибка подключения к УТМ'), MB_ICONWARNING);
end;

function SendWBrequest(Identifier: String): eReturnStatus;
var
    xmlReqStream: TMemoryStream;
    ServerAnswer, ReplyID: String;
begin
    Log('Отправка запроса на накладную...');

    xmlReqStream:= CreateWBRequest(Identifier);
    if xmlReqStream = nil then begin
        Log('Не удалось сформировать запрос');
        Result:= eReturnStatus.rsError;
        Exit;
    end;

    if not SendStreamToUTM(GetUTMAddress() + constWBResendUrl, xmlReqStream, ServerAnswer) then begin
        Log('Всё пропало, шеф! Всё пропало!');
        Result:= eReturnStatus.rsError;
    end else begin
        ReplyID:= ParseServerAnswer(ServerAnswer);
        Log('Присвоен идентификатор: ' + ReplyID);
        Log('Отправка запроса ...OK');
        Result:= eReturnStatus.rsOK;
    end;
    xmlReqStream.Free;

end;

procedure WayBillRequest();
var
    Doc: TEgaisDocument;
    DialogResult: Integer;
    Status: eReturnStatus;
begin
    if (not Assigned(frmWBrequest)) then frmWBrequest:= TfrmWBrequest.Create(frmMain);
    DialogResult:= frmWBrequest.ShowModal;
    if DialogResult = mrCancel then
        Log('Перезапрос накладной отменен')
    else begin
        Status:= SendWBrequest('TTN-' + frmWBrequest.txtWBIdentifier.Text);

    if Status = eReturnStatus.rsOK then
        MessageBox(frmMain.Handle, PWideChar('Запрос повторной отправки накладной успешно отправлен!'), PWideChar('Успешная отправка'),
                       MB_OK + MB_ICONINFORMATION);
    if Status = eReturnStatus.rsError then
        MessageBox(frmMain.Handle, PWideChar('Ошибка отправки запроса!'), PWideChar('Неудачная отправка'),
                       MB_OK + MB_ICONWARNING);
    end;
    FreeAndNil(frmWBrequest);
end;

procedure ShowLogForm();
begin
	if Assigned(frmLog) and frmLog.Visible then begin
          	FreeAndNil(frmLog);
        	frmMain.tbtnLog.Down:=False;
        end
    else begin
        frmLog:=  TfrmLog.Create(nil);
                frmLog.SetBounds(
        				frmMain.Left + frmMain.Width,
        				frmMain.Top,
						frmLog.Width,
        				frmMain.Height);
        frmLog.lbLog.Items:=LogList;
        frmLog.lbLog.ItemIndex:=frmLog.lbLog.Items.Count-1;
        frmLog.Show;
        bLogDocked:=True;
        frmMain.tbtnLog.Down:=True;
        frmLog.tmrLog.OnTimer(nil);
    end;
end;

function ParseFSRARIDfromUTM(): String;
var
    Str: String;
    Posi: Integer;
begin
    Result:= '';
    if not bOnlineMode then Exit;
    if not LoadStringFromUTM(GetUTMaddress(), Str) then Exit;
    Posi := Pos('FSRAR-RSA-', Str);
    if Posi > 0 then
        Str:= Copy(Str, Posi + 10);
        Str:= Copy(Str,1, Pos(Chr(32), Str) - 1);

    if Posi > 0 then
        Result:= Str
    else
        Log('Не удалось определелить идентификатор FSRARID');

end;

function SendReturn(WayBill: TEgaisDocument): eReturnStatus;
var
    xmlRetStream: TMemoryStream;
    ServerAnswer, ReplyID: String;
    NewFileName: String;
begin

    xmlRetStream:= CreateReturnAct(WayBill);
    //xmlRetStream:= CreateAcceptAct(WayBill);
    if xmlRetStream = nil then begin
        Log('Не удалось сформировать акт');
        Result:= eReturnStatus.rsError;
        xmlRetStream.Free;
        Exit;
    end;

    if not SendStreamToUTM(GetUTMAddress() + constWBSendUrl, xmlRetStream, ServerAnswer) then
        begin
        Log('Всё пропало, шеф! Всё пропало!');
        Result:= eReturnStatus.rsError;
        end
    else
        begin
        ReplyID:= ParseServerAnswer(ServerAnswer);
        Log('Присвоен идентификатор: ' + ReplyID);
        WayBill.ReplyID:= ReplyID;
        WayBill.SystemComment:= 'Накладная успешно отправлена';
        WayBill.DocumentStatus:= edsUploaded;
        WayBill.DocumentType:= edtOutbox;
        Save_WayBill(WayBill, NewFileName);
        xmlRetStream.SaveToFile(strArchiveFolder + NewFileName);
        Result:= eReturnStatus.rsOK;
        Log('Отправка возврата ...OK');
        end;
    xmlRetStream.Free;

end;

procedure CreateReturn(WBNumber: string);
var
    Doc: TEgaisDocument;
    tmpOrg: TContragent;
    DialogResult: Integer;
begin

    if not bOnlineMode then begin
        if not CheckUTM then begin
            ShowMessageUTMoffline();
            Exit;
        end
    end;

    Doc:= GetDocumentByNumber(WBNumber);
    if Doc = nil then Exit;
    tmpOrg:= TContragent.Create;
    tmpOrg.Assign(Doc.Shipper);
    Doc.Shipper.Assign(Doc.Consignee);
    Doc.Consignee.Assign(tmpOrg);

    Doc.DocumentType:= edtOutbox;
    Doc.Identity:= GenerateGUID(True);
    Doc.DocumentDate:= Date();
    Doc.TTNType:= 2;
    Doc.SystemComment:='';

    if (not Assigned(frmReturn)) then frmReturn:= TfrmReturn.Create(frmMain, Doc);
    DialogResult:= frmReturn.ShowModal;
    if DialogResult = mrOk then
        begin
        if SendReturn(Doc) = eReturnStatus.rsOK then
            begin
            DocFilter.Inbox:= False;
            DocFilter.Outbox:= True;
            ListDocumentsToScreen(Doc.REGINFO.WBRegId);
            MessageBox(frmMain.Handle, PWideChar('Возврат успешно отправлен!'), PWideChar('Успешная отправка'),
                       MB_OK + MB_ICONINFORMATION);
            end;
        end;

    FreeAndNil(frmReturn);
    FreeAndNil(Doc);
end;

end.

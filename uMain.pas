unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.Grids, Vcl.DBGrids, Vcl.XPMan,


  uLogic, uAbout, Vcl.ToolWin, System.ImageList, Vcl.ImgList, Vcl.Menus,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  Data.Win.ADODB, Vcl.StdCtrls;

type
  TfrmMain = class(TForm)
    imlListView: TImageList;
    menuQuickStatus: TPopupMenu;
    mnuQuickFilterAll: TMenuItem;
    mnuQuickFilterInbox: TMenuItem;
    mnuQuickFilterOutbox: TMenuItem;
    lvMain: TListView;
    N1: TMenuItem;
    mnuShowFilter: TMenuItem;
    lblEmpty: TStaticText;
    pnlToolBar: TPanel;
    ToolBarHelp: TToolBar;
    ToolButton11: TToolButton;
    tbtnDownload: TToolButton;
    tbtnRefresh: TToolButton;
    ToolButton2: TToolButton;
    ToolButton1: TToolButton;
    tbtnOptions: TToolButton;
    ToolButton9: TToolButton;
    tbtnLog: TToolButton;
    mnuQuickFilterToday: TMenuItem;
    tmrReg: TTimer;
    imlQuickStatus: TImageList;
    menuHelp: TPopupMenu;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    ToolButton3: TToolButton;
    imlToolBarDisabled: TImageList;
    menuService: TPopupMenu;
    menuUTMLists: TMenuItem;
    mnuShowConsole: TMenuItem;
    mnuWBrequest: TMenuItem;
    mnuQuickFilterMonth: TMenuItem;
    N2: TMenuItem;
    procedure WMSysCommand(var Msg: TWMSysCommand)  ; message WM_SYSCOMMAND;    //Отлавливает максимизацию формы
    procedure OnMove(var Msg: TWMMove)              ; message WM_MOVE;
    procedure tbtnLogClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure tbtnOptionsClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ToolButton1Click(Sender: TObject);
    procedure tbtnDownloadClick(Sender: TObject);
    procedure tbtnRefreshClick(Sender: TObject);
    procedure lvMainDblClick(Sender: TObject);
    procedure tbtnHelpClick(Sender: TObject);
    procedure tmrUTMCheckTimer(Sender: TObject);
    procedure mnuShowFilterClick(Sender: TObject);
    procedure tmrRegTimer(Sender: TObject);
    procedure ToolButton3Click(Sender: TObject);
    procedure tmrCloseTimer(Sender: TObject);
    procedure mnuQuickFilterAllClick(Sender: TObject);
    procedure mnuQuickFilterInboxClick(Sender: TObject);
    procedure mnuQuickFilterOutboxClick(Sender: TObject);
    procedure mnuQuickFilterTodayClick(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem7Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure menuUTMListsClick(Sender: TObject);
    procedure mnuWBrequestClick(Sender: TObject);
    procedure mnuShowConsoleClick(Sender: TObject);
    procedure tbtnLogContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure mnuQuickFilterMonthClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation
uses uLog, uConsole, uUpdater;
{$R *.dfm}

{$REGION '#Открытие-закрытие формы'}
procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
        CanClose:= (MessageBox(Self.Handle, PWideChar('Завершить работу с программой?'), PWideChar(Application.Title), MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) = mrYes);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
    //Назначаем лже-сплиттеру действие на даблклик, в дизайнере нельзя
    //Splitter.OnDblClick:= SplitterDblClick;
    //Эта процедура устраняет мерцание при ресайзе формы
    //SetWindowLongPtr(tabMain.Handle, GWL_EXSTYLE,
    //GetWindowLongPtr(tabMain.Handle, GWL_EXSTYLE) or WS_EX_COMPOSITED);
    if not InitGlobal then
        frmMain.Close;
    //Задаём внешний вид меню
    //RyMenu.MinWidth:=200;
    //RyMenu.Add(menuMain, nil);
    //RyMenu.Add(menuTreePopup, nil);
end;
procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    SaveSettings;
    DestroyObjects;
    Application.Terminate;
end;
{$ENDREGION}

{$REGION '#Открытие модальных окошек'}
procedure TfrmMain.tbtnOptionsClick(Sender: TObject);
begin
    ShowOptionsWindow;
end;
procedure TfrmMain.tbtnRefreshClick(Sender: TObject);
begin
    ListDocumentsToScreen();
end;

procedure TfrmMain.tmrCloseTimer(Sender: TObject);
begin
    Close();
end;

procedure TfrmMain.tmrRegTimer(Sender: TObject);
begin
    bRegStatus:= tmrReg.Enabled;
    ChangeMainFormCaption;
    tmrReg.Enabled:= False;
end;

procedure TfrmMain.tmrUTMCheckTimer(Sender: TObject);
begin
    Log('Фоновая проверка УТМ...');
    CheckUTM();
end;

procedure TfrmMain.ToolButton1Click(Sender: TObject);
begin
    ShowFilterWindow();
end;

procedure TfrmMain.ToolButton3Click(Sender: TObject);
begin
    //MessageBox();
end;

//Открытие формы Логирования.
//Код логирования переехал в Logic
procedure TfrmMain.tbtnDownloadClick(Sender: TObject);
begin
    StartDownload();
end;

procedure TfrmMain.tbtnHelpClick(Sender: TObject);
begin
    ShowAboutWindow();
end;

procedure TfrmMain.tbtnLogClick(Sender: TObject);
begin
    tbtnLog.Down:=True;
    with TToolButton(Sender), ClientToScreen(Point(0, Height)) do
        menuService.Popup(x, y);
    //tbtnLog.CheckMenuDropdown;
end;
procedure TfrmMain.tbtnLogContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin

end;

{$ENDREGION}

{$REGION '#Прилипание формы лога к краю основной и всяческие ресайзы'}
procedure TfrmMain.OnMove(var Msg: TWMMove);
begin
    if Assigned(frmLog) {and bLogDocked} then
      frmLog.tmrLog.OnTimer(nil);
end;

{
    procedure TfrmMain.SplitterDblClick(Sender: TObject);
    begin
        //По двойному щелчку панель переходит
        //из любого состояния в отношение 2:5
        //А если она уже в нём, то скрывается вправо
        if (pnlTree.Width <> tabMain.ClientWidth div 5 * 2) then
            pnlTree.Width:= tabMain.ClientWidth div 5 * 2
        else
            pnlTree.Width:= tabMain.ClientWidth - 17;
    end;
}
procedure TfrmMain.FormResize(Sender: TObject);
begin
    if Assigned(frmLog) and bLogDocked then
    	frmLog.tmrLog.OnTimer(nil);
    //Log(Self.Width);
    lblEmpty.SetBounds((frmMain.Width - lblEmpty.Width) div 2,
        (frmMain.Height - lblEmpty.Height) div 2,
        lblEmpty.Width,
        lblEmpty.Height);
end;
procedure TfrmMain.lvMainDblClick(Sender: TObject);
begin
    if lvMain.Items.Count = 0 then Exit;
    if lvMain.Selected = nil then Exit;

    ShowWayBillWindow(lvMain.Selected.SubItems.Strings[1]);
    //ShowWayBillView(lvMain.);
end;

procedure TfrmMain.MenuItem4Click(Sender: TObject);
begin
    GoToWebPage(strUrlWebpage);
end;

procedure TfrmMain.MenuItem5Click(Sender: TObject);
begin
    GoToWebPage(strUrlVKpage);
end;

procedure TfrmMain.MenuItem7Click(Sender: TObject);
begin
    ShowAboutWindow();
end;

procedure TfrmMain.menuUTMListsClick(Sender: TObject);
begin
    ShowRawUTMWindow();
end;

procedure TfrmMain.mnuQuickFilterOutboxClick(Sender: TObject);
begin
    DocFilter.ClearFilter;
    DocFilter.Outbox:= True;
    ListDocumentsToScreen();
end;

procedure TfrmMain.mnuQuickFilterAllClick(Sender: TObject);
begin
    DocFilter.ClearFilter;
    DocFilter.Inbox:= True;
    DocFilter.Outbox:= True;
    ListDocumentsToScreen();
end;

procedure TfrmMain.mnuQuickFilterInboxClick(Sender: TObject);
begin
    DocFilter.ClearFilter;
    DocFilter.Inbox:= True;
    ListDocumentsToScreen();
end;

procedure TfrmMain.mnuQuickFilterMonthClick(Sender: TObject);
begin
    DocFilter.DateStart:= IncMonth(Date, -1);
    DocFilter.DateEnd:= Date;
    ListDocumentsToScreen();
end;

procedure TfrmMain.mnuQuickFilterTodayClick(Sender: TObject);
begin
    DocFilter.DateStart:= Date;
    DocFilter.DateEnd:= Date;
    ListDocumentsToScreen();
end;

procedure TfrmMain.mnuShowConsoleClick(Sender: TObject);
begin
    ShowLogForm();
end;

procedure TfrmMain.mnuShowFilterClick(Sender: TObject);
begin
    ShowFilterWindow();
end;

procedure TfrmMain.mnuWBrequestClick(Sender: TObject);
begin
    WayBillRequest();
end;

procedure TfrmMain.WMSysCommand;
begin
    if (Msg.CmdType = SC_MAXIMIZE) then
        SaveSettings;
    DefaultHandler(Msg) ;
end;
{$ENDREGION}

end.

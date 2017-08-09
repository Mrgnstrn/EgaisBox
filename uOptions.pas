{На каждый чекбокс или другой элемент опций вешается процедура,
которая записывает его состояние во временный конфиг
Запись имён опций ведется по хинту с валидным для ini именем опции}

unit uOptions;

interface

uses
Windows, SysUtils, Classes, FileCtrl, Controls, Forms, StdCtrls, Vcl.ComCtrls,
uSettings, uLog, System.ImageList, Vcl.ImgList, Vcl.Buttons, Vcl.Menus,
  Vcl.Imaging.pngimage, Variants, Vcl.ExtCtrls;

type
  TfrmOptions = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    btnOK: TButton;
    chkMakeBackups: TCheckBox;
    imlOptions: TImageList;
    btnCancel: TButton;
    lblBackupsCount: TLabel;
    udBackupsCount: TUpDown;
    txtBackupsCount: TEdit;
    btnBackupNow: TButton;
    Label2: TLabel;
    TabSheet5: TTabSheet;
    txtUTMserver: TEdit;
    Label5: TLabel;
    txtUTMport: TEdit;
    Label6: TLabel;
    btnCheckUTMdata: TSpeedButton;
    chkDontDel: TCheckBox;
    imgDontDel: TImage;
    bhOptions: TBalloonHint;
    imgConsoleButton: TImage;
    chkGenNewPass: TCheckBox;
    imgAutoAccept: TImage;
    CheckBox2: TCheckBox;
    imgHideToTray: TImage;
    CheckBox3: TCheckBox;
    lblFSRARIDinfo: TLabel;
    lblFSRARID: TLabel;
    txtFSRARID: TEdit;
    ParseFSRARID: TSpeedButton;
    CheckBox1: TCheckBox;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    constructor Create(AOwner: TComponent; tempSettings: TSettings); reintroduce;
    procedure ChangeValue(Sender: TObject);
    procedure udBackupsCountClick(Sender: TObject; Button: TUDBtnType);
    procedure btnSelBackupFolderClick(Sender: TObject);
    procedure chkMakeBackupsClick(Sender: TObject);
    procedure btnBackupNowClick(Sender: TObject);
    procedure txtBackupFoldeExit(Sender: TObject);
    procedure txtBackupFolderChange(Sender: TObject);
    procedure btnAssociateFilesClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure ShowBalloonHint(Control: TControl;Title: String; Text: String);
    procedure imgDontDelClick(Sender: TObject);
    procedure imgConsoleButtonClick(Sender: TObject);
    procedure btnCheckUTMdataClick(Sender: TObject);
    procedure imgAutoAcceptClick(Sender: TObject);
    procedure imgHideToTrayClick(Sender: TObject);
    procedure ParseFSRARIDClick(Sender: TObject);
  private
    { Private declarations }
    Cfg: TSettings;
    procedure ReadConfiguration;
  public
    { Public declarations }
  end;

var
  frmOptions: TfrmOptions;

implementation
uses uLogic, uUTM;
{$R *.dfm}

procedure TfrmOptions.btnSelBackupFolderClick(Sender: TObject);
var
    ChosenDir: String;
begin
//    //ChosenDir:= ExtractFilePath(Application.ExeName);
//    if SelectDirectory(rsSelectBackupDirectoryDialog, '', ChosenDir) then
//        txtBackupFolder.Text:=ChosenDir;
end;

procedure TfrmOptions.ChangeValue(Sender: TObject);
begin
    if not Self.Visible then Exit;
    if (Sender is TCheckBox) then
        with (Sender as TCheckBox) do Cfg.SetValue(Hint, BoolToStr(Checked, True));
    if (Sender is TEdit) then
        with (Sender as TEdit) do Cfg.SetValue(Hint, Text);
    if (Sender is TUpDown) then
        with (Sender as TUpDown) do Cfg.SetValue(Hint, Position);
    if (Sender is TComboBox) then
        with (Sender as TComboBox) do begin
//            if Hint = 'Language' then                                           //Особый случай, нужен не индекс а имя
//                Cfg.SetValue(Hint, appLoc.Languages[ItemIndex].ShortName)
//            else
//                Cfg.SetValue(Hint, ItemIndex);
        end;
end;

procedure TfrmOptions.chkMakeBackupsClick(Sender: TObject);
begin
//    txtBackupFolder.Enabled:= chkMakeBackups.Checked or chkMakeBackupsCh.Checked;
//    btnSelBackupFolder.Enabled:= chkMakeBackups.Checked or chkMakeBackupsCh.Checked;
//    txtBackupsCount.Enabled:= chkMakeBackups.Checked or chkMakeBackupsCh.Checked;
//    udBackupsCount.Enabled:= chkMakeBackups.Checked or chkMakeBackupsCh.Checked;
//    lblBackupFolder.Enabled:= chkMakeBackups.Checked or chkMakeBackupsCh.Checked;
//    lblBackupsCount.Enabled:= chkMakeBackups.Checked or chkMakeBackupsCh.Checked;
//    ChangeValue(Sender);
end;

constructor TfrmOptions.Create(AOwner: TComponent; tempSettings: TSettings);
begin
    inherited Create(AOwner);
    Cfg:= tempSettings;
    ReadConfiguration;
end;

procedure TfrmOptions.ReadConfiguration;

procedure ReadValues(Com: TComponent);

//(RootNode.ChildNodes.FindNode(Section) <> nil)
begin
    if Com is TCheckBox then with (Com as TCheckBox) do
        if Cfg.HasOption(Hint) then
            Checked:= Boolean(Cfg.GetValue(Hint, False));
    if Com is TEdit then with (Com as TEdit) do
        if Cfg.HasOption(Hint) then
            Text:= VarToStr(Cfg.GetValue(Hint, ''));
    if Com is TUpDown then with (Com as TUpDown) do
        if Cfg.HasOption(Hint) then
            Position:= Integer(Cfg.GetValue(Hint, Min));
end;

var i: Integer;
begin
    //Заполняем чекбоксы в соответствии с текущими настройками.
    for i := 0 to Self.ComponentCount - 1 do ReadValues(Self.Components[i]);
end;

procedure TfrmOptions.txtBackupFolderChange(Sender: TObject);
var
    fullPath: String;
begin
    //CheckBackupFolder(txtBackupFolder.Text, fullPath);
    //btnSelBackupFolder.Hint:= 'Current path: ' + fullPath;
    //bhBackup.Description := fullPath;
end;

procedure TfrmOptions.txtBackupFoldeExit(Sender: TObject);
var
    fullPath: String;
begin
{
        if not CheckBackupFolder(txtBackupFolder.Text, fullPath, True) then
            case MessageBox(Self.Handle,
                            PWideChar(Format(rsWrongBackupFolder, [fullPath])),
                            PWideChar(rsWrongBackupFolderTitle),
                            MB_YESNOCANCEL + MB_ICONWARNING) of
            ID_NO: begin
                txtBackupFolder.Show;
                txtBackupFolder.SetFocus;
            end;
            ID_YES: begin
                txtBackupFolder.Text:=strDefaultBackupFolder;
    //            txtBackupFolder.Show;
    //            txtBackupFolder.SetFocus;
            end;
            ID_CANCEL:begin
                txtBackupFolder.Text:=xmlCfg.GetValue('BackupFolder', strDefaultBackupFolder);
    //            txtBackupFolder.Show;
    //            txtBackupFolder.SetFocus;
            end;
            end;


        ChangeValue(Sender);
}
end;

procedure TfrmOptions.udBackupsCountClick(Sender: TObject; Button: TUDBtnType);
begin
    ChangeValue(Sender);
end;

procedure TfrmOptions.btnAssociateFilesClick(Sender: TObject);
begin
    //AssociateFileTypes(True);
end;

procedure TfrmOptions.btnBackupNowClick(Sender: TObject);
begin
    //MakeDocumentBackup;
    Beep;
end;

procedure TfrmOptions.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    Self.BorderIcons:=[];
    Self.Caption:='';
end;

procedure TfrmOptions.FormCreate(Sender: TObject);
//var
    //Lng:TLocalization.TLanguage;
begin
    bhOptions.HideHint;
    //for Lng in appLoc.Languages do
    //    cmbLanguages.Items.Add(Lng.Name);
    //cmbLanguages.ItemIndex:= appLoc.Languages.IndexOf(appLoc.CurrentLanguage);
end;

procedure TfrmOptions.FormKeyPress(Sender: TObject; var Key: Char);
begin
    if Ord(Key) = vk_Escape then begin
        Self.ModalResult:= mrCancel;
        Key := Chr($00);
    end;
end;

procedure TfrmOptions.FormShow(Sender: TObject);
begin
    WindowsOnTop(bWindowsOnTop, Self);
    //appLoc.TranslateForm(Self);
    //SetButtonImg(btnSelBackupFolder, imlOptions, 4);
    //chkMakeBackupsClick(nil);                                                   //Для enable-disable зависимых контролов
    //txtBackupFolderChange(nil);                                                 //Для заполнения bhBackup
end;

procedure TfrmOptions.imgAutoAcceptClick(Sender: TObject);
begin
    ShowBalloonHint(imgAutoAccept, 'Автоматическое подтверждение накладных' ,
                        'Автоматически подтверждать все накладные' + CrLf +
                        'Используйте на свой страх и риск для отгрузок' + CrLf +
                        'на собственные подразделения...'+ CrLf +
                        '(функция в разработке)' + CrLf + CrLf);
end;

procedure TfrmOptions.imgConsoleButtonClick(Sender: TObject);
begin
    ShowBalloonHint(imgConsoleButton, 'Кнопка окна консоли' ,
                        'Используется при неполадках для просмотра' + CrLf +
                        'внутренних процессов программы' + CrLf + CrLf);
end;

procedure TfrmOptions.imgDontDelClick(Sender: TObject);
begin
    ShowBalloonHint(imgDontDel, 'Не удалять адреса из списков транспортного модуля' ,
                        'Осторожно используйте эту опцию' + CrLf +
                        'Она может привести к разрастанию папки УТМ и замедлению работы' + CrLf +
                        'Рекомендуется использовать только при неполадках' + CrLf + CrLf);
end;

procedure TfrmOptions.imgHideToTrayClick(Sender: TObject);
begin
        ShowBalloonHint(imgHideToTray, 'Скрывать приложение в трей' ,
                        'При закрытии главного окна приложение' + CrLf +
                        'скрывается в системуную область рядом с часами' + CrLf +
                        '(функция в разработке)' + CrLf + CrLf);
end;

procedure TfrmOptions.ParseFSRARIDClick(Sender: TObject);
begin
    txtFSRARID.Text:=  ParseFSRARIDfromUTM();
end;

procedure TfrmOptions.ShowBalloonHint(Control: TControl; Title: String; Text: String);
var
    Point:TPoint;
begin
    if bhOptions.ShowingHint then begin
        bhOptions.HideHint;                                       //Нестабильно
        Exit;
    end;
    bhOptions.Title := Title;
    bhOptions.Description:= Text;
    bhOptions.ImageIndex:= 4;
    point.X := Control.Width div 2;
    point.Y := Control.Height;
    bhOptions.ShowHint(Control.ClientToScreen(point));

end;

procedure TfrmOptions.btnCheckUTMdataClick(Sender: TObject);

begin
    if CheckUTMServer('http://' + Trim(txtUTMserver.Text) + ':' + Trim(txtUTMport.Text)) then
        MessageBox(Self.Handle, PWideChar('Настройки верны, транспортный модуль доступен.'),
                PWideChar('Данные верны'), MB_OK + MB_ICONINFORMATION)
    else
        MessageBox(Self.Handle, PWideChar('Транспортный модуль недоступен с этими настройками.'),
                PWideChar('Ошибка'), MB_OK + MB_ICONWARNING);
end;

end.

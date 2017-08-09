program EgaisBox;









{$R *.dres}

uses
  Vcl.Forms,
  Windows,
  uMain in 'uMain.pas' {frmMain},
  uLog in 'uLog.pas',
  uConsole in 'uConsole.pas' {frmLog},
  uLogic in 'uLogic.pas',
  uOptions in 'uOptions.pas' {frmOptions},
  uSettings in 'uSettings.pas',
  Vcl.Themes,
  Vcl.Styles,
  uCrypt in 'uCrypt.pas',
  WCrypt2 in 'WCrypt2.pas',
  uDocument in 'uDocument.pas',
  uTypes in 'uTypes.pas',
  uUTM in 'uUTM.pas',
  uXML in 'uXML.pas',
  uDatabase in 'uDatabase.pas',
  uWBview in 'uWBview.pas' {frmWBview},
  uAbout in 'uAbout.pas' {frmAbout},
  uFilter in 'uFilter.pas' {frmFilter},
  uUpdater in 'uUpdater.pas',
  uUTMChecker in 'uUTMChecker.pas',
  uActEdit in 'uActEdit.pas' {frmActEdit},
  uRawUTM in 'uRawUTM.pas' {frmRawUTM},
  uWBrequest in 'uWBrequest.pas' {frmWBrequest},
  uReturn in 'uReturn.pas' {frmReturn};

var
    H: THandle;
{$R *.res}

begin
    TStyleManager.TrySetStyle('Aqua Light Slate');
    H := CreateMutex(nil, True, '4B3512F4-3614-48D9-8A22-808E7029B9D6');
    if GetLastError = ERROR_ALREADY_EXISTS then begin
        MessageBox(Application.Handle, PWideChar('Программа уже работает,'
               + CrLf + 'нельзя запустить вторую копию!'
               ), PWideChar('Неправильный запуск'), MB_OK + MB_ICONWARNING);
        Exit;
    end;
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    TStyleManager.TrySetStyle('Aqua Light Slate');
  Application.Title := 'EgaisBox';
    Application.CreateForm(TfrmMain, frmMain);
  Application.Run;

end.

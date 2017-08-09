unit uUTMChecker;

interface

uses System.Classes;

type TUTMChecker = class(TThread)
    private
    { Private declarations }
    protected
        procedure Execute; override;
        //procedure ChangeFormCaption();
    end;
var
    thUTMChecker: TUTMChecker;

    procedure StartUTMChecker();
    procedure StopUTMChecker();

implementation

uses uMain, uLogic, uLog, uUtm;

procedure StartUTMChecker();
begin
    if thUTMChecker <> nil then Exit;

    Log('Запуск фоновой проверки УТМ...');
    thUTMChecker:=TUTMChecker.Create(true);
    thUTMChecker.FreeOnTerminate:= True;
    thUTMChecker.Priority:= tpLower;
    thUTMChecker.Resume;
end;

procedure StopUTMChecker();
begin
    if thUTMChecker = nil then Exit;

    Log('Остановка фоновой проверки УТМ...');
    bOnlineMode:= false;
    thUTMChecker.Terminate;
    thUTMChecker:=nil;
end;

procedure TUTMChecker.Execute;
begin
    while not Self.Terminated do begin
        Sleep(5000);
        bOnlineMode:= CheckUTMServer();
        Synchronize(ChangeMainFormCaption);
    end;
end;

end.

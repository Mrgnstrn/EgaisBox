program Updater;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Windows;

function TryChangeFiles(): Boolean;
var
    fs: TSearchRec;
    NewFileName: String;
begin
try
    if FindFirst('*.new', faAnyFile - faDirectory, fs) = 0 then begin
        repeat
            NewFileName:= StringReplace(fs.Name, '.new', '', [rfReplaceAll]);
            if FileExists(NewFileName) then
                if FileExists(NewFileName + '.old') then DeleteFile(PWideChar(NewFileName + '.old'));
                if not MoveFile(PWideChar(NewFileName), PWideChar(NewFileName + '.old')) then begin
                    Result:= False;
                    Exit;
                end;
            MoveFile(PWideChar(fs.Name), PWideChar(NewFileName));
        until FindNext(fs) <> 0;
    end;
    Result:= True;
except
    on E: Exception do begin
    Result:= False;
    end;
end;
end;

var
    Terminated: Boolean;

begin
    try
        Writeln(ParamStr(0));
        SetCurrentDir(ExtractFilePath(ParamStr(0)));
        while not Terminated do begin
            Terminated:= TryChangeFiles();
            Sleep(500);
        end;
    except
        on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;
end.

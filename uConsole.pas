unit uConsole;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.ToolWin, ClipBrd;

type
  TfrmLog = class(TForm)
    lbLog: TListBox;
    tmrLog: TTimer;
    Shape1: TShape;
    StatusBar1: TStatusBar;
    procedure OnMove(var Msg: TWMMove); message WM_MOVE;
    procedure tmrLogTimer(Sender: TObject);
    procedure lbLogMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lbLogDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
private
  	procedure HitTest(var Msg: TWMNcHitTest); message WM_NCHITTEST;

    { Private declarations }
public
    { Public declarations }
end;

var
   frmLog: TfrmLog;
   bLogDocked: Boolean;

implementation
uses uMain{, Logic};

{$R *.dfm}

procedure TfrmLog.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	frmMain.tbtnLog.Down:=False;
    Action:=caFree;       	//Не закрываем, а выгружаем
	Self.Release;			//Контрольный в голову
    frmLog:=nil;
end;

procedure TfrmLog.FormKeyPress(Sender: TObject; var Key: Char);
begin
if Ord(Key) = vk_Escape then begin
	Self.Close;
end;
end;

procedure TfrmLog.FormShow(Sender: TObject);
begin
    StatusBar1.Panels[1].Text := 'Строк: ' +  lbLog.Items.Count.ToString();
end;

procedure TfrmLog.lbLogDblClick(Sender: TObject);
begin
    Clipboard.AsText:= lbLog.Items.Text;
    Beep;
end;

procedure TfrmLog.lbLogMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
if Button = TMouseButton.mbRight then lbLog.Items.Clear
else begin
	ReleaseCapture;
	Self.Perform(WM_SysCommand, $F012, 0);
end;
end;

procedure TfrmLog.OnMove(var Msg: TWMMove);
begin
if tmrLog = nil then Exit;

tmrLog.Enabled:=False;
tmrLog.Enabled:=True;
end;

//Липни, форма! Липни крепче! //Пока только справа и снизу
procedure TfrmLog.tmrLogTimer(Sender: TObject);
begin
//Log ('X', Self.Left - frmMain.Left - frmMain.Width);
//Log ('Y', Self.Top - frmMain.Top) ;
	if (Abs(Self.Left - frmMain.Left - frmMain.Width) < 100) and
		(Abs(Self.Top - frmMain.Top) < 100) then begin
        Self.SetBounds(
        				frmMain.Left + frmMain.Width,
        				frmMain.Top,
						Width,
        				frmMain.Height);
        bLogDocked:=True;
    end else
    if (Abs(Self.Top - frmMain.Top - frmMain.Height) < 100) and
       	(Abs(Self.Left - frmMain.Left) < 100) then begin
        Self.SetBounds(
        				frmMain.Left,
  						frmMain.Top + frmMain.Height,
						800,
        				200);
        bLogDocked:=True;
    end else
    bLogDocked:=False;
	tmrLog.Enabled:=False;
end;

procedure TfrmLog.HitTest(var Msg: TWMNcHitTest);
var X, Y: Integer;
begin
  inherited;
 // получаем координаты мыши относительно формы
  X := Msg.XPos - Left;
  Y := Msg.YPos - Top;
	if X <= 15 then begin // если мышь у левого края формы
  		if Y <= 15 then Msg.Result := HTTOPLEFT// если мышь у верхнего края формы
    	else if Y >= ClientHeight - 15 then Msg.Result := HTBOTTOMLEFT // мышь у левого нижнего края
      	else Msg.Result := HTLEFT;
  	end
    else if X >= ClientWidth - 15 then begin
    	if Y <= 5 then Msg.Result := HTTOPRIGHT
        else if Y >= ClientHeight - 15 then Msg.Result := HTBOTTOMRIGHT
        else Msg.Result := HTRIGHT;
    end
    else begin
        if Y <= 15 then Msg.Result := HTTOP
        else if Y >= ClientHeight - 15 then Msg.Result := HTBOTTOM
        else Msg.Result := HTCAPTION
    end;
end;

end.

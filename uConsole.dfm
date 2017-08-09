object frmLog: TfrmLog
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = #1051#1086#1075
  ClientHeight = 398
  ClientWidth = 536
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnClose = FormClose
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 536
    Height = 381
    Align = alClient
    Pen.Color = clBtnShadow
    ExplicitLeft = 104
    ExplicitTop = -120
    ExplicitWidth = 400
    ExplicitHeight = 400
  end
  object lbLog: TListBox
    Left = 0
    Top = 0
    Width = 536
    Height = 381
    Align = alClient
    Color = clHotLight
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindow
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ItemHeight = 15
    ParentFont = False
    TabOrder = 0
    StyleElements = []
    OnDblClick = lbLogDblClick
    OnMouseDown = lbLogMouseDown
    ExplicitLeft = 3
    ExplicitTop = 3
    ExplicitWidth = 538
    ExplicitHeight = 396
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 381
    Width = 536
    Height = 17
    Margins.Top = 0
    Panels = <
      item
        Text = 'Esc - '#1047#1072#1082#1088#1099#1090#1100', RMB - '#1054#1095#1080#1089#1090#1080#1090#1100', DblClick - '#1050#1086#1087#1080#1088#1086#1074#1072#1090#1100' '#1074#1089#1077
        Width = 300
      end
      item
        Alignment = taRightJustify
        Text = #1057#1090#1088#1086#1082':'
        Width = 90
      end>
    ExplicitLeft = 3
    ExplicitTop = 402
    ExplicitWidth = 538
  end
  object tmrLog: TTimer
    Enabled = False
    Interval = 300
    OnTimer = tmrLogTimer
    Left = 131
    Top = 232
  end
end

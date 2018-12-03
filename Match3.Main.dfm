object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = '3 '#1074' '#1088#1103#1076
  ClientHeight = 508
  ClientWidth = 485
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnMouseDown = FormMouseDown
  OnMouseMove = FormMouseMove
  OnMouseUp = FormMouseUp
  OnPaint = FormPaint
  PixelsPerInch = 96
  TextHeight = 13
  object PanelCtrl: TPanel
    Left = 0
    Top = 428
    Width = 485
    Height = 80
    Align = alBottom
    BevelOuter = bvNone
    Color = clGray
    ParentBackground = False
    TabOrder = 0
    ExplicitTop = 424
    object Button1: TButton
      Left = 6
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Button1'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 87
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Button2'
      TabOrder = 1
      OnClick = Button2Click
    end
  end
  object TimerFPS: TTimer
    OnTimer = TimerFPSTimer
    Left = 312
    Top = 104
  end
  object TimerRepaint: TTimer
    Enabled = False
    Interval = 15
    OnTimer = FormPaint
    Left = 248
    Top = 104
  end
  object TimerAnimate: TTimer
    Interval = 10
    OnTimer = TimerAnimateTimer
    Left = 368
    Top = 104
  end
end

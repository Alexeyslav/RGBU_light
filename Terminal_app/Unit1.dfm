object Form1: TForm1
  Left = 383
  Top = 120
  Width = 621
  Height = 481
  Caption = #1059#1087#1088#1072#1074#1083#1077#1085#1080#1077' RGBU-'#1084#1086#1076#1091#1083#1103#1084#1080
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label2: TLabel
    Left = 394
    Top = 106
    Width = 40
    Height = 16
    Caption = #1040#1076#1088#1077#1089
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Label3: TLabel
    Left = 233
    Top = 196
    Width = 17
    Height = 29
    Caption = 'R'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -24
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Label4: TLabel
    Left = 268
    Top = 196
    Width = 18
    Height = 29
    Caption = 'G'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clLime
    Font.Height = -24
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Label5: TLabel
    Left = 302
    Top = 196
    Width = 16
    Height = 29
    Caption = 'B'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -24
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Label6: TLabel
    Left = 335
    Top = 197
    Width = 17
    Height = 29
    Caption = 'U'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 16748962
    Font.Height = -24
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object hhALed1: ThhALed
    Left = 16
    Top = 127
    Width = 16
    Height = 17
    Blink = False
  end
  object hhALed2: ThhALed
    Left = 16
    Top = 151
    Width = 16
    Height = 16
    TrueColor = clRed
    Blink = False
  end
  object hhALed3: ThhALed
    Left = 16
    Top = 175
    Width = 16
    Height = 16
    TrueColor = clRed
    Blink = False
  end
  object hhALed4: ThhALed
    Left = 16
    Top = 199
    Width = 16
    Height = 17
    Blink = False
  end
  object Label7: TLabel
    Left = 41
    Top = 129
    Width = 37
    Height = 13
    Caption = 'READY'
  end
  object Label8: TLabel
    Left = 42
    Top = 154
    Width = 69
    Height = 13
    Caption = 'COM_ERROR'
  end
  object Label9: TLabel
    Left = 43
    Top = 177
    Width = 50
    Height = 13
    Caption = 'COM_retry'
  end
  object hhALed5: ThhALed
    Left = 16
    Top = 223
    Width = 16
    Height = 17
    Blink = False
  end
  object Label10: TLabel
    Left = 43
    Top = 199
    Width = 53
    Height = 13
    Caption = 'COM_state'
  end
  object Label11: TLabel
    Left = 40
    Top = 223
    Width = 65
    Height = 13
    Caption = 'Protocol state'
  end
  object hhALed6: ThhALed
    Left = 16
    Top = 247
    Width = 16
    Height = 17
    Blink = False
  end
  object Label12: TLabel
    Left = 40
    Top = 247
    Width = 38
    Height = 13
    Caption = 'Opened'
  end
  object COMst: TLabel
    Left = 111
    Top = 199
    Width = 18
    Height = 13
    Caption = '------'
  end
  object Gauge1: TGauge
    Left = 208
    Top = 8
    Width = 193
    Height = 15
    MaxValue = 1023
    Progress = 0
  end
  object Gauge2: TGauge
    Left = 416
    Top = 8
    Width = 193
    Height = 15
    MaxValue = 1023
    Progress = 0
  end
  object Gauge4: TGauge
    Left = 416
    Top = 28
    Width = 193
    Height = 15
    MaxValue = 1023
    Progress = 0
  end
  object Gauge3: TGauge
    Left = 208
    Top = 28
    Width = 193
    Height = 15
    MaxValue = 1023
    Progress = 0
  end
  object Gauge6: TGauge
    Left = 416
    Top = 48
    Width = 193
    Height = 15
    MaxValue = 1023
    Progress = 0
  end
  object Gauge5: TGauge
    Left = 208
    Top = 48
    Width = 193
    Height = 15
    MaxValue = 1023
    Progress = 0
  end
  object Lerrcnt: TLabel
    Left = 124
    Top = 153
    Width = 9
    Height = 13
    Caption = '---'
  end
  object Lretrycnt: TLabel
    Left = 124
    Top = 177
    Width = 9
    Height = 13
    Caption = '---'
  end
  object Label13: TLabel
    Left = 394
    Top = 157
    Width = 85
    Height = 16
    Caption = #1053#1086#1074#1099#1081' '#1072#1076#1088#1077#1089
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Label14: TLabel
    Left = 16
    Top = 104
    Width = 121
    Height = 13
    Caption = #1048#1085#1090#1077#1088#1074#1072#1083' '#1086#1073#1085#1086#1074#1083#1077#1085#1080#1103' ='
  end
  object Bevel1: TBevel
    Left = 240
    Top = 224
    Width = 9
    Height = 17
    Shape = bsLeftLine
  end
  object Bevel2: TBevel
    Left = 240
    Top = 224
    Width = 161
    Height = 17
    Shape = bsBottomLine
  end
  object Bevel3: TBevel
    Left = 276
    Top = 248
    Width = 123
    Height = 17
    Shape = bsBottomLine
  end
  object Bevel4: TBevel
    Left = 307
    Top = 272
    Width = 94
    Height = 17
    Shape = bsBottomLine
  end
  object Bevel5: TBevel
    Left = 342
    Top = 296
    Width = 59
    Height = 17
    Shape = bsBottomLine
  end
  object Bevel6: TBevel
    Left = 276
    Top = 224
    Width = 9
    Height = 41
    Shape = bsLeftLine
  end
  object Bevel7: TBevel
    Left = 307
    Top = 224
    Width = 9
    Height = 65
    Shape = bsLeftLine
  end
  object Bevel8: TBevel
    Left = 341
    Top = 224
    Width = 9
    Height = 89
    Shape = bsLeftLine
  end
  object Bevel9: TBevel
    Left = 216
    Top = 72
    Width = 377
    Height = 265
  end
  object Label1: TLabel
    Left = 280
    Top = 64
    Width = 176
    Height = 13
    Caption = ' '#1059#1087#1088#1072#1074#1083#1077#1085#1080#1077' '#1086#1076#1080#1085#1086#1095#1085#1099#1084' '#1084#1086#1076#1091#1083#1077#1084' '
  end
  object Memo1: TMemo
    Left = 0
    Top = 351
    Width = 613
    Height = 99
    Align = alBottom
    Lines.Strings = (
      'Memo1')
    TabOrder = 0
  end
  object Button1: TButton
    Left = 8
    Top = 32
    Width = 75
    Height = 25
    Caption = 'Connect'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 88
    Top = 32
    Width = 75
    Height = 25
    Caption = 'Disconnect'
    TabOrder = 2
    OnClick = Button2Click
  end
  object SpinAddr: TSpinEdit
    Left = 488
    Top = 102
    Width = 49
    Height = 22
    MaxValue = 255
    MinValue = 0
    TabOrder = 3
    Value = 254
    OnChange = SpinAddrNewChange
  end
  object COMsel: TComboBox
    Left = 9
    Top = 5
    Width = 94
    Height = 21
    ItemHeight = 13
    ItemIndex = 3
    TabOrder = 4
    Text = 'COM4'
    Items.Strings = (
      'COM1'
      'COM2'
      'COM3'
      'COM4'
      'COM5'
      'COM6'
      'COM7'
      'COM8'
      'COM9'
      'COM10'
      'COM11'
      'COM12'
      'COM13'
      'COM14'
      'COM15'
      'COM16')
  end
  object SpinR: TScrollBar
    Left = 228
    Top = 88
    Width = 31
    Height = 110
    Ctl3D = False
    Kind = sbVertical
    LargeChange = 16
    Max = 255
    PageSize = 1
    ParentCtl3D = False
    Position = 255
    TabOrder = 5
  end
  object SpinG: TScrollBar
    Left = 262
    Top = 88
    Width = 31
    Height = 110
    Ctl3D = False
    Kind = sbVertical
    LargeChange = 16
    Max = 255
    PageSize = 1
    ParentCtl3D = False
    Position = 255
    TabOrder = 6
  end
  object SpinB: TScrollBar
    Left = 296
    Top = 88
    Width = 31
    Height = 110
    Ctl3D = False
    Kind = sbVertical
    LargeChange = 16
    Max = 255
    PageSize = 1
    ParentCtl3D = False
    Position = 255
    TabOrder = 7
  end
  object SpinU: TScrollBar
    Left = 330
    Top = 88
    Width = 31
    Height = 110
    Ctl3D = False
    Kind = sbVertical
    LargeChange = 16
    Max = 255
    PageSize = 1
    ParentCtl3D = False
    Position = 192
    TabOrder = 8
  end
  object Button3: TButton
    Left = 392
    Top = 128
    Width = 132
    Height = 23
    Caption = #1057#1084#1077#1085#1080#1090#1100' '#1072#1076#1088#1077#1089
    TabOrder = 9
    OnClick = Button3Click
  end
  object SpinAddrNew: TSpinEdit
    Left = 489
    Top = 154
    Width = 49
    Height = 22
    MaxValue = 255
    MinValue = 0
    TabOrder = 10
    Value = 0
    OnChange = SpinAddrNewChange
  end
  object TrackBar1: TTrackBar
    Left = 8
    Top = 64
    Width = 193
    Height = 36
    Ctl3D = False
    LineSize = 5
    Max = 2000
    Min = 50
    ParentCtl3D = False
    PageSize = 50
    Frequency = 50
    Position = 250
    TabOrder = 11
    TickMarks = tmBoth
    TickStyle = tsManual
    OnChange = TrackBar1Change
  end
  object ComboR: TComboBox
    Left = 400
    Top = 229
    Width = 177
    Height = 21
    ItemHeight = 13
    ItemIndex = 2
    TabOrder = 12
    Text = #1040#1062#1055': '#1082#1072#1085#1072#1083' 1'
    Items.Strings = (
      #1060#1080#1082#1089#1080#1088#1086#1074#1072#1085#1085#1086#1077' '#1079#1085#1072#1095#1077#1085#1080#1077
      #1057#1083#1091#1095#1072#1081#1085#1086#1077' '#1089' '#1072#1084#1087#1083#1080#1090#1091#1076#1086#1081
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 1'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 2'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 3'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 4'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 5'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 6')
  end
  object ComboG: TComboBox
    Left = 400
    Top = 253
    Width = 177
    Height = 21
    ItemHeight = 13
    ItemIndex = 4
    TabOrder = 13
    Text = #1040#1062#1055': '#1082#1072#1085#1072#1083' 3'
    Items.Strings = (
      #1060#1080#1082#1089#1080#1088#1086#1074#1072#1085#1085#1086#1077' '#1079#1085#1072#1095#1077#1085#1080#1077
      #1057#1083#1091#1095#1072#1081#1085#1086#1077' '#1089' '#1072#1084#1087#1083#1080#1090#1091#1076#1086#1081
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 1'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 2'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 3'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 4'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 5'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 6')
  end
  object ComboB: TComboBox
    Left = 400
    Top = 277
    Width = 177
    Height = 21
    ItemHeight = 13
    ItemIndex = 7
    TabOrder = 14
    Text = #1040#1062#1055': '#1082#1072#1085#1072#1083' 6'
    Items.Strings = (
      #1060#1080#1082#1089#1080#1088#1086#1074#1072#1085#1085#1086#1077' '#1079#1085#1072#1095#1077#1085#1080#1077
      #1057#1083#1091#1095#1072#1081#1085#1086#1077' '#1089' '#1072#1084#1087#1083#1080#1090#1091#1076#1086#1081
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 1'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 2'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 3'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 4'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 5'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 6')
  end
  object ComboU: TComboBox
    Left = 400
    Top = 301
    Width = 177
    Height = 21
    ItemHeight = 13
    ItemIndex = 1
    TabOrder = 15
    Text = #1057#1083#1091#1095#1072#1081#1085#1086#1077' '#1089' '#1072#1084#1087#1083#1080#1090#1091#1076#1086#1081
    Items.Strings = (
      #1060#1080#1082#1089#1080#1088#1086#1074#1072#1085#1085#1086#1077' '#1079#1085#1072#1095#1077#1085#1080#1077
      #1057#1083#1091#1095#1072#1081#1085#1086#1077' '#1089' '#1072#1084#1087#1083#1080#1090#1091#1076#1086#1081
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 1'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 2'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 3'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 4'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 5'
      #1040#1062#1055': '#1082#1072#1085#1072#1083' 6')
  end
  object Timer1: TTimer
    Interval = 250
    OnTimer = Timer1Timer
    Left = 168
    Top = 32
  end
end

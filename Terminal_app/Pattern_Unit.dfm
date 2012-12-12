object Form1: TForm1
  Left = 578
  Top = 215
  Width = 607
  Height = 356
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 104
    Height = 13
    Caption = #1050#1086#1083#1080#1095#1077#1089#1090#1074#1086' '#1082#1072#1085#1072#1083#1086#1074
  end
  object Label2: TLabel
    Left = 136
    Top = 8
    Width = 59
    Height = 13
    Caption = #1089#1091#1073#1082#1072#1085#1072#1083#1086#1074
  end
  object Label3: TLabel
    Left = 428
    Top = 36
    Width = 15
    Height = 13
    Caption = #1044#1086
  end
  object Label4: TLabel
    Left = 536
    Top = 36
    Width = 36
    Height = 13
    Caption = #1088#1072#1076#1080#1072#1085
  end
  object Label5: TLabel
    Left = 428
    Top = 84
    Width = 15
    Height = 13
    Caption = #1044#1086
  end
  object Label6: TLabel
    Left = 536
    Top = 84
    Width = 56
    Height = 13
    Caption = #1069#1083#1077#1084#1077#1085#1090#1086#1074
  end
  object Label7: TLabel
    Left = 428
    Top = 132
    Width = 15
    Height = 13
    Caption = #1044#1086
  end
  object Label9: TLabel
    Left = 428
    Top = 180
    Width = 15
    Height = 13
    Caption = #1044#1086
  end
  object progress: TGauge
    Left = 376
    Top = 299
    Width = 201
    Height = 17
    Progress = 0
  end
  object Items_count: TLabeledEdit
    Left = 8
    Top = 68
    Width = 73
    Height = 21
    Hint = 
      #1050#1086#1083#1080#1095#1077#1089#1090#1074#1086' '#1101#1083#1077#1084#1077#1085#1090#1086#1074' '#1087#1072#1090#1090#1077#1088#1085#1072'. '#1050#1072#1078#1076#1099#1081' '#1101#1083#1077#1084#1077#1085#1090' '#1087#1072#1090#1090#1077#1088#1085#1072#13#10#1089#1086#1076#1077#1088#1078#1080#1090 +
      ' '#1074' '#1089#1077#1073#1077' '#1079#1085#1072#1095#1077#1085#1080#1077' '#1103#1088#1082#1086#1089#1090#1080' '#1076#1083#1103' '#1082#1072#1078#1076#1086#1075#1086' '#1082#1072#1085#1072#1083#1072'.'
    EditLabel.Width = 193
    EditLabel.Height = 13
    EditLabel.Caption = #1050#1086#1083#1080#1095#1077#1089#1090#1074#1086' '#1075#1077#1085#1077#1088#1080#1088#1091#1077#1084#1099#1093' '#1101#1083#1077#1084#1077#1085#1090#1086#1074
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    Text = '10000'
  end
  object Button1: TButton
    Left = 240
    Top = 296
    Width = 129
    Height = 25
    Caption = 'Generate it!'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    OnClick = Button1Click
  end
  object Step_count: TLabeledEdit
    Left = 8
    Top = 112
    Width = 121
    Height = 21
    Hint = 
      #1056#1072#1089#1089#1095#1077#1090' '#1079#1085#1072#1095#1077#1085#1080#1103' '#1076#1083#1103' '#1082#1072#1078#1076#1086#1075#1086' N-'#1075#1086' '#1101#1083#1077#1084#1077#1085#1090#1072' '#1084#1085#1086#1078#1077#1089#1090#1074#1072', '#13#10#1086#1089#1090#1072#1083#1100#1085#1099 +
      #1077' '#1088#1072#1089#1089#1095#1080#1090#1099#1074#1072#1102#1090#1089#1103' '#1087#1088#1080' '#1087#1086#1084#1086#1097#1080' '#1083#1080#1085#1077#1081#1085#1086#1081' '#1080#1085#1090#1077#1088#1087#1086#1083#1103#1094#1080#1080
    EditLabel.Width = 137
    EditLabel.Height = 13
    EditLabel.Caption = #1064#1072#1075' '#1075#1077#1085#1077#1088#1072#1094#1080#1080', '#1101#1083#1077#1084#1077#1085#1090#1086#1074
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    Text = '8'
  end
  object Channel_num: TSpinEdit
    Left = 8
    Top = 24
    Width = 57
    Height = 22
    MaxValue = 20
    MinValue = 1
    TabOrder = 3
    Value = 8
  end
  object Select_random: TRadioButton
    Tag = 1
    Left = 16
    Top = 240
    Width = 505
    Height = 17
    Caption = #1056#1072#1089#1089#1095#1080#1090#1072#1090#1100' '#1085#1072' '#1086#1089#1085#1086#1074#1077' '#1089#1083#1091#1095#1072#1081#1085#1099#1093' '#1074#1077#1083#1080#1095#1080#1085
    Checked = True
    TabOrder = 4
    TabStop = True
  end
  object SubChan_num: TSpinEdit
    Left = 144
    Top = 24
    Width = 57
    Height = 22
    MaxValue = 8
    MinValue = 1
    TabOrder = 5
    Value = 4
  end
  object Select_garmonic: TRadioButton
    Tag = 1
    Left = 16
    Top = 264
    Width = 505
    Height = 17
    Caption = #1056#1072#1089#1089#1095#1080#1090#1072#1090#1100' '#1085#1072' '#1086#1089#1085#1086#1074#1077' '#1090#1088#1080#1075#1086#1085#1086#1084#1077#1090#1088#1080#1095#1077#1089#1082#1080#1093' '#1092#1091#1085#1082#1094#1080#1081
    TabOrder = 6
  end
  object St_phase_from: TLabeledEdit
    Left = 336
    Top = 28
    Width = 73
    Height = 21
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    EditLabel.Width = 228
    EditLabel.Height = 13
    EditLabel.Caption = #1053#1072#1095#1072#1083#1100#1085#1072#1103' '#1092#1072#1079#1072' '#1076#1083#1103' '#1082#1072#1078#1076#1086#1075#1086' '#1080#1079' '#1089#1091#1073#1082#1072#1085#1072#1083#1086#1074
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    ShowHint = False
    TabOrder = 7
    Text = '0'
  end
  object St_phase_to: TEdit
    Left = 459
    Top = 29
    Width = 68
    Height = 21
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 8
    Text = '3.14'
  end
  object Period_from: TLabeledEdit
    Left = 336
    Top = 76
    Width = 73
    Height = 21
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    EditLabel.Width = 84
    EditLabel.Height = 13
    EditLabel.Caption = #1055#1077#1088#1080#1086#1076' '#1092#1091#1085#1082#1094#1080#1080
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    ShowHint = False
    TabOrder = 9
    Text = '10'
  end
  object Period_to: TEdit
    Left = 459
    Top = 77
    Width = 68
    Height = 21
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 10
    Text = '100'
  end
  object Offset_from: TLabeledEdit
    Left = 336
    Top = 124
    Width = 73
    Height = 21
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    EditLabel.Width = 112
    EditLabel.Height = 13
    EditLabel.Caption = #1057#1084#1077#1097#1077#1085#1080#1077' "0", 0...255'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    ShowHint = False
    TabOrder = 11
    Text = '128'
  end
  object Offset_to: TEdit
    Left = 459
    Top = 125
    Width = 68
    Height = 21
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 12
    Text = '128'
  end
  object Mirror: TCheckBox
    Left = 336
    Top = 208
    Width = 257
    Height = 17
    Caption = #1054#1090#1088#1072#1078#1077#1085#1080#1077' '#1092#1091#1085#1082#1094#1080#1080' '#1087#1088#1080' '#1074#1099#1093#1086#1076#1077' '#1079#1072' '#1087#1088#1077#1076#1077#1083#1099
    TabOrder = 13
  end
  object Gain_from: TLabeledEdit
    Left = 336
    Top = 172
    Width = 73
    Height = 21
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    EditLabel.Width = 112
    EditLabel.Height = 13
    EditLabel.Caption = #1040#1084#1087#1083#1080#1090#1091#1076#1072' -100...+100'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    ShowHint = False
    TabOrder = 14
    Text = '0.9'
  end
  object Gain_to: TEdit
    Left = 459
    Top = 173
    Width = 68
    Height = 21
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 15
    Text = '1.1'
  end
end

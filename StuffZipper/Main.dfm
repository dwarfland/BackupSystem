object MainForm: TMainForm
  Left = 405
  Top = 154
  Width = 353
  Height = 263
  Caption = 'Zipping stuff...'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Visible = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    345
    236)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 4
    Width = 61
    Height = 13
    Caption = 'Zipping stuff:'
  end
  object pl_Progress: TProgressList
    Left = 8
    Top = 24
    Width = 329
    Height = 170
    Items = <>
  end
  object btn_Close: TButton
    Left = 264
    Top = 200
    Width = 75
    Height = 23
    Anchors = [akRight, akBottom]
    Caption = 'Close'
    Default = True
    Enabled = False
    ModalResult = 1
    TabOrder = 1
  end
end

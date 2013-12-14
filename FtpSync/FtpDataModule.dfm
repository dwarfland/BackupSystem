object FtpData: TFtpData
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Left = 511
  Top = 259
  Height = 150
  Width = 215
  object id_FTP: TIdFTP
    OnStatus = id_FTPStatus
    MaxLineAction = maException
    ReadTimeout = 0
    OnWork = id_FTPWork
    Passive = True
    ProxySettings.ProxyType = fpcmNone
    ProxySettings.Port = 0
    Left = 16
    Top = 8
  end
end

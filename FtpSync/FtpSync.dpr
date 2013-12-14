program FtpSync;

{$APPTYPE CONSOLE}

uses
  SysUtils, eCmdLine,
  FtpDataModule in 'FtpDataModule.pas' {FtpData: TDataModule};

begin
  writeln('elitedevelopments FtpSync 0.1');
  writeln('(c) copyright elitedevelopments software 2002. All rights reserved.');
  writeln;
  with TFtpData.Create(nil) do try

  finally
    Free();
  end;  
  writeln('Done.');
  if SwitchExists('wait') then readln;
end.

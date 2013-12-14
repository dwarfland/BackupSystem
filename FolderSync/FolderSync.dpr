program FolderSync;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, eStrings,
    eCmdLine;

procedure Sync(const iSourceFolder, iDestinationFolder:string);
var lSearch:TSearchRec;
    lMustBeCopied: boolean;
    lOk:dword;
    lLastAccess,lLastChange:TFileTime;
    lLastAccessDate,lLastChangeDate:TDateTime;
    lHandle:THandle;
begin
  ForceDirectories(iDestinationFolder);

  writeln('Syncing new files from '+iSourceFolder+' to '+iDestinationFolder);

  lOk := FindFirst(MakePath(iSourceFolder)+'*.*',$3f,lSearch);
  try
    while lOk = 0 do begin

      if (lSearch.Name <> '.') and (lSearch.Name <> '..') then begin

        if (lSearch.Attr and faDirectory) = faDirectory then begin
          Sync(MakePath(iSourceFolder)+lSearch.Name, MakePath(iDestinationFolder)+lSearch.Name);
        end
        else begin

          lMustBeCopied := false;
          if not FileExists(MakePath(iDestinationFolder)+lSearch.Name) then begin
            lMustBeCopied := true;
          end;

          if lMustBeCopied then begin
            Writeln('Copying  '+MakePath(iSourceFolder)+lSearch.Name);
            if not CopyFile(pChar(MakePath(iSourceFolder)+lSearch.Name), pChar(MakePath(iDestinationFolder)+lSearch.Name),true) then RaiseLastOSError();
          end
          else begin
            Writeln('Skipping '+MakePath(iSourceFolder)+lSearch.Name);
          end;

        end;
      end;

      lOk := FindNext(lSearch)
    end;
  finally
    FindClose(lSearch);
  end;

  writeln('Removing old files from '+iDestinationFolder);

  lOk := FindFirst(MakePath(iDestinationFolder)+'*.*',$3f,lSearch);
  try
    while lOk = 0 do begin

      if (lSearch.Name <> '.') and (lSearch.Name <> '..') then begin

        if (lSearch.Attr and faDirectory) = faDirectory then begin
          //Sync(MakePath(iSourceFolder)+lSearch.Name, MakePath(iDestinationFolder)+lSearch.Name);
        end
        else begin

          if not FileExists(MakePath(iSourceFolder)+lSearch.Name) then begin
            Writeln('Deleting '+MakePath(iDestinationFolder)+lSearch.Name);
            DeleteFile(pChar(MakePath(iDestinationFolder)+lSearch.Name));
          end;

        end;
      end;

      lOk := FindNext(lSearch)
    end;
  finally
    FindClose(lSearch);
  end;

end;

begin
  writeln('elitedevelopments FolderSync 0.1');
  writeln('(c) copyright elitedevelopments software 2003. All rights reserved.');
  writeln;
  writeln('Recursively syncs files in tow folders');
  writeln;

  if ParamCount < 2 then begin
    writeln('Syntax:  FolderSync <SourcePath> <DestPath> [/wait]');
    writeln;
    exit;
  end;

  try

    Sync(ParamStr(1),ParamStr(2));

  except
    on E: Exception do
      writeln(E.Classname+': '+E.Message);
  end;

  writeln;
  writeln('Done.');
  writeln;

  if SwitchExists('wait') then begin
    Writeln('Press enter...');
    readln;
  end;
end.

program TouchFolders;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  eCmdLine, eStrings,
  eBackupSystemHelpers in '..\eBackupSystemHelpers.pas';

procedure RecursivelyTouchFolder(const iFolder:string; var oLastAccess, oLastChange:TFileTime; iLevel:integer);
var lSearch:TSearchRec;
    lOk:dword;
    lLastAccess,lLastChange:TFileTime;
    //lLastAccessDate, lLastChangeDate:TDateTime;
    lHandle:THandle;
begin
  lOk := FindFirst(iFolder+'\*.*',$3f,lSearch);
  try
    while lOk = 0 do begin

      if (lSearch.Name <> '.') and (lSearch.Name <> '..') then begin

        if StartsWith('__',lSearch.Name) then begin
          writeln('Skipping '+lSearch.Name);

          lOk := FindNext(lSearch);
          continue;
        end;


        //if (lSearch.Attr and faDirectory) = 0 then begin

          //lHandle := CreateFile(pChar(iFolder+'\'+lSearch.Name),$180, 0, nil, OPEN_EXISTING, 0, 0);
          //try

            { get filetime }
            //if lHandle = INVALID_HANDLE_VALUE then RaiseLastOSError();
            //if not GetFileTime(lHandle,nil,@lLastAccess,@lLastChange) then RaiseLastOSError();

          //finally
            //CloseHandle(lHandle);
          //end;

        { make sure o* has the latest change }
        if CompareFileTime(lSearch.FindData.ftLastAccessTime,oLastAccess) = 1 then oLastAccess := lSearch.FindData.ftLastAccessTime;
        if CompareFileTime(lSearch.FindData.ftLastWriteTime,oLastChange) = 1 then oLastChange := lSearch.FindData.ftLastWriteTime;

        if (lSearch.Attr and faDirectory) = faDirectory then begin
          lLastAccess := lSearch.FindData.ftLastAccessTime;
          lLastChange := lSearch.FindData.ftLastWriteTime;

          //writeln('LastAccess Date for '+iFolder+'\'+lSearch.Name+' was '+DateTimeToStr(FileTimeToDateTime(lLastAccess)));
          //writeln('LastChange Date for '+iFolder+'\'+lSearch.Name+' was '+DateTimeToStr(FileTimeToDateTime(lLastChange)));
          if not SwitchExists('quiet') then writeln(iFolder+'\'+lSearch.Name);
          RecursivelyTouchFolder(iFolder+'\'+lSearch.Name, lLastAccess, lLastChange, iLevel+1);
          //writeln('LastAccess Date for '+iFolder+'\'+lSearch.Name+' is '+DateTimeToStr(FileTimeToDateTime(lLastAccess)));
          //writeln(iFolder+'\'+lSearch.Name+' is '+DateTimeToStr(FileTimeToDateTime(lLastChange)));

          try
            lHandle := CreateFile(pChar(iFolder+'\'+lSearch.Name),$180 {GENERIC_READ or GENERIC_WRITE}, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);
            if lHandle = INVALID_HANDLE_VALUE then RaiseLastOSError();
            try
              if not SetFileTime(lHandle,nil,@lLastAccess,@lLastChange) then RaiseLastOSError();
            finally
              CloseHandle(lHandle);
            end;
          except
            on E:Exception do
              writeln(iFolder+'\'+lSearch.Name+' - '+E.Message);
          end;

        end;
      end;

      lOk := FindNext(lSearch)
    end;
  finally
    FindClose(lSearch);
  end;

end;



var d1,d2:TFileTime;
begin
  writeln('elitedevelopments TouchFolders 0.1');
  writeln('(c) copyright elitedevelopments software 2002. All rights reserved.');
  writeln;
  writeln('Recursively touches all folders and subfolders below the specified path');
  writeln;

  if ParamCount = 0 then begin
    writeln('Syntax:  TouchFile <Path> [/wait] [/quiet]');
    writeln;
    exit;
  end;

  writeln('Touching '+ExcludeTrailingBackslash(ParamStr(1))+'...');
  RecursivelyTouchFolder(ExcludeTrailingBackslash(ParamStr(1)),d1,d2,0);

  writeln;
  writeln('Done.');
  writeln;

  if SwitchExists('wait') then begin
    Writeln('Press enter...');
    readln;
  end;
end.

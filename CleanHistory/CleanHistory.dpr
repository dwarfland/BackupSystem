program CleanHistory;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, DateUtils, Classes,
  eStrings, eCmdLine;

type
  TFileInfo = Class
    fFilename: string;
    fFileDate: TDateTime;
    fFileSize: Int64;
    constructor Create(const aFilename:string; aFileDate:TDateTime; aFileSize:Int64);
  end;

function FileSortCompare(Item1, Item2: Pointer): Integer;
begin
  if TFileInfo(Item1).fFileDate = TFileInfo(Item2).fFileDate then begin
    result := 0;
  end
  else if TFileInfo(Item1).fFileDate > TFileInfo(Item2).fFileDate then begin
    result := 1;
  end
  else begin
    result := -1;
  end;
    
end;

function IsSameMonth(aDate1,aDate2:TDateTime):boolean;
begin
  result := (YearOf(aDate1)  = YearOf(aDate2)) and
            (MonthOf(aDate1) = MonthOf(aDate2));
end;

var
  gDeletedSpace: Int64;

procedure CleanFolder(const aFolder: string; aInHistory:boolean; aRecurse:boolean=true);
var
  I: Integer;
  lSearch:TSearchRec;
  lOk:dword;
  lFiles:TList;
  lFile:TFileInfo;
  lLast:TDateTime;
begin
  lFiles := TList.Create();
  try

    lOk := FindFirst(MakePath(aFolder)+'*.*',faDirectory,lSearch);
    try
      while lOk = 0 do begin
        if (lSearch.Attr and faDirectory) = faDirectory then begin
          if aRecurse and (lSearch.Name <> '.') and (lSearch.Name <> '..') then
            CleanFolder(MakePath(aFolder)+lSearch.Name,aInHistory or (lSearch.Name='__History'),aRecurse);
        end
        else begin
          lFiles.Add(TFileInfo.Create(lSearch.Name,FileDateToDateTime(FileAge(MakePath(aFolder)+lSearch.Name)),lSearch.Size));
        end;
        lOk := FindNext(lSearch);
      end;    { while }

    finally
      FindClose(lSearch);
    end;

    writeln;

    if aInHistory then begin
      writeln('Folder '+aFolder+':');

      lFiles.Sort(FileSortCompare);

      lLast := 0;
      for i := 0 to lFiles.Count-1 do begin
        lFile := TObject(lFiles[i]) as TFileInfo;
        if WithinPastDays(Now,lFile.fFileDate,15) then begin
          write('  LAST15  ');
        end
        else if IsSameMonth(lFile.fFileDate,lLast) then begin
          if not SwitchExists('preview') then begin
            DeleteFile(MakePath(aFolder)+lFile.fFilename);
            write('  DELETED ');
          end
          else begin
            write('  DELETE  ');
          end;
          gDeletedSpace := gDeletedSpace+lFile.fFileSize;
        end
        else begin
          write('  KEEP    ');
        end;
        writeln('  '+DateToStr(lFile.fFileDate)+' - '+lFile.fFilename);

        lLast := lFile.fFileDate;
      end; { for }
    end
    else begin
      writeln('Skipping Folder '+aFolder+':');
    end;

  finally
    lFiles.Free();
  end;
end;

{ TFileInfo }

constructor TFileInfo.Create(const aFilename: string; aFileDate: TDateTime; aFileSize:Int64);
begin
  fFilename := aFilename;
  fFileDate := aFileDate;
  fFileSize := aFileSize;
end;


begin
  writeln('elitedevelopments BackupSystem - CleanHistory.');
  writeln('(c) copyright elitedevelopments software 2003. All rights reserved.');
  writeln;
  if (ParamCount > 0) and DirectoryExists(ParamStr(1)) then begin

    //if ExtractFileName(ParamStr(1)) = '__History' then begin
      CleanFolder(ParamStr(1),ExtractFileName(ParamStr(1)) = '__History',SwitchExists('recurse'));
      writeln;
      if SwitchExists('preview') then begin
        write(SizeString(gDeletedSpace)+' would be freed.');
      end
      else begin
        write(SizeString(gDeletedSpace)+' were freed.');
      end;
      writeln;
      writeln('Done.');
    {end
    else begin
      writeln;
      writeln('You may only run this tool on __History folders.');
      writeln('Use with caution, or you will have severe data loss!');
    end;}
  end
  else begin
    writeln('  This tool will clean the __History folders created by the StuffZipper.');
    writeln('  It will REMOVE ALL FILES from the given folder(s) that are not');
    writeln('    - newer then 15 days');
    writeln('    - the first file of the given month ');
    writeln;
    writeln('  The logic will be applied to all __History folders, and all THEIR subfolder.');
    writeln;
    writeln('  If in doubt, run the /preview switch to show what files would be deleted.');
    writeln;
    writeln('SYNTAX: CleanHistory <foldername> [/recurse] [/wait] [/preview]');
  end;
  writeln;
  if SwitchExists('wait') then begin
    readln;
  end;
end.


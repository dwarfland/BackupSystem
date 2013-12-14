unit Main;

interface

procedure Execute();

implementation

uses
  Windows, Messages, SysUtils, Variants, Classes,
  IniFiles, eStrings, eCmdLine, eFiles, eBackupSystemHelpers, DateUtils;


procedure DeleteOldHistoryFiles(const iDestinationFolder,iName:string);
var lSearch2:TSearchRec;
    lOk:dword;
    lHistoryFolder: string;
begin
  lHistoryFolder := MakePath(iDestinationFolder)+'__History\'+iName;
  ForceDirectories(lHistoryFolder);

  lOk := FindFirst(MakePath(iDestinationFolder)+iName+' - *.*',faAnyFile,lSearch2);
  try
    while lOk = 0 do begin
      if (lSearch2.Attr and faDirectory) = 0 then begin
        writeln('Moving old "'+lSearch2.Name+'" to History.');
        DeleteFile(pChar(MakePath(iDestinationFolder)+lSearch2.Name));
      end;
      lOk := FindNext(lSearch2);
    end;
  finally
    FindClose(lSearch2);
  end;
end;

procedure MoveOldFilesToHistory(const iDestinationFolder,iName:string);
var lSearch2:TSearchRec;
    lOk:dword;
    lHistoryFolder: string;
begin
  lHistoryFolder := MakePath(iDestinationFolder)+'__History\'+iName;
  ForceDirectories(lHistoryFolder);

  lOk := FindFirst(MakePath(iDestinationFolder)+iName+' - *.*',faAnyFile,lSearch2);
  try
    while lOk = 0 do begin
      if (lSearch2.Attr and faDirectory) = 0 then begin
        writeln('Moving old "'+lSearch2.Name+'" to History.');
        MoveFile(pChar(MakePath(iDestinationFolder)+lSearch2.Name),
                 pChar(MakePath(lHistoryFolder)+lSearch2.Name));
      end;
      lOk := FindNext(lSearch2);
    end;
  finally
    FindClose(lSearch2);
  end;
end;

function ArchiveFolderIfChanged(const iSourceFolder, iName:string; var ioLastArchiveDate:TDateTime; const iDestinationFolder, iWinZipPath:string; iParams:string; iSourceIsParentFolder:boolean=true; iNoHistory:boolean=false):boolean;
var
  lDate: TDatetime;
  lFolder,
  lDestinationFile,
  lTempDestinationFile,
  lSourcePattern,
  lZipCommand:string;
begin
  //lDestinationFile := MakePath(lDestinationFolder)+lSearch.Name;
  if iSourceIsParentFolder then
    lFolder := MakePath(MakePath(iSourceFolder)+iName)
  else
    lFolder := MakePath(iSourceFolder);

  lDate := GetFolderDate(ExcludeTrailingBackslash(lFolder));
  if ioLastArchiveDate = lDate then begin
    writeln(iName+' - archived '+DateTimeToStr(ioLastArchiveDate)+', no change since. skipping.');
    result := false;
  end
  else begin
    writeln(iName+' - archived '+DateTimeToStr(ioLastArchiveDate)+', changed '+DateTimeToStr(lDate));

    lDestinationFile := MakePath(iDestinationFolder)+iName+' - changed '+FormatDateTime('yyyymmdd-hhnnss',lDate)+' - created '+FormatDateTime('yyyymmdd-hhnnss',Now)+'.zip';
    lTempDestinationFile := MakePath(iDestinationFolder)+'__temp_'+iName+' - changed '+FormatDateTime('yyyymmdd-hhnnss',lDate)+' - created '+FormatDateTime('yyyymmdd-hhnnss',Now)+'.zip';
    lSourcePattern := MakePath(lFolder)+'*.*';

    { zip to temp file }
    //ChDir(ExtractFilePath(lSourcePattern));
    Replace(iParams,'%BASE%',ExtractFilePath(lSourcePattern));
    writeln('Zipping up "'+lSourcePattern+'" to "'+lTempDestinationFile+'".');
    lZipCommand := '-r -o -p -whs -ybc '+iParams+' "'+lTempDestinationFile+'" "'+lSourcePattern+'"';
    writeln('  '+lZipCommand);
    ExecuteAndWait(iWinzipPath,lZipCommand);

    if iNoHistory then begin
      DeleteOldHistoryFiles(iDestinationFolder,iName);
    end
    else begin
      { move old files to History folder }
      MoveOldFilesToHistory(iDestinationFolder,iName);
    end;


    { rename temp file to proper name }
    MoveFile(pChar(lTempDestinationFile),pChar(lDestinationFile));

    ioLastArchiveDate := lDate;
    result := true;
  end;
end;

procedure Process;
var i: Integer;
    lSourceFolder: string;
    lSearch:TSearchRec;
    lOk:dword;
    lDestinationFolder: string;
    lDateStr: string;
    lArciveDate: TDatetime;
    SourcePath: string;
    lDestinationFile,lTempDestinationFile: string;
    Command: string;
    fCfgFile:string;
    fFolders:TStringList;
    lWinzipPath, lWinZipParams:string;
    fDestination:string;
    lNoHistory: boolean;
begin
  fFolders := TStringList.Create();
  if ParamCount > 0 then
    fCfgFile := ParamStr(1)
  else
    fCfgFile := ChangeFileExt(GetModuleName,'.cfg');

  writeln('Reading config file '+fCfgFile);
  if FileExists(fCfgFile) then begin
    with TMemIniFile.Create(fCfgFile) do try
      fDestination := ReadString('General','Destination',ExtractFilePath(GetModuleName));
      lWinzipPath := ReadString('General','wzzip','c:\Program Files\WinZip\wzzip.exe');

      //for i := 0 to fFolders.Count-1 do begin
        //writeln('Folder '+fFolders.Names[i]);
      //end; { for }

      { Process Folders that have subfolders, in "Folders" section }

      ReadSectionValues('Folders',fFolders);
      for i := 0 to fFolders.Count-1 do try

        lSourceFolder := fFolders.Values[fFolders.Names[i]];

        lDestinationFolder := MakePath(fDestination)+fFolders.Names[i];
        ForceDirectories(lDestinationFolder);

        writeln('Folder '+fFolders.Names[i]+' '+lSourceFolder);
        lOk := FindFirst(MakePath(lSourceFolder)+'*.*',faDirectory,lSearch);
        try
          while lOk = 0 do begin
            if (lSearch.Name <> '.') and (lSearch.Name <> '..') and ((lSearch.Attr and faDirectory) = faDirectory)then begin
              //Writeln('  Subfolder '+lSearch.Name);

              lDateStr := ReadString('ArchiveDates for '+fFolders.Names[i],lSearch.Name,'');
              lArciveDate := StrToDateTimeDef(lDateSTr,0);

              lWinZipParams := ReadString('ZipParams',fFolders.Names[i],'')+' '+ReadString('ZipParams','*','');
              lNoHistory := ReadString('NoHistory',fFolders.Names[i],'false') = 'true';
              if ArchiveFolderIfChanged(lSourceFolder, lSearch.Name, lArciveDate, lDestinationFolder, lWinZipPath, lWinzipParams, true, lNoHistory) then begin
                WriteString('ArchiveDates for '+fFolders.Names[i],lSearch.Name,DateTimeToStr(lArciveDate));
                UpdateFile();
              end;

            end;
            lOk := FindNext(lSearch);
          end;    { while }

        finally
          FindClose(lSearch);
        end;

      except
        on E:Exception do begin
          Writeln(E.Classname+': '+E.Message);
          //ToDo: log message
        end;
      end;

      { Process Folders that don't have individual subfolders, in "SimpleFolders" section }

      ReadSectionValues('SimpleFolders',fFolders);
      for i := 0 to fFolders.Count-1 do try

        lSourceFolder := ExcludeTrailingBackslash(fFolders.Values[fFolders.Names[i]]);

        lDestinationFolder := MakePath(fDestination);//+fFolders.Names[i];
        ForceDirectories(lDestinationFolder);

        lDateStr := ReadString('ArchiveDates SimpleFolders',fFolders.Names[i],'');
        lArciveDate := StrToDateTimeDef(lDateSTr,0);

        lWinZipParams := ReadString('ZipParams',fFolders.Names[i],'');
        if ArchiveFolderIfChanged(lSourceFolder, fFolders.Names[i], lArciveDate, lDestinationFolder, lWinZipPath, lWinZipParams, false) then begin
          WriteString('ArchiveDates SimpleFolders',fFolders.Names[i],DateTimeToStr(lArciveDate));
          UpdateFile();
        end;

      except
        on E:Exception do begin
          Writeln(E.Classname+': '+E.Message);
          //ToDo: log message
        end;
      end;

    finally
      Free();
    end; { with }
  end;

end;

procedure Execute;
begin
  Writeln('elitedevelopments StuffZipper 0.3');
  Writeln;
  try
    Process();
  except
    on E:Exception do Writeln(E.Classname+': '+E.Message);
  end;
  Writeln('Done.');
  if SwitchExists('wait') then begin
    Writeln('Press Enter.');
    Readln;
  end;
  Writeln;
end;

end.

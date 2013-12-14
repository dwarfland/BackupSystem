unit eBackupSystemHelpers;

interface

uses Windows;

function GetFolderDate(const iFolder:string):TDateTime;
function FileTimeToDateTime(const iTime:TFileTime):TDateTime;

implementation

uses SysUtils;

function GetFolderDate(const iFolder:string):TDateTime;
var lSearch:TSearchRec;
    lOk:dword;
    lDate:TFileTime;
begin
  lOk := FindFirst(iFolder+'\*.*',$3f,lSearch);
  try
    if lOk <> 0 then
      raise Exception.CreateFmt('Folder "%s" nor found',[iFolder]);
    result := FileTimeToDateTime(lSearch.FindData.ftLastWriteTime);
  finally
    FindClose(lSearch);
  end;
end;

function FileTimeToDateTime(const iTime:TFileTime):TDateTime;
var lLocalFileTime: TFileTime;
    lFileDate:integer;
begin
  FileTimeToLocalFileTime(iTime, lLocalFileTime);
  if not FileTimeToDosDateTime(lLocalFileTime, LongRec(lFileDate).Hi, LongRec(lFileDate).Lo) then RaiseLastOsError();
  result := FileDateToDateTime(lFileDate);
end;


end.

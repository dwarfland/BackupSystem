program UnrarDiz;

{$APPTYPE CONSOLE}

uses SysUtils, Windows,
     eCmdLine, eFiles, eStrings;

var gWinRarPath : string = 'c:\Program Files\WinRAR\rar.exe';

var
  gErrors: boolean = false;
  gCount: integer = 0;

procedure RecursivelyUnrar(const iFolder:string; const iDest:string);
var lSearch:TSearchRec;
    lOk:dword;
    p,p2:Integer;
    lSkip:Boolean;
    lResult: integer;
begin
  lOk := SysUtils.FindFirst(iFolder+'\*.*',$3f,lSearch);
  try
    while lOk = 0 do begin

      if (lSearch.Name <> '.') and (lSearch.Name <> '..') then begin

        if (lSearch.Attr and faDirectory) = faDirectory then begin
          if not SwitchExists('quiet') then writeln(iFolder+'\'+lSearch.Name);
          RecursivelyUnrar(iFolder+'\'+lSearch.Name, iDest);
        end
        else begin
          if LowCaseStr(ExtractFileExt(lSearch.Name)) = '.rar' then begin

            p := Pos('part',lSearch.Name);
            p2 := Pos('.rar',lSearch.Name);

            lSkip := False;
            if (p <> 0) and (p+6=p2) and (Pos('part01',lSearch.Name) <> p) then lSkip := True;

            if not lSkip then begin
              //Writeln('!!!! x '+iFolder+'\'+lSearch.Name+' '+iDest);
              lResult := ExecuteAndWait(gWinRarPath,'x '+iFolder+'\'+lSearch.Name+' '+iDest);
              if lResult > 0 then begin
                writeln('winrar exited with code '+IntToStr(lResult)+'. Press enter to continue.');
                gErrors := true;
                readln;
              end
              else begin
                inc(gCount);
              end;

            end;

          end;
        end;
      end;

      lOk := SysUtils.FindNext(lSearch)
    end
  finally
    SysUtils.FindClose(lSearch);
  end;

end;

var
  lNewName: string;
begin
  try

    writeln('spb''s UnrarDiz 0.3!    BRONX - WHAT A RUSH!');
    writeln;

    if SwitchExists('rar') then gWinRarPath := SwitchStr('rar');

    if SwitchExists('dest') and (SwitchExists('folder')) then begin

      ForceDirectories(SwitchStr('dest'));
      RecursivelyUnrar(SwitchStr('folder'),SwitchStr('dest'));

      if (not gErrors) and (gCount > 0) then begin
        lNewName := ExtractFilePath(SwitchStr('folder'))+'___UnRARed__'+ExtractFileName(SwitchStr('folder'));
        SetCurrentDirectory(pChar(ExtractFilePath(SwitchStr('folder'))));
        if not MoveFile(pChar(SwitchStr('folder')),pChar(lNewName)) then
          writeln('rename failed with ', GetLastError)
        else
          writeln('renamed to '+lNewName);
      end;

      if gCount = 0 then begin
        writeln('Nothing to unpack.');
        readln;
      end;


      writeln('Done.');
      writeln;
    end
    else begin
      writeln('SYNTAX: UnrarDiz /dest:<folder to extract to>');
      writeln('                 /folder:<folder to scan>');
      writeln('                [/rar:<path to rar.exe>]');
      writeln;
    end;

    if SwitchExists('/wait') then begin
      readln;
    end;

  except
    on e:Exception do begin
      Writeln(E.Classname+': '+E.Message);
      readln;
    end;

  end
  { TODO -oUser -cConsole Main : Insert code here }
end.

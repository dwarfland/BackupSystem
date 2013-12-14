unit FtpDataModule;

interface

uses
  SysUtils, Classes, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdFTP;

type
  TFtpData = class(TDataModule)
    id_FTP: TIdFTP;
    procedure DataModuleCreate(Sender: TObject);
    procedure id_FTPStatus(ASender: TObject; const AStatus: TIdStatus;
      const AStatusText: String);
    procedure id_FTPWork(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCount: Integer);
  private
    fWorkCountMax: Integer;
    fLocalStartFolder: string;
    fRemoteStartFolder: string;
    { Private declarations }
  public
    procedure Initialize(const iConfigFile:string);
    procedure Sync(const iRemoteFolder,iLocalFolder:string);
  end;

var
  FtpData: TFtpData;

implementation

uses
  Forms, IniFiles,
  eStrings, IdFTPList;

{$R *.dfm}

procedure TFtpData.DataModuleCreate(Sender: TObject);
begin
  Initialize(ChangeFileExt(Application.ExeName,'.cfg'));
  id_FTP.Connect(true);
  try
    id_FTP.ChangeDir(fRemoteStartFolder);
    writeln('Changed to folder '+fRemoteStartFolder);
    Sync(fRemoteStartFolder,fLocalStartFolder);
  finally
    id_FTP.Disconnect();
  end;
end;

procedure TFtpData.Initialize(const iConfigFile: string);
begin
  with TMemIniFile.Create(iConfigFile) do try

    writeln('Loading config from '+iConfigFile);
    id_FTP.Host := ReadString('FTP','Server','');
    id_FTP.Port := StrToIntDef(ReadString('FTP','Server','21'),21);
    id_FTP.Username := ReadString('FTP','Login','anonymous');
    id_FTP.Password := ReadString('FTP','Password','email@email.com');
    id_FTP.Passive := ReadString('FTP','Passive','1') = '1';
    fRemoteStartFolder := MakePathUnix(ReadString('FTP','Folder',''));
    fLocalStartFolder := MakePath(ReadString('Local','Folder',''));
    ForceDirectories(fLocalStartFolder);

  finally
    Free();
  end; 
end;

procedure TFtpData.id_FTPStatus(ASender: TObject; const AStatus: TIdStatus;
  const AStatusText: String);
begin
  //writeln('Status: '+AStatusText);
end;

procedure TFtpData.Sync(const iRemoteFolder, iLocalFolder: string);
var i:integer;
    lFileSize: int64;
    lName: string;
    lListing:TIdFTPListItems;
    f:file;
begin
  id_FTP.List(nil);
  lListing := TIdFTPListItems.Create;
  try
    lListing.Assign(id_FTP.DirectoryListing);

    for i := 0 to lListing.Count-1 do  begin
      lName := lListing[i].FileName;
      case lListing[i].ItemType of

        ditDirectory:begin
            if not DirectoryExists(iLocalFolder+lName) then begin
              CreateDir(iLocalFolder+lName);
              writeln('folder '+iLocalFolder+lName+ ' (created)');
            end
            else begin
              writeln('folder '+iLocalFolder+lName+ ' (exists)');
            end;
            id_FTP.ChangeDir(iRemoteFolder+lName);
            try
              Sync(MakePathUnix(iRemoteFolder+lName),MakePath(iLocalFolder+lName));
            finally
              id_FTP.ChangeDir(iRemoteFolder);
            end;
          end;

        ditFile:begin
            if not FileExists(iLocalFolder+lName) then begin
              //CreateDir(iLocalFolder+lName);
              writeln('file   '+iLocalFolder+lName+ ' (missing)');
              fWorkCountMax := lListing[i].Size;
              try
                fWorkCountMax := lListing[i].Size;
                id_FTP.Get(iRemoteFolder+lName,iLocalFolder+lName,true);
              except
                on E:Exception do writeln('Failed ('+E.ClassName+': '+E.Message+')');
              end;
            end
            else begin
              AssignFile(f,iLocalFolder+lName);
              Reset(f,1);
              try
                lFileSize := FileSize(f);
              finally
                CloseFile(f);
              end;

              if (lFileSize < lListing[i].Size) then begin
                writeln(Format('file   '+iLocalFolder+lName+ ' (partial %s of %s)',[SizeString(lFileSize),SizeString(lListing[i].Size)]));
                try
                  DeleteFile(iLocalFolder+lName);
                  fWorkCountMax := lListing[i].Size;
                  id_FTP.Get(iRemoteFolder+lName,iLocalFolder+lName,true);
                except
                  on E:Exception do writeln('Failed ('+E.ClassName+': '+E.Message+')');
                end;
              end
              else begin
                writeln('file   '+iLocalFolder+lName+ ' (exists)');
              end;

            end;
          end;
      end;


    end;    // for

  finally
    FreeAndNil(lListing);
  end;
end;

function PercentageBar(iProgress,iMax:int64):string;
var lBars,lPercentage:int64;
begin
  lBars := 50;
  lPercentage := iProgress*lBars div iMax;
  result := WordStrFillSpace(iProgress*100 div iMax,3)+'% |'+FillStr('','#',lPercentage)+FillStr('','-',lBars-lPercentage)+'|'
end;

procedure TFtpData.id_FTPWork(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCount: Integer);
begin
  write(PercentageBar(AWorkCount,fWorkCountMax)+' Total: '+SizeString(fWorkCountMax)+'   Received: '+SizeString(AWorkCount)+#13);
end;

end.

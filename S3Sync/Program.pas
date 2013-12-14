namespace S3Sync;

interface

uses
  System.IO,
  System.Linq,
  Amazon.S3.*;

type
  ConsoleApp = class
  public
    class method Main(args: array of String);
  end;

implementation

class method ConsoleApp.Main(args: array of String);
begin
  Console.WriteLine('elitedevelopments Backup System - Cheap S3 Sync.');
  Console.WriteLine();
  if length(args) < 5 then begin
    Console.WriteLine('Syntax: S3Sync <local folder> <bucket> <bucket folder> <AccessKey> <SecretKey>');
    exit;
  end;

  var lConfig := new AmazonS3Config();
  lConfig.ServiceURL := "https://s3.amazonaws.com";
  var lS3Client := new AmazonS3Client(args[3], args[4]);

  Console.Write('Getting remote file list...');
  var lRequest := new ListObjectsRequest(BucketName := args[1], Prefix := args[2]);
  var lS3Objects := lS3Client.ListObjects(lRequest):S3Objects:&Select(o -> Path.GetFileName(o.Key.Replace('/',Path.DirectorySeparatorChar))).ToList;
  Console.WriteLine(' got '+lS3Objects.Count+' objects');

  {for each f in lS3Objects do
    Console.WriteLine('"'+f+'"');
  exit;}

  var lLocalFiles := Directory.GetFiles(args[0]);
  for each f in lLocalFiles do begin
    var lFilename := Path.GetFileName(f);
    if lS3Objects.Contains(lFilename) then begin
      Console.WriteLine(lFilename+' exists. skipping.');
      continue;
    end;
   
    Console.Write(lFilename+' uploading...');

    using lStream := new FileStream(f, FileMode.Open, FileAccess.Read, FileShare.Delete) do begin
      var lPutRequest := new PutObjectRequest(BucketName := args[1], Key := args[2]+'/'+lFilename, InputStream := lStream, Timeout := -1);
      lS3Client.PutObject(lPutRequest);
    end;
    Console.WriteLine(' uploaded.');
  end;
  Console.WriteLine('Done.');
end;

end.

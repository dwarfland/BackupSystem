namespace S3Sync;

uses
  System.Collections.Generic,
  System.IO,
  System.Linq,
  Amazon.S3.*,
  Amazon.SimpleWorkflow.Model;

type
  ConsoleApp = class
  public

    class method Main(args: array of String);
    begin
      Console.WriteLine('elitedevelopments Backup System - Cheap S3 Sync.');
      Console.WriteLine();
      if length(args) < 5 then begin
        Console.WriteLine('Syntax: S3Sync <local folder> <bucket> <bucket folder> <AccessKey> <SecretKey> [up|down]');
        exit;
      end;

      var lConfig := new AmazonS3Config();
      lConfig.ServiceURL := "https://s3.amazonaws.com";
      var lS3Client := new AmazonS3Client(args[3], args[4]);
      Console.WriteLine('key: "{0}"', args[0]);

      Console.Write('Getting remote file list...');
      var lS3Objects := GetAllFilenames(lS3Client, args[1], args[2]);
      Console.WriteLine(' got '+lS3Objects.Count+' objects');

      //for each f in lS3Objects do
      //  Console.WriteLine('"'+f+'"');
      //exit;

      if (length(args) ≥ 6) and (args[5]:ToLower = 'down') then begin

        //
        // Download
        //
        Directory.CreateDirectory(args[0]);
        var lLocalFiles := Directory.GetFiles(args[0]).Select(f -> Path.GetFileName(f));
        for each f in lS3Objects do begin
          if length(f) = 0 then continue; // S3 list will contain one empty item;

          var lFilename := f;
          if lLocalFiles.Contains(lFilename) then begin
            Console.WriteLine(lFilename+' exists. skipping.');
            continue;
          end;

          Console.Write(lFilename+' downloading...');

          var lGetRequest := new GetObjectRequest(BucketName := args[1], Key := args[2]+'/'+f);
          using lGetResponse := lS3Client.GetObject(lGetRequest) do begin
            lGetResponse.WriteResponseStreamToFile(Path.Combine(args[0], f));
          end;
          Console.WriteLine(' downloaded.');
        end;

      end
      else begin

        //
        // Upload
        //
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
            lS3Client.PutObject(lPutRequest).Dispose();
          end;
          Console.WriteLine(' uploaded.');
        end;

      end;
      Console.WriteLine('Done.');
    end;

  private

    class method GetAllFilenames(aS3Client: AmazonS3Client; aBucket: String; aPrefix: String): List<String>;
    begin
      var lastKey := "";
      var preLastKey := "";

      var lList := new List<String>();
      repeat
        preLastKey := lastKey;

        var lRequest := new ListObjectsRequest(BucketName := aBucket, Prefix := aPrefix);
        lRequest.Marker := lastKey;

        var newObjects := aS3Client.ListObjects(lRequest):S3Objects;
        for each o in newObjects do begin
          lList.Add(Path.GetFileName(o.Key.Replace('/',Path.DirectorySeparatorChar)));
          lastKey := o.Key;
        end;

      until lastKey = preLastKey;

      result := lList.OrderBy(n -> n).ToList();
    end;


  end;

end.
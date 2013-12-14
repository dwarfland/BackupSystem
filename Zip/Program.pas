namespace Zip;

interface

uses
  System.IO,
  System.Linq,
  Ionic.Zip;

type
  ConsoleApp = class
  private
    class method ProcessFolder(aFolder: String; aMask: String; aDestinationPath: String; aZipFile: ZipFile);
  public
    class method Main(args: array of String): Int32;
  end;

implementation

class method ConsoleApp.ProcessFolder(aFolder: String; aMask: String; aDestinationPath: String; aZipFile: ZipFile);
begin
  var lFiles := Directory.GetFiles(aFolder, aMask);
  for each f in lFiles do begin

    aZipFile.AddFile(f, aDestinationPath);
    Console.WriteLine(Path.Combine(aDestinationPath, Path.GetFileName(f)));
  end;
  var lDirectories := Directory.GetDirectories(aFolder, aMask);
  for each d in lDirectories do begin
    ProcessFolder(d, aMask, Path.Combine(aDestinationPath, Path.GetFileName(d)), aZipFile);
  end;
end;

class method ConsoleApp.Main(args: array of String): Int32;
begin
  Console.WriteLine('elitedevelopments Backup System - Command line Zip Hack.');
  Console.WriteLine();
  Console.WriteLine('This tools is aimed at replacinf wzzip.exe as called from StuffZipper.');
  Console.WriteLine('Do not use it for general purpose zipping');
  Console.WriteLine();

  // example command line from StuffZipper:
  //   -r -o -p -whs -ybc "c:\temp\BACKUPTEST\Test2\__temp_ci2 - changed 20130723-113046 - created 20131214-132328.zip" "v:\git\ci2\*.*"
  
  var lTarget: String;
  var lSourceMask: String;
  for each a in args do begin
    if a.StartsWith('-') then continue;
    if not assigned(lTarget) then lTarget := a
    else if not assigned(lSourceMask) then lSourceMask := a;
  end;

  if not assigned(lTarget) or not assigned(lSourceMask) then begin
    Console.WriteLine('At least two parameters expected, target.zip and source mask.');
    exit 1;
  end;

  using zip := new ZipFile() do begin
    
    // Ionic.Zip likes to hang when savuing files, unless we increase buffer size.
    zip.BufferSize := 1000000;
    zip.CodecBufferSize := 1000000;

    ProcessFolder(Path.GetDirectoryName(lSourceMask), Path.GetFileName(lSourceMask), Path.GetFileName(Path.GetDirectoryName(lSourceMask)), zip);   
    Console.WriteLine('Saving zip.');
    zip.Save(lTarget);
  end;

  Console.WriteLine('Done.');
end;

end.

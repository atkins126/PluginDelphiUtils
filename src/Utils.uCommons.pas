unit Utils.uCommons;

interface

uses
  WinApi.Windows, System.SysUtils, VCL.Dialogs;

function GetDLLPath: string;

implementation

function GetDLLPath: string;
var
  Buffer: array[0..MAX_PATH] of Char;
  DLLHandle: HMODULE;
  DLLPath: string;
begin
  DLLHandle := LoadLibrary('PluginDelphiUtils.dll');
  try
    if DLLHandle = 0 then
    begin
      ShowMessage('Falha ao carregar a DLL: PluginDelphiUtils');
      Exit;
    end;

    SetString(DLLPath, Buffer, GetModuleFileName(DLLHandle, Buffer, MAX_PATH));

    result := ExtractFilePath(DLLPath);
  finally
    FreeLibrary(DLLHandle);
  end;
end;

end.


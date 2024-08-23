unit uPluginMainMenu;

interface

uses
  ToolsAPI, ShellAPI, WinApi.Windows, VCL.Menus, System.SysUtils, Vcl.Dialogs;

type
  TPluginMainMenu = class(TInterfacedObject, IOTAWizard, IOTAMenuWizard, IOTAThreadNotifier)
  private
    FProcessEnd: boolean;

    { Assinaturas do IOTAWizard }
    function GetState: TWizardState;
    function GetIDString: string;
    function GetName: string;
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Execute;
    procedure Modified;

    { Assinatura da Interface IOTAMenuWizard }
    function GetMenuText: string;

    { Assinaturas do IOTAThreadNotifier }
    procedure EvaluteComplete(const ExprStr: string; const ResultStr: string; CanModify: Boolean; ResultAddress: Cardinal; ResultSize: Cardinal; ReturnCode: Integer);
    procedure ModifyComplete(const ExprStr: string; const ResultStr: string; ReturnCode: Integer);
    procedure ThreadNotify(Reason: TOTANotifyReason);

    procedure ExecutarDatasetViewer(Sender: TObject);
  public
    constructor Create;
  end;

function LoadPlugin(BorlandIDEServices: IBorlandIDEServices; RegisterProc: TWizardRegisterProc; var Terminate: TWizardTerminateProc): boolean; stdcall;

implementation

uses
  uCommons;

function LoadPlugin(BorlandIDEServices: IBorlandIDEServices; RegisterProc: TWizardRegisterProc; var Terminate: TWizardTerminateProc): boolean; stdcall;
begin
  result := True;

  RegisterProc(TPluginMainMenu.Create);
end;

{ TPluginMainMenu }

constructor TPluginMainMenu.Create;
var
  MainMenu: TMainMenu;
  MenuDelphiUtils: TMenuItem;
  MenuDatasetViewer: TMenuItem;
begin
  MainMenu := (BorlandIDEServices as INTAServices).MainMenu;

  MenuDelphiUtils := TMenuItem.Create(MainMenu);
  MenuDelphiUtils.Name := 'DelphiUtils';
  MenuDelphiUtils.Caption := 'Delphi Utils';
  MainMenu.Items.Add(MenuDelphiUtils);

  MenuDatasetViewer := TMenuItem.Create(MainMenu);
  MenuDatasetViewer.Name := 'DatasetViewer';
  MenuDatasetViewer.Caption := 'Dataset Viewer';
  MenuDatasetViewer.OnClick := ExecutarDatasetViewer;
  MenuDelphiUtils.Add(MenuDatasetViewer);
end;

procedure TPluginMainMenu.AfterSave;
begin

end;

procedure TPluginMainMenu.BeforeSave;
begin

end;

procedure TPluginMainMenu.Destroyed;
begin

end;

procedure TPluginMainMenu.Execute;
begin

end;

function TPluginMainMenu.GetIDString: string;
begin
  result := 'PluginDelphiUtils';
end;

function TPluginMainMenu.GetMenuText: string;
begin
  result := 'PluginDelphiUtils';
end;

function TPluginMainMenu.GetName: string;
begin
  result := 'PluginDelphiUtils';
end;

function TPluginMainMenu.GetState: TWizardState;
begin
  result := [wsEnabled];
end;

procedure TPluginMainMenu.Modified;
begin

end;

procedure TPluginMainMenu.EvaluteComplete(const ExprStr, ResultStr: string; CanModify: Boolean; ResultAddress, ResultSize: Cardinal; ReturnCode: Integer);
begin
  Self.FProcessEnd := True;
end;

procedure TPluginMainMenu.ModifyComplete(const ExprStr, ResultStr: string; ReturnCode: Integer);
begin

end;

procedure TPluginMainMenu.ThreadNotify(Reason: TOTANotifyReason);
begin

end;

procedure TPluginMainMenu.ExecutarDatasetViewer(Sender: TObject);
var
  pathDatasetViewer: string;
  psthData: string;
  selectDataset: string;
  command: string;
  topView: IOTAEditView;
  getBlock: IOTAEditBlock;
  currentProcess: IOTAProcess;
  currentThread: IOTAThread;
  evaluateResult: TOTAEvaluateResult;
  indiceNotifier: integer;

  // Variáveis para preencher os parâmetros "out" do Evaluate
  canModify: boolean;
  resultAddr: UInt64;
  resultSize: Cardinal;
  resultVal: Cardinal;
begin
  pathDatasetViewer := uCommons.GetDLLPath + '\DatasetViewer';

  psthData := pathDatasetViewer + '\data.xml';

  topView := (BorlandIDEServices as IOTAEditorServices).TopView;

  if not Assigned(topView) then
  begin
    ShowMessage('Dataset não selecionado.');
    Exit;
  end;

  getBlock := topView.GetBlock;

  if not Assigned(getBlock) then
  begin
    ShowMessage('Dataset não selecionado.');
    Exit;
  end;

  selectDataset := getBlock.Text;

  command := Format('%s.SaveToFile(''%s'')', [selectDataset, psthData]);

  currentProcess := (BorlandIDEServices as IOTADebuggerServices).CurrentProcess;

  if not Assigned(currentProcess) then
  begin
    ShowMessage('O visualizador de DataSets só pode ser executado em tempo de execução.');
    Exit;
  end;

  currentThread := (BorlandIDEServices as IOTADebuggerServices).CurrentProcess.CurrentThread;

  evaluateResult := currentThread.Evaluate(command, '', 0, canModify, True, '', resultAddr, resultSize, resultVal);

  if evaluateResult = erDeferred then
  begin
    Self.FProcessEnd := False;

    indiceNotifier := currentThread.AddNotifier(Self);

    while not Self.FProcessEnd do
      (BorlandIDEServices as IOTADebuggerServices).ProcessDebugEvents;

    currentThread.RemoveNotifier(indiceNotifier);
  end;

  if not (evaluateResult in [erError, erBusy]) then
    ShellExecute(0, 'open', PChar(pathDatasetViewer + '\DatasetViewer.exe ' + psthData), nil, nil, SW_SHOWNORMAL);
end;

end.

unit qplugins;

interface

{$I qdac.inc}
{$HPPEMIT '#pragma link "qplugins"'}

uses classes, sysutils, types, qstring, qvalue, qtimetypes, qdac_postqueue,
  qplugins_params, syncobjs, math{$IFDEF MSWINDOWS}, windows{$ENDIF} {$IFDEF POSIX},
  Posix.Unistd{$ENDIF}{$IFDEF UNICODE},
  Generics.collections{$ENDIF};

{ QPlugins ����������� Delphi �ӿ�ʵ�ֵ�Ԫ������������Ի����Լ���ʵ��
  ����Ԫʵ����Delphi�µ� QPlugins �ĺ���ʵ�֣�ע������������ļ�������·��������

  ���˵��
  2016.3.25
  =========
  * ������ TQBaseLoader ���ص� Loader ��ַ���������
  * ������ ServiceSource ���������ط������Դ�ļ�
  2015.8.8
  ========
  * �޸� TPointerList Ϊֱ��ӳ�䵽 TList �Խ�� C++ Builder �г����쳣����
  * ������ TQParams.ByName ʱ�ҵ�����Ȼѭ��������(�ܶ����棩
  * ������ TQParams ���浽���ټ��غ�������Ϣ��ʧ������
  2015.8.4
  =========
  * �޸�������ʽ��ʹ��ȫ�ֵĹ�������������ܴ��ڵ�������������С�⣩
  * �������ض����������ü�������ȷ����ɳ����˳�ʱ�ڴ����й¶������
  * ������ע�����ʱ���޷�ע�ᵽ��Ĭ�ϸ��������⣨��ˮ���걨�棩
  * ������ IdByName ʱ�����ظ�ID�����⣨�ഺ���棩
  2015.7.29
  =========
  + ���� RegisterServices �� UnregisterServices �Է�������ע����ע�����ഺ�ȣ�
  * ������ ByPath �Ǹ�·��������Ч�����⣨�ഺ���棩

  2015.7.27
  =========
  * ������ QueryInterface ʱ�ظ����� GetInstance �����⣨��л�¸磩
  + �����ĸ�Ԥ�����֪ͨID���ڲ�����غ�ж��ʱ����
  + ���� TQBaseLoader ʵ����Ϊ���м������Ļ���,����������Ӧ�Ĳ��ֽӿڼ���
  * ������ TQBaseLoader FreeLibraries ʱ��û�в��ʱ���쳣������
  2015.7.23
  ========
  * ������ByPath/ById ����ֵû��ʹ��GetInstance���ؿ��ܵ���ʵ�������⣨��л�¸磩
  * ������ByPathʱ Lock/Unlock ��Դ��󣨸�л�¸磩
  * �������滻PluginsManager�Ķ���ʼ�շ��� False �����⣨��л�¸磩

  2015.7.22
  =========
  + ��ʼ�汾
}
const
  // ��־��¼����
  LOG_EMERGENCY: BYTE = 0;
  LOG_ALERT = 1;
  LOG_FATAL = 2;
  LOG_ERROR = 3;
  LOG_WARN = 4;
  LOG_HINT = 5;
  LOG_MESSAGE = 6;
  LOG_DEBUG = 7;
  // Ԥ����֪ͨ��ID
  NID_MANAGER_REPLACED = 0; // ������������滻�����ֻ֪ͨ��Ҫ�����ڲ����Ӧ��
  NID_MANAGER_FREE = 1; // �����������Ҫ�������ͷ�
  NID_LOADERS_STARTING = 2; // ��������������
  NID_LOADERS_STARTED = 3; // �������������
  NID_LOADERS_STOPPING = 4; // ������ֹͣ��
  NID_LOADERS_STOPPED = 5; // ��������ֹͣ
  NID_LOADERS_PROGRESS = 6; // ����������/ֹͣ����
  NID_LOADER_ERROR = 7; // ���������س���
  NID_PLUGIN_LOADING = 8; // ���ڼ��ز��
  NID_PLUGIN_LOADED = 9; // ���ز�����
  NID_PLUGIN_UNLOADING = 10; // ����׼��ж��
  NID_PLUGIN_UNLOADED = 11; // ����ж�����
  NID_NOTIFY_PROCESSING = 12; // ֪ͨ��Ҫ������
  NID_NOTIFY_PROCESSED = 13; // ֪ͨ�Ѿ��������
  NID_SERVICE_READY = 14; // ����ע�����

type
  // �汾��Ϣ
  TQShortVersion = packed record
    case Integer of
      0:
        (Major, Minor, Release, Build: BYTE); // �������������������İ汾��
      1:
        (Value: Integer);
  end;
{$IF RTLVersion>=21}
{$M+}
{$IFEND}

  // �汾��Ϣ�ṹ
  TQVersion = packed record
    Version: TQShortVersion; // �汾
    Company: array [0 .. 63] of WideChar; // ��˾��
    Name: array [0 .. 63] of WideChar; // ģ������
    Description: array [0 .. 255] of WideChar; // ����
    FileName: array [0 .. MAX_PATH] of WideChar; // ԭʼ�ļ���
  end;

  // ����汾��Ϣ
  IQVersion = interface
    ['{4AD82500-4148-45D1-B0F8-F6B6FB8B7F1C}']
    function GetVersion(var AVerInfo: TQVersion): Boolean; stdcall;
  end;

  IQServices = interface;
  IQLoader = interface;

  // ��������
  IQService = interface
    ['{0DA5CBAC-6AB0-49FA-B845-FDF493D9E639}']
    function GetInstance: IQService; stdcall;
    function GetOwnerInstance: THandle; stdcall;
    function Execute(AParams: IQParams; AResult: IQParams): Boolean; stdcall;
    function Suspended(AParams: IQParams): Boolean; stdcall;
    function Resume(AParams: IQParams): Boolean; stdcall;
    function GetParent: IQServices; stdcall;
    function GetInstanceCreator: IQService; stdcall;
    procedure AddExtension(AInterface: IInterface); stdcall;
    procedure RemoveExtension(AInterface: IInterface); stdcall;
    procedure SetParent(AParent: IQServices); stdcall;
    function GetName: PWideChar; stdcall;
    function GetAttrs: IQParams; stdcall;
    function GetLastErrorMsg: PWideChar; stdcall;
    function GetLastErrorCode: Cardinal; stdcall;
    function GetId: TGuid; stdcall;
    function GetLoader: IQLoader; stdcall;
    function GetOriginObject: Pointer; stdcall;
    function IsInModule(AModule: THandle): Boolean; stdcall;
    property Parent: IQServices read GetParent write SetParent;
    property Name: PWideChar read GetName;
    property Attrs: IQParams read GetAttrs;
    property LastError: Cardinal read GetLastErrorCode;
    property LastErrorMsg: PWideChar read GetLastErrorMsg;
    property Loader: IQLoader read GetLoader;
    property Creator: IQService read GetInstanceCreator;
  end;

  // ��������б�
  IQServices = interface
    ['{7325DF17-BC83-4163-BB72-0AE0208352ED}']
    function GetItems(AIndex: Integer): IQService; stdcall;
    function GetCount: Integer; stdcall;
    function ByPath(APath: PWideChar): IQService; stdcall;
    function ById(const AId: TGuid): IQService; stdcall;
    function Add(AItem: IQService): Integer; stdcall;
    function IndexOf(AItem: IQService): Integer; stdcall;
    procedure Delete(AIndex: Integer); stdcall;
    procedure Remove(AItem: IQService); stdcall;
    function MoveTo(AIndex, ANewIndex: Integer): Boolean; stdcall;
    procedure Clear; stdcall;
    function GetParent: IQServices; stdcall;
    function GetName: PWideChar; stdcall;
    function GetOwnerInstance: HINST; stdcall;
    property Name: PWideChar read GetName;
    property Parent: IQServices read GetParent;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: IQService read GetItems; default;
  end;

  // ֪ͨ��Ӧ�ӿ�
  IQNotify = interface
    ['{00C7F80F-44BF-4E60-AA58-5992B2B71754}']
    procedure Notify(const AId: Cardinal; AParams: IQParams;
      var AFireNext: Boolean); stdcall;
  end;

  TQSubscribeEnumCallback = procedure(ANotify: IQNotify; AParam: Int64;
    var AContinue: Boolean);

  // ֪ͨ������
  IQNotifyManager = interface
    ['{037DCCD1-6877-4917-A315-120CD3E403F4}']
    function Subscribe(ANotifyId: Cardinal; AHandler: IQNotify)
      : Boolean; stdcall;
    procedure Unsubscribe(ANotifyId: Cardinal; AHandler: IQNotify); stdcall;
    function IdByName(const AName: PWideChar): Cardinal; stdcall;
    function NameOfId(const AId: Cardinal): PWideChar; stdcall;
    procedure Send(AId: Cardinal; AParams: IQParams); stdcall;
    procedure Post(AId: Cardinal; AParams: IQParams); stdcall;
    procedure Clear;
    function EnumSubscribe(ANotifyId: Cardinal;
      ACallback: TQSubscribeEnumCallback; AParam: Int64): Integer; stdcall;
    function GetCount: Integer; stdcall;
    function GetId(const AIndex: Integer): Cardinal; stdcall;
    function GetName(const AIndex: Integer): PWideChar; stdcall;
    property Count: Integer read GetCount;
    property Id[const AIndex: Integer]: Cardinal read GetId;
    property Name[const AIndex: Integer]: PWideChar read GetName;
  end;

  // �����ı���·�ɹ�����Ŀ���˽ӿڽ�Ϊ��ʾ���޸�ʹ��
  IQTextRouter = interface(IQService)
    ['{F3834278-4D2F-46D5-AA72-6EF016CE7F3A}']
    function GetSource: PWideChar; stdcall; // ����Դ
    function GetTarget: PWideChar; stdcall; // ����Ŀ��
    procedure SetRule(const ASource, ATarget: PWideChar); stdcall; // ����Ŀ���Դ
  end;

  // ���� ID ӳ��Ĺ�����Ŀ
  IQIdRouter = interface(IQService)
    ['{C2390553-ABE3-489A-8713-CB28A938C000}']
    function GetSource: TGuid; stdcall;
    function GetTarget: TGuid; stdcall;
    procedure SetRule(const ASource, ATarget: TGuid); stdcall;
  end;

  TQModuleState = (msUnknown, msLoading, msLoaded, msUnloading);
  TQLoaderState = (lsIdle, lsLoading, lsUnloading);

  // �������ӿڣ�����ʵ�ֻ����� TQBaseLoader
  IQLoader = interface(IQService)
    ['{3F576A14-D251-47C4-AB6E-0F89B849B71F}']
    function GetServiceSource(AService: IQService; ABuf: PWideChar;
      ALen: Integer): Integer; stdcall;
    procedure Start; stdcall;
    procedure Stop; stdcall;
    function LoadServices(const AFileName: PWideChar): THandle;
      stdcall; overload;
    function LoadServices(const AStream: IQStream): THandle; stdcall; overload;
    function UnloadServices(const AHandle: THandle; AWaitDone: Boolean = True)
      : Boolean; stdcall;
    function GetModuleCount: Integer; stdcall;
    function GetModuleName(AIndex: Integer): PWideChar; stdcall;
    function GetModules(AIndex: Integer): HMODULE; stdcall;
    function GetModuleState(AInstance: HINST): TQModuleState; stdcall;
    procedure SetLoadingModule(AInstance: HINST); stdcall;
    function GetState: TQLoaderState; stdcall;
  end;

  // ��־�ӿڣ������Ҫ��װ��
  IQLog = interface(IQService)
    ['{14F4C543-2D43-4AAD-BAFE-B25784BC917D}']
    procedure Post(ALevel: BYTE; AMsg: PWideChar); stdcall;
    procedure Flush; stdcall;
  end;

  TQServiceCallback = procedure(const AService: IQService); stdcall;

  // ��������������з�����ܹܼ�
  IQPluginsManager = interface(IQServices)
    ['{BDE6247B-87AD-4105-BDC9-1EA345A9E4B0}']
    function GetLoaders: IQServices; stdcall;
    function GetRouters: IQServices; stdcall;
    function GetServices: IQServices; stdcall;
    function ForcePath(APath: PWideChar): IQServices; stdcall;
    function GetActiveLoader: IQLoader; stdcall;
    procedure SetActiveLoader(ALoader: IQLoader); stdcall;
    procedure Start; stdcall;
    procedure ModuleUnloading(AInstance: HINST); stdcall;
    procedure AsynCall(AProc: TQAsynProc; AParams: IQParams); stdcall;
    procedure ProcessQueuedCalls; stdcall;
    function Stop: Boolean; stdcall;
    function Replace(ANewManager: IQPluginsManager): Boolean; stdcall;
    function WaitService(const AService: PQCharW; ANotify: TQServiceCallback)
      : Boolean; overload; stdcall;
    function WaitService(const AId: TGuid; ANotify: TQServiceCallback): Boolean;
      overload; stdcall;
    procedure RemoveServiceWait(ANotify: TQServiceCallback); overload; stdcall;
    procedure RemoveServiceWait(const AService: PQCharW;
      ANotify: TQServiceCallback); overload; stdcall;
    procedure RemoveServiceWait(const AId: TGuid; ANotify: TQServiceCallback);
      overload; stdcall;
    procedure ServiceReady(AService: IQService); stdcall;
    property Services: IQServices read GetServices;
    property Routers: IQServices read GetRouters;
    property Loaders: IQServices read GetLoaders;
    property ActiveLoader: IQLoader read GetActiveLoader write SetActiveLoader;
  end;

  IQLocker = interface
    ['{5008B5D4-EE67-419D-80CB-E5C62FA95243}']
    procedure Lock; stdcall;
    procedure Unlock; stdcall;
  end;
{$IF RTLVersion>=21}
{$M-}
{$IFEND}
  // ������Delphi�������ӿڵ�ʵ��

  TQServices = class;

  PQServiceExtension = ^TQServiceExtension;

  TQServiceExtension = record
    Instance: IInterface;
    Next: PQServiceExtension;
  end;

  TQService = class(TQInterfacedObject, IQService)
  private
    function GetPath: QStringW;
  protected
    FId: TGuid;
    FName: QStringW;
    FAttrs: IQParams;
    FErrorCode: Cardinal;
    FErrorMsg: QStringW;
    FParent: Pointer; // ��ʹ��IQServices���Ա����ɴ��������ü���
    FLoader: Pointer;
    FCreator: Pointer; // ����Ĵ�����ʵ������ʵ��ʱ����ָ��������
    FFirstExt, FLastExt: PQServiceExtension;
    function GetParent: IQServices; stdcall;
    procedure SetParent(AParent: IQServices); stdcall;
    function GetName: PWideChar; stdcall;
    function GetAttrs: IQParams; stdcall;
    function GetLastErrorMsg: PWideChar; stdcall;
    function GetLastErrorCode: Cardinal; stdcall;
    function GetId: TGuid; stdcall;
    function GetDParent: TQServices;
    function GetServiceAttrs: TQParams; virtual;
    function GetLoader: IQLoader; virtual; stdcall;
    procedure SetLastError(ACode: Cardinal; AMsg: QStringW);
    procedure ValidName(const S: QStringW);
    function GetOriginObject: Pointer; virtual; stdcall;
    function IsInModule(AModule: THandle): Boolean; stdcall;
    function GetInstanceCreator: IQService; virtual; stdcall;
    procedure ClearExts;
  public
    constructor Create(const AId: TGuid; AName: QStringW); overload; virtual;
    destructor Destroy; override;
    function GetInstance: IQService; virtual; stdcall;
    function Execute(AParams: IQParams; AResult: IQParams): Boolean;
      virtual; stdcall;
    function Suspended(AParams: IQParams): Boolean; virtual; stdcall;
    function Resume(AParams: IQParams): Boolean; virtual; stdcall;
    function GetOwnerInstance: HINST; stdcall;
    procedure AddExtension(AInterface: IInterface); stdcall;
    procedure RemoveExtension(AInterface: IInterface); stdcall;
    function QueryInterface(const IID: TGuid; out Obj): HRESULT;
      override; stdcall;
    property Parent: TQServices read GetDParent;
    property Id: TGuid read FId;
    property Name: QStringW read FName;
    property Path: QStringW read GetPath;
    property Attrs: TQParams read GetServiceAttrs;
    property LastError: Cardinal read FErrorCode;
    property LastErrorMsg: QStringW read FErrorMsg;
  end;

  TQPointerList = TList;

  TQServices = class(TQService, IQServices)
  protected
    FItems: TQPointerList;
    function GetItems(AIndex: Integer): IQService; stdcall;
    function GetCount: Integer; stdcall;
  public
    constructor Create(const AId: TGuid; AName: QStringW); override;
    destructor Destroy; override;
    function ByPath(APath: PWideChar): IQService; virtual; stdcall;
    function ById(const AId: TGuid): IQService; virtual; stdcall;
    function Add(AItem: IQService): Integer; virtual; stdcall;
    function IndexOf(AItem: IQService): Integer; virtual; stdcall;
    procedure Delete(AIndex: Integer); virtual; stdcall;
    function MoveTo(AIndex, ANewIndex: Integer): Boolean; virtual; stdcall;
    procedure Remove(AItem: IQService); virtual; stdcall;
    procedure Clear; virtual; stdcall;
    function QueryInterface(const IID: TGuid; out Obj): HRESULT;
      override; stdcall;
  end;

  TQNotifyManager = class;

  TQNotifyItem = class
  private
    function GetCount: Integer;
    function GetItems(AIndex: Integer): IQNotify;
  protected
    FId: Cardinal;
    FName: QStringW;
    FItems: TQPointerList;
    FOwner: TQNotifyManager;
  public
    constructor Create(AOwner: TQNotifyManager; AId: Cardinal;
      AName: QStringW); overload;
    destructor Destroy; override;
    function Add(ANotify: IQNotify): Integer;
    procedure Remove(ANotify: IQNotify);
    procedure Clear;
    property Id: Cardinal read FId;
    property Name: QStringW read FName;
    property Items[AIndex: Integer]: IQNotify read GetItems; default;
    property Count: Integer read GetCount;
  end;

  TQNotifyManager = class(TQInterfacedObject, IQNotifyManager)
  protected
    FItems: TQPointerList;
    FNextId: Cardinal;
    FBeforeProcessNotify, FAfterProcessNotify: TQNotifyItem;
    procedure Clear;
    procedure HandlePost(AParams: IInterface);
    procedure DoNotify(AId: Cardinal; AParams: IQParams);
  public
    constructor Create; override;
    destructor Destroy; override;
    function Subscribe(ANotifyId: Cardinal; AHandler: IQNotify)
      : Boolean; stdcall;
    procedure Unsubscribe(ANotifyId: Cardinal; AHandler: IQNotify); stdcall;
    function EnumSubscribe(ANotifyId: Cardinal;
      ACallback: TQSubscribeEnumCallback; AParam: Int64): Integer; stdcall;
    function IdByName(const AName: PWideChar): Cardinal; stdcall;
    function NameOfId(const AId: Cardinal): PWideChar; stdcall;
    procedure Send(AId: Cardinal; AParams: IQParams); stdcall;
    procedure Post(AId: Cardinal; AParams: IQParams); stdcall;
    function GetCount: Integer; stdcall;
    function GetId(const AIndex: Integer): Cardinal; stdcall;
    function GetName(const AIndex: Integer): PWideChar; stdcall;
    property Count: Integer read GetCount;
    property Id[const AIndex: Integer]: Cardinal read GetId;
    property Name[const AIndex: Integer]: PWideChar read GetName;
  end;

  TQLoadedModule = record
    FileName: QStringW;
    Handle: THandle;
  end;

  PQLoadedModule = ^TQLoadedModule;
  TQBaseLoader = class;
  TQAcceptModuleEvent = procedure(ALoader: TQBaseLoader; AFileName: QStringW;
    var Accept: Boolean);

  TQBaseLoader = class(TQService, IQLoader, IQVersion)
  protected
    FFileExt: QStringW;
    FPath: QStringW;
    FIncludeSubDir: Boolean;
    FItems: TQPointerList;
    FState: TQLoaderState;
    FActiveFileName: QStringW;
    FOnAccept: TQAcceptModuleEvent;
    FLoadingModule, FUnloadingModule: HINST;
    procedure Clear; virtual;
    function GetServiceSource(AService: IQService; ABuf: PWideChar;
      ALen: Integer): Integer; virtual; stdcall;
    function InternalLoadServices(const AFileName: PWideChar): THandle;
      overload; virtual;
    function InternalLoadServices(const AStream: TStream): THandle;
      overload; virtual;
    function LoadServices(const AFileName: PWideChar): THandle;
      overload; stdcall;
    procedure Start; virtual; stdcall;
    procedure Stop; virtual; stdcall;
    function LoadServices(const AStream: IQStream): THandle; overload; stdcall;
    function InternalUnloadServices(const AHandle: THandle): Boolean; virtual;
    function UnloadServices(const AHandle: THandle; AWaitDone: Boolean = True)
      : Boolean; stdcall;
    function GetVersion(var AVerInfo: TQVersion): Boolean; virtual; stdcall;
    function GetModuleCount: Integer; virtual; stdcall;
    function GetModuleName(AIndex: Integer): PWideChar; virtual; stdcall;
    function GetModules(AIndex: Integer): HMODULE; virtual; stdcall;
    procedure AddModule(AFileName: QStringW; AHandle: THandle);
    procedure RemoveModule(AModule: PQLoadedModule);
    function FileByHandle(AHandle: THandle): String;
    function HandleByFile(AFileName: QStringW): THandle;
    function GetLoader: IQLoader; override; stdcall;
    procedure AsynUnload(AParams: IInterface);
    function GetModuleState(AInstance: HINST): TQModuleState; stdcall;
    procedure SetLoadingModule(AInstance: HINST); stdcall;
    function GetState: TQLoaderState; stdcall;
  public
    constructor Create(const AId: TGuid; AName: QStringW; APath, AExt: QStringW;
      AIncSubDir: Boolean = false); overload;
    destructor Destroy; override;
    function Execute(AParams: IQParams; AResult: IQParams): Boolean;
      override; stdcall;
    property FileExt: QStringW read FFileExt;
    property Path: QStringW read FPath;
    property OnAccept: TQAcceptModuleEvent read FOnAccept write FOnAccept;
  end;

  TQInterfaceHolder = class(TComponent)
  private
    FInterface: IInterface;
  public
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(AOwner: TComponent; AInterface: IInterface);
      reintroduce; overload;
    property InterfaceObject: IInterface read FInterface write FInterface;
  end;

  /// <summary>
  /// ����ȫ�ֵ� PluginsManager ʵ���������δ�������򴴽���
  /// </summary>
  /// <remarks>
  /// ע�⣺ÿ���������Լ������Ĳ��������
  /// </remarks>
function PluginsManager: IQPluginsManager;
/// <summary>
/// ע��һ�����
/// </summary>
/// <param name="AParent">
/// ����ĸ�·��
/// </param>
/// <param name="AServices">
/// �����б�������ʵ��IQService�ӿ�
/// </param>
procedure RegisterServices(AParent: PWideChar; AServices: array of IQService);
/// <summary>
/// ȡ��һ������ע��
/// </summary>
/// <param name="APath">
/// ����ĸ�·��
/// </param>
/// <param name="AServices">
/// Ҫȡ��ע��ķ��������б�
/// </param>
procedure UnregisterServices(APath: PWideChar; AServices: array of QStringW);
/// <summary>
/// ��ȡ�������Դģ����
/// </summary>
/// <param name="AService">
/// Ҫ������Դģ��ķ���ʵ��
/// </param>
function ServiceSource(AService: IQService): QStringW;
/// <summary>
/// ��ָ���ĸ�����£�����ָ��·���ķ���
/// </summary>
/// <param name="AParent">
/// �����
/// </param>
/// <param name="APath">
/// �������ڵ�·���������/��ʼ�������AParent���Ӹ���ʼ�������AParent��ʼ���²���
/// </param>
/// <remarks>
/// ע�� FindService ������� GetInstance �������ص�ʼ����ʵ���������� GetService ����� FindService
/// �� GetInstance��Ҳ����˵�����ڶ�ʵ��������˵��FindService���صĶ�ʵ������������ GetService
/// ���ص�ʼ�����ṩ����ľ���ʵ����
/// </remarks>
function FindService(AParent: IQServices; APath: PWideChar): IQService;
  overload;
/// <summary>
/// ��ָ���ĸ�����£�����ָ��·���ķ���
/// </summary>
/// <param name="APath">
/// �Ӹ���ʼ�ķ������ڵ�·��
/// </param>
/// <param name="AId">
/// �����IID����
/// </param>
/// <param name="AService">
/// ���صķ���ʵ��
/// </param>
/// <returns>
/// �ҵ���Ӧ�ķ��񣬷���true�����򷵻�false
/// </returns>
/// <remarks>
/// ע�� FindService ������� GetInstance �������ص�ʼ����ʵ���������� GetService ����� FindService
/// �� GetInstance��Ҳ����˵�����ڶ�ʵ��������˵��FindService���صĶ�ʵ������������ GetService
/// ���ص�ʼ�����ṩ����ľ���ʵ����
/// </remarks>
function FindService(APath: PWideChar; const AId: TGuid; out AService)
  : Boolean; overload;
/// <summary>
/// ��ָ���ĸ�����£�����ָ��·���ķ���
/// </summary>
/// <param name="APath">
/// �Ӹ���ʼ�ķ������ڵ�·��
/// </param>
/// <returns>
/// �����ҵ��ķ���
/// </returns>
/// <remarks>
/// ע�� FindService ������� GetInstance �������ص�ʼ����ʵ���������� GetService ����� FindService
/// �� GetInstance��Ҳ����˵�����ڶ�ʵ��������˵��FindService���صĶ�ʵ������������ GetService
/// ���ص�ʼ�����ṩ����ľ���ʵ����
/// </remarks>
function FindService(APath: PWideChar): IQService; overload;

/// <summary>
/// ��ȡָ��·���ķ���ʵ��������Ƕ�ʵ�����򷵻�һ�������ṩ�������ʵ����
/// </summary>
/// <param name="APath">
/// �Ӹ���ʼ�ķ������ڵ�·��
/// </param>
/// <returns>
/// �����ҵ��ķ���
/// </returns>
/// <remarks>
/// ע�� FindService ������� GetInstance �������ص�ʼ����ʵ���������� GetService ����� FindService
/// �� GetInstance��Ҳ����˵�����ڶ�ʵ��������˵��FindService���صĶ�ʵ������������ GetService
/// ���ص�ʼ�����ṩ����ľ���ʵ����
/// </remarks>
function GetService(APath: PWideChar): IQService; overload;
/// <summary>
/// ��ȡָ��·���ķ���ʵ��������Ƕ�ʵ�����򷵻�һ�������ṩ�������ʵ����
/// </summary>
/// <param name="AParent">
/// �����
/// </param>
/// <param name="APath">
/// �������ڵ�·���������/��ʼ�������AParent���Ӹ���ʼ�������AParent��ʼ���²���
/// </param>
/// <returns>
/// �����ҵ��ķ���
/// </returns>
function GetService(AParent: IQServices; APath: PWideChar): IQService; overload;
/// <summary>
/// ��ȡָ��·���ķ���ʵ��������Ƕ�ʵ�����򷵻�һ�������ṩ�������ʵ����
/// </summary>
/// <param name="APath">
/// �������ڵ�·��
/// </param>
/// <param name="AId">
/// �����IID����
/// </param>
/// <param name="AService">
/// ���صķ���ʵ��
/// </param>
/// <returns>
/// �ҵ���Ӧ�ķ��񣬷���true�����򷵻�false
/// </returns>
/// <remarks>
/// ע�� FindService ������� GetInstance �������ص�ʼ����ʵ���������� GetService ����� FindService
/// �� GetInstance��Ҳ����˵�����ڶ�ʵ��������˵��FindService���صĶ�ʵ������������ GetService
/// ���ص�ʼ�����ṩ����ľ���ʵ����
/// </remarks>
function GetService(APath: PWideChar; const AId: TGuid; out AService)
  : Boolean; overload;

/// <summary>
/// ��ȡ���������ļ�����ʵ������������ǵ�ǰ����������ע��ģ��򷵻ؿ�
/// </summary>
/// <param name="AService">
/// Ҫ��ѯ�ķ���ʵ��
/// </param>
/// <returns>
/// �ɹ������ؼ������ӿ�ʵ����ʧ�ܻ����Ϊ������ǰע��ģ��򷵻ؿ�
/// </returns>
/// <remarks>
/// ע�� FindService ������� GetInstance �������ص�ʼ����ʵ���������� GetService ����� FindService
/// �� GetInstance��Ҳ����˵�����ڶ�ʵ��������˵��FindService���صĶ�ʵ������������ GetService
/// ���ص�ʼ�����ṩ����ľ���ʵ����
/// </remarks>

function ServiceLoader(AService: IInterface): IQLoader;
/// <summary>
/// ��ȡ����������ģ��
/// </summary>
/// <param name="AService">
/// Ҫ��ѯ�ķ���ʵ��
/// </param>
/// <returns>
/// �ɹ�������ģ������ʧ�ܣ�����0
/// </returns>
function ServiceModule(AService: IInterface): HMODULE;

/// <summary>
/// ��ȡָ���ķ����ע������·��
/// </summary>
/// <param name="AService">
/// Ҫ��ѯ�ķ���ʵ��
/// </param>
/// <returns>
/// ���ط��������·��������PluginsManager��
/// </returns>
function ServicePath(AService: IQService;APathDelimiter:QCharW='/'): QStringW;
function UnloadServices(AInstance: HMODULE; AWaitDone: Boolean): Boolean;
function HoldByComponent(AOwner: TComponent; AInterface: IInterface)
  : TComponent;
var
  PathDelimiter: PQCharW = '/';
implementation

const
  NullChar: WideChar = #0;

resourcestring
  SInvalidName = '��Ч�Ľ�����ƣ������в��ܰ��� "/"��';
  SMismatchServicePath = '����ķ���·�� %s �����ڻ����Ͳ�ƥ�䡣';

type

  TQStringService = class(TQService, IQStringService)
  public
    function NewString(S: PWideChar): IQString; stdcall;
  end;

  PServiceWaitItem = ^TServiceWaitItem;

  TServiceWaitItem = record
    Path: QStringW;
    Id: TGuid;
    Next: PServiceWaitItem;
    case Integer of
      0:
        (OnReady: TQServiceCallback);
      1:
        (Method: TMethod);
  end;

  // TQPluginsManager ʵ����IQService/IQServices/IQNotify�ӿ�
  TQPluginsManager = class(TQServices, IQPluginsManager, IQNotify)
  private
  protected
    FRouters: IQServices;
    FServices: IQServices;
    FLoaders: IQServices;
    FActiveLoader: IQLoader;
    FWaitingServices: PServiceWaitItem;
    FNotifyMgr: IQNotifyManager;
    function GetLoaders: IQServices; stdcall;
    function GetRouters: IQServices; stdcall;
    function GetServices: IQServices; stdcall;
    function GetActiveLoader: IQLoader; stdcall;
    procedure SetActiveLoader(ALoader: IQLoader); stdcall;
    function DoLoaderAction(AStartAction, AStopAction: BYTE;
      ARevert: Boolean): Boolean;
    procedure Notify(const AId: Cardinal; AParams: IQParams;
      var AFireNext: Boolean); stdcall;
    function WaitService(const AService: PQCharW; ANotify: TQServiceCallback)
      : Boolean; overload; stdcall;
    function WaitService(const AId: TGuid; ANotify: TQServiceCallback): Boolean;
      overload; stdcall;
    procedure RemoveServiceWait(ANotify: TQServiceCallback); overload; stdcall;
    procedure RemoveServiceWait(const AService: PQCharW;
      ANotify: TQServiceCallback); overload; stdcall;
    procedure RemoveServiceWait(const AId: TGuid; ANotify: TQServiceCallback);
      overload; stdcall;
    procedure ServiceReady(AService: IQService); stdcall;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Start; stdcall;
    function Stop: Boolean; stdcall;
    function Replace(ANewManager: IQPluginsManager): Boolean; stdcall;
    function ForcePath(APath: PWideChar): IQServices; stdcall;
    function QueryInterface(const IID: TGuid; out Obj): HRESULT;
      override; stdcall;
    function ByPath(APath: PWideChar): IQService; override; stdcall;
    function ById(const AId: TGuid): IQService; override; stdcall;
    function PathOf(AService: IQService): QStringW;
    procedure AsynCall(AProc: TQAsynProc; AParams: IQParams); stdcall;
    procedure ProcessQueuedCalls; stdcall;
    procedure ModuleUnloading(AInstance: HINST); stdcall;
    function _AddRef: Integer; override; stdcall;
    function _Release: Integer; override; stdcall;
    property Services: IQServices read GetServices;
    property Router: IQServices read GetRouters;
    property Loaders: IQServices read GetLoaders;
  end;

  TQManagerChangeHandler = class(TQInterfacedObject, IQNotify)
  protected
    procedure Notify(const AId: Cardinal; AParams: IQParams;
      var AFireNext: Boolean); stdcall;
  end;

  TQLocker = class(TQInterfacedObject, IQLocker)
  protected
    FLocker: TCriticalSection;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Lock; stdcall;
    procedure Unlock; stdcall;
  end;

var
  MapHandle: THandle = 0;
  OwnerInstance: THandle;
  _PluginsManager: IQPluginsManager = nil;
  PluginsManagerNameSpace: QStringW;
  _MgrReplaceNotify: IQNotify = nil;
  _ActiveLoader: IQLoader = nil;
  GlobalLocker: IQLocker;

{$IFDEF POSIX}

function GetCurrentProcessId: Cardinal;
begin
  Result := getpid;
end;
{$ENDIF}

procedure Lock; inline;
begin
  GlobalLocker.Lock;
end;

procedure Unlock; inline;
begin
  GlobalLocker.Unlock;
end;

{$IFDEF MSWINDOWS}

procedure RegisterManager;
var
  P: Pointer;
begin
  _PluginsManager := TQPluginsManager.Create as IQPluginsManager;
  OwnerInstance := _PluginsManager.GetOwnerInstance;
  _PluginsManager._Release; // �ͷŹ��캯������Ϊ���ӵļ���
  MapHandle := CreateFileMappingW(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0,
    SizeOf(Pointer), PWideChar(PluginsManagerNameSpace));
  if MapHandle = 0 then
    RaiseLastOSError(GetLastError);
  P := MapViewOfFile(MapHandle, FILE_MAP_WRITE, 0, 0, 0);
  PPointer(P)^ := Pointer(_PluginsManager);
  UnmapViewOfFile(P);
  StringService := TQStringService.Create(IQStringService, 'NewString');
  _PluginsManager.Services.Add(StringService as IQService);
end;

procedure UnregisterManager;
begin
  if _PluginsManager <> nil then
  begin
    if _MgrReplaceNotify <> nil then
    begin
      (_PluginsManager as IQNotifyManager).Unsubscribe(NID_MANAGER_REPLACED,
        _MgrReplaceNotify);
      _MgrReplaceNotify := nil;
    end;
    if HInstance <> OwnerInstance then
      _PluginsManager.ModuleUnloading(HInstance)
    else
      _PluginsManager.Clear;
    _PluginsManager := nil;
    StringService := nil;
    if MapHandle <> 0 then
    begin
      CloseHandle(MapHandle);
      MapHandle := 0;
    end;
  end;
end;
{$ELSE}

procedure RegisterManager;
var
  AVal: Pointer;
begin
  OwnerInstance := HInstance;
  _PluginsManager := TQPluginsManager.Create;
  MapHandle := FileCreate(PluginsManagerNameSpace, fmOpenWrite,
    fmShareDenyWrite);
  if MapHandle <> THandle(-1) then
  begin
    AVal := Pointer(_PluginsManager);
    FileWrite(MapHandle, AVal^, SizeOf(AVal));
  end;
  StringService := TQStringService.Create(IQStringService, 'NewString');
  _PluginsManager.Services.Add(StringService as IQService);
end;

procedure UnregisterManager;
begin
  if MapHandle <> THandle(-1) then
  begin
    FileClose(MapHandle);
    DeleteFile(PluginsManagerNameSpace);
    MapHandle := THandle(-1);
    if HInstance = MainInstance then
      _PluginsManager.Clear;
    _PluginsManager := nil;
    StringService := nil;
  end;
end;
{$ENDIF}

function PluginsManager: IQPluginsManager;
{$IFDEF MSWINDOWS}
  procedure FindManager;
  var
    AHandle: THandle;
    P: Pointer;
  begin
    AHandle := OpenFileMappingW(FILE_MAP_READ, false,
      PWideChar(PluginsManagerNameSpace));
    if AHandle = 0 then // �����ڣ��Լ����׸�������
    begin
      RegisterManager;
      Result := _PluginsManager;
    end
    else
    begin
      P := MapViewOfFile(AHandle, FILE_MAP_READ, 0, 0, 0);
      _PluginsManager := IQPluginsManager(PPointer(P)^);
      UnmapViewOfFile(P);
      { Close the file mapping }
      CloseHandle(AHandle);
      OwnerInstance := _PluginsManager.GetOwnerInstance;
    end;
  end;
{$ELSE}
  procedure FindManager;
  var
    AHandle: THandle;
    P: Pointer;
  begin
    AHandle := FileOpen(PluginsManagerNameSpace, fmOpenRead or fmShareDenyNone);
    if AHandle <> INVALID_HANDLE_VALUE then
    begin
      FileRead(AHandle, P^, SizeOf(Pointer));
      FileClose(AHandle);
      _PluginsManager := IQPluginsManager(P);
    end
    else
    begin
      RegisterManager;
    end;
  end;
{$ENDIF}

begin
  if not Assigned(_PluginsManager) then
  begin
    FindManager;
    StringService := _PluginsManager as IQStringService;
    GlobalLocker := _PluginsManager as IQLocker;
    if Assigned(_PluginsManager) then
    begin
      _MgrReplaceNotify := TQManagerChangeHandler.Create;
      (_PluginsManager as IQNotifyManager).Subscribe(NID_MANAGER_REPLACED,
        _MgrReplaceNotify)
    end;
  end;
  Result := _PluginsManager;
end;

function ServiceSource(AService: IQService): QStringW;
var
  ALoader: IQLoader;
begin
  ALoader := AService.Loader;
  SetLength(Result, MAX_PATH);
  if not Assigned(ALoader) then
  begin
    if not Supports(AService, IQLoader, ALoader) then // ������������Loader
    begin
      SetLength(Result,
{$IFDEF UNICODE}GetModuleFileName{$ELSE}GetModuleFileNameW{$ENDIF}(MainInstance,
        PQCharW(Result), MAX_PATH));
      Exit;
    end;
  end;
  SetLength(Result, ALoader.GetServiceSource(AService, PWideChar(Result),
    MAX_PATH));
end;
{ TQService }

procedure TQService.AddExtension(AInterface: IInterface);
var
  AItem: PQServiceExtension;
begin
  if Assigned(AInterface) then
  begin
    New(AItem);
    AItem.Instance := AInterface;
    AItem.Next := nil;
    if Assigned(FLastExt) then
      FLastExt.Next := AItem
    else
      FFirstExt := AItem;
    FLastExt := AItem;
  end;
end;

procedure TQService.ClearExts;
var
  AItem, ANext: PQServiceExtension;
begin
  AItem := FFirstExt;
  while Assigned(AItem) do
  begin
    ANext := AItem.Next;
    Dispose(AItem);
    AItem := ANext;
  end;
  FFirstExt := nil;
  FLastExt := nil;
end;

constructor TQService.Create(const AId: TGuid; AName: QStringW);
begin
  inherited Create;
  FId := AId;
  FName := AName;
  FLoader := Pointer(_ActiveLoader);
end;

destructor TQService.Destroy;
begin
  FParent := nil;
  ClearExts;
  inherited;
end;

function TQService.Execute(AParams, AResult: IQParams): Boolean;
begin
  Result := True;
end;

function TQService.GetAttrs: IQParams;
begin
  if not Assigned(FAttrs) then
    FAttrs := TQParams.Create;
  Result := FAttrs;
end;

function TQService.GetDParent: TQServices;
begin
  Result := InstanceOf(IInterface(FParent)) as TQServices;
end;

function TQService.GetOriginObject: Pointer;
begin
  Result := Self;
end;

function TQService.GetOwnerInstance: THandle;
begin
  Result := HInstance;
end;

function TQService.GetId: TGuid;
begin
  Result := FId;
end;

function TQService.GetLastErrorCode: Cardinal;
begin
  Result := FErrorCode;
end;

function TQService.GetLastErrorMsg: PWideChar;
begin
  Result := PQCharW(FErrorMsg);
end;

function TQService.GetLoader: IQLoader;
begin
  Result := IQLoader(FLoader);
end;

function TQService.GetName: PWideChar;
begin
  Result := PQCharW(FName);
end;

function TQService.GetParent: IQServices;
begin
  Result := IQServices(FParent);
end;

function TQService.GetPath: QStringW;
var
  AParent: IQServices;
begin
  AParent := IQServices(FParent);
  Result := FName;
  while AParent <> nil do
  begin
    Result := QStringW(AParent.Name) + PathDelimiter^ + Result;
    AParent := AParent.Parent;
  end;
end;

function TQService.GetServiceAttrs: TQParams;
begin
  Result := InstanceOf(GetAttrs) as TQParams;
end;

function TQService.IsInModule(AModule: THandle): Boolean;
begin
  Result := HInstance = AModule;
end;

function TQService.QueryInterface(const IID: TGuid; out Obj): HRESULT;
  function QueryExt: HRESULT;
  var
    AItem: PQServiceExtension;
  begin
    Result := E_NOINTERFACE;
    AItem := FFirstExt;
    while Assigned(AItem) do
    begin
      Result := AItem.Instance.QueryInterface(IID, Obj);
      if Result = S_OK then
        break;
      AItem := AItem.Next;
    end;
  end;

begin
  Result := inherited QueryInterface(IID, Obj);
  if Result = E_NOINTERFACE then
    Result := QueryExt;
end;

function TQService.GetInstance: IQService;
begin
  Result := Self;
end;

function TQService.GetInstanceCreator: IQService;
begin
  if not Supports(TObject(FCreator), IQService, Result) then
    Result := nil;
end;

procedure TQService.RemoveExtension(AInterface: IInterface);
var
  APrior, AItem, ANext: PQServiceExtension;
begin
  AItem := FFirstExt;
  APrior := nil;
  while Assigned(AItem) do
  begin
    if AItem.Instance = AInterface then
    begin
      ANext := AItem.Next;
      if Assigned(APrior) then
        APrior.Next := ANext
      else
        FFirstExt := ANext;
      Dispose(AItem);
      AItem := ANext;
    end
    else
    begin
      APrior := AItem;
      AItem := AItem.Next;
    end;
  end;
  if FFirstExt = nil then
    FLastExt := nil;
end;

function TQService.Resume(AParams: IQParams): Boolean;
begin
  Result := True;
end;

procedure TQService.SetLastError(ACode: Cardinal; AMsg: QStringW);
begin
  FErrorCode := ACode;
  FErrorMsg := AMsg;
end;

procedure TQService.SetParent(AParent: IQServices);
begin
  FParent := Pointer(AParent);
end;

function TQService.Suspended(AParams: IQParams): Boolean;
begin
  Result := True;
end;

procedure TQService.ValidName(const S: QStringW);
begin
  if ContainsCharW(S,PathDelimiter) then
    raise QException.Create(SInvalidName);
end;

{ TQServices }

function TQServices.Add(AItem: IQService): Integer;
begin
  AItem._AddRef;
  AItem.Parent := Self;
  Lock;
  try
    Result := FItems.Add(Pointer(AItem));
  finally
    Unlock;
  end;
end;

function TQServices.ById(const AId: TGuid): IQService;
var
  I: Integer;
  AParent: IQServices;
  AService: IQService;
begin
  Result := nil;
  Lock;
  try
    for I := 0 to FItems.Count - 1 do
    begin
      AService := IQService(FItems[I]);
      if SameId(AService.GetId, AId) or
        (AService.QueryInterface(AId, Result) = S_OK) then
      begin
        Result := AService;
        break;
      end
      else if Supports(AService, IQServices, AParent) then
      begin
        Result := AParent.ById(AId);
        if Assigned(Result) then
          break;
      end;
    end;
  finally
    Unlock;
  end;
  if Assigned(Result) then
    Result := Result.GetInstance;
end;

function FindService(AParent: IQServices; APath: PWideChar): IQService;
var
  I: Integer;
  AName: QStringW;
  AMgr: IQPluginsManager;
  AFound: Boolean;
begin
  if Assigned(APath) then
  begin
    AMgr := PluginsManager;
    if CharInW(APath,PathDelimiter) then
    begin
      AParent := AMgr;
      Inc(APath);
    end
    else if AParent = nil then
      AParent := AMgr;
    if not Supports(AParent, IQService, Result) then
      Result := nil;
    AFound := True;
    Lock;
    try
      while (APath^ <> #0) and (AParent <> nil) and AFound do
      begin
        AName := DecodeTokenW(APath, PathDelimiter, NullChar, True);
        if Length(AName) > 0 then
        begin
          AFound := false;
          for I := 0 to AParent.Count - 1 do
          begin
            Result := AParent[I];
            if StrCmpW(Result.Name, PWideChar(AName), True) = 0 then
            begin
              AFound := True;
              if not Supports(Result, IQServices, AParent) then
                AParent := nil;
              break;
            end;
          end;
        end;
      end;
      if (APath^ <> #0) or (not AFound) then
        Result := nil;
    finally
      Unlock;
    end;
  end
  else
    Result := nil;
end;

function FindService(APath: PWideChar): IQService;
begin
  Result := FindService(PluginsManager, APath);
end;

function FindService(APath: PWideChar; const AId: TGuid; out AService): Boolean;
begin
  Result := Supports(FindService(APath), AId, AService);
end;

function GetService(APath: PWideChar): IQService;
begin
  Result := PluginsManager.ByPath(APath);
end;

function GetService(AParent: IQServices; APath: PWideChar): IQService;
begin
  Result := AParent.ByPath(APath);
end;

function GetService(APath: PWideChar; const AId: TGuid; out AService): Boolean;
begin
  Result := Supports(GetService(APath), AId, AService);
end;

function ServiceLoader(AService: IInterface): IQLoader;
var
  AIntf: IQService;
begin
  if Supports(AService, IQService, AIntf) then
    Result := AIntf.Loader
  else
    Result := nil;
end;

function ServiceModule(AService: IInterface): HMODULE;
var
  AIntf: IQService;
begin
  if Supports(AService, IQService, AIntf) then
    Result := AIntf.GetOwnerInstance
  else
    Result := 0;
end;

function ServicePath(AService: IQService;APathDelimiter:QCharW): QStringW;
var
  AParent, ARoot: IQServices;
begin
  ARoot := PluginsManager as IQServices;
  if Assigned(AService.Creator) then
    AService := AService.Creator;
  AParent := AService.Parent;
  if AParent <> ARoot then
  begin
    Result := AService.Name;
    Lock;
    try
      while AParent <> ARoot do
      begin
        Result := QStringW(AParent.Name) + APathDelimiter + Result;
        AParent := AParent.Parent;
      end;
      Result := APathDelimiter + Result;
    finally
      Unlock;
    end;
  end
  else
    SetLength(Result, 0);
end;

function HoldByComponent(AOwner: TComponent; AInterface: IInterface)
  : TComponent;
begin
  Result := TQInterfaceHolder.Create(AOwner, AInterface);
end;

function InstanceLoader(AInstance: HMODULE): IQLoader;
var
  I, J, C: Integer;
begin
  Lock;
  try
    for I := 0 to PluginsManager.Loaders.Count - 1 do
    begin
      if Supports(PluginsManager.Loaders[I], IQLoader, Result) then
      begin
        C := Result.GetModuleCount;
        for J := 0 to C - 1 do
        begin
          if Result.GetModules(J) = AInstance then
            Exit;
        end;
      end;
    end;
  finally
    Unlock;
  end;
  Result := nil;
end;

function UnloadServices(AInstance: HMODULE; AWaitDone: Boolean): Boolean;
var
  ALoader: IQLoader;
begin
  ALoader := InstanceLoader(AInstance);
  if Assigned(ALoader) then
    Result := ALoader.UnloadServices(AInstance, AWaitDone)
  else
    Result := false;
end;

function TQServices.ByPath(APath: PWideChar): IQService;
begin
  if (APath <> nil) then
  begin
    if APath^ = PathDelimiter^ then
    begin
      Inc(APath);
      Result := FindService(PluginsManager, APath);
    end
    else
      Result := FindService(Self, APath);
    if Assigned(Result) then
      Result := Result.GetInstance;
  end
  else
    Result := GetInstance;
end;

procedure TQServices.Clear;
var
  I: Integer;
begin
  Lock;
  try
    for I := 0 to FItems.Count - 1 do
      IQService(FItems[I])._Release;
    FItems.Clear;
  finally
    Unlock;
  end;
end;

constructor TQServices.Create(const AId: TGuid; AName: QStringW);
begin
  inherited;
  FItems := TQPointerList.Create;
end;

procedure TQServices.Delete(AIndex: Integer);
begin
  Lock;
  try
    IQService(FItems[AIndex])._Release;
    FItems.Delete(AIndex);
  finally
    Unlock;
  end;
end;

destructor TQServices.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited;
end;

function TQServices.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQServices.GetItems(AIndex: Integer): IQService;
begin
  Result := IQService(FItems[AIndex]);
end;

function TQServices.IndexOf(AItem: IQService): Integer;
begin
  Result := FItems.IndexOf(Pointer(AItem));
end;

function TQServices.MoveTo(AIndex, ANewIndex: Integer): Boolean;
begin
  Lock;
  try
    Result := (AIndex >= 0) and (AIndex < FItems.Count);
    if Result then
    begin
      if ANewIndex < 0 then
        ANewIndex := 0;
      if ANewIndex >= FItems.Count then
        ANewIndex := FItems.Count - 1;
      if AIndex <> ANewIndex then
        FItems.Move(AIndex, ANewIndex)
      else
        Result := false
    end;
  finally
    Unlock;
  end;
end;

function TQServices.QueryInterface(const IID: TGuid; out Obj): HRESULT;
var
  AService: IQService;
begin
  Result := inherited QueryInterface(IID, Obj);
  if Result = E_NOINTERFACE then
  begin
    AService := ById(IID);
    if Assigned(AService) then
      Result := AService.QueryInterface(IID, Obj)
    else
      Result := E_NOINTERFACE;
  end;
end;

procedure TQServices.Remove(AItem: IQService);
begin
  Lock;
  try
    if FItems.IndexOf(Pointer(AItem)) <> -1 then
    begin
      AItem._Release;
      FItems.Remove(Pointer(AItem));
    end;
  finally
    Unlock;
  end;
end;

{ TQPluginsManager }

procedure TQPluginsManager.AsynCall(AProc: TQAsynProc; AParams: IQParams);
begin
  qdac_postqueue.AsynCall(AProc, AParams);
end;

function TQPluginsManager.ById(const AId: TGuid): IQService;
var
  I: Integer;
  AServices: IQServices;
begin
  Result := nil;
  // ����ʹ��·����·�ɵĽ��
  Lock;
  try
    for I := 0 to FRouters.Count - 1 do
    begin
      if Supports(FRouters[I], IQServices, AServices) then
      begin
        Result := AServices.ById(AId);
        if Assigned(Result) then
          break;
      end;
    end;
  finally
    Unlock;
  end;
  if Result = nil then
    Result := inherited ById(AId);
end;

function TQPluginsManager.ByPath(APath: PWideChar): IQService;
var
  I: Integer;
  AServices: IQServices;
begin
  Result := nil;
  Lock;
  try
    for I := 0 to FRouters.Count - 1 do
    begin
      if Supports(FRouters[I], IQServices, AServices) then
      begin
        Result := AServices.ByPath(APath);
        if Assigned(Result) then
          break;
      end;
    end;
  finally
    Unlock;
  end;
  if Result = nil then
    Result := inherited ByPath(APath);
end;

procedure TQPluginsManager.ModuleUnloading(AInstance: HINST);
  procedure Unregister(AParent: IQServices);
  var
    I: Integer;
    AList: IQServices;
    AService: IQService;
    AServiceInstance: THandle;
  begin
    I := 0;
    while I < AParent.Count do
    begin
      AService := AParent[I];
      AServiceInstance := AService.GetOwnerInstance;
      // OutputDebugString(PChar('Service ' + AService.Name + '.OwnerInstance=' +
      // IntToHex(AServiceInstance, 8)));
      if AInstance = AServiceInstance then
      begin
        // OutputDebugString(PChar(String('Delete Service ') + AService.Name));
        if Supports(AService, IQServices, AList) then
          AList.Clear;
        AParent.Delete(I);
      end
      else
      begin
        if Supports(AService, IQServices, AList) then
          Unregister(AList);
        Inc(I);
      end;
    end;
  end;
  procedure RemoveWaitings;
  var
    APrior, AItem, ANext: PServiceWaitItem;
  begin
    if Assigned(FWaitingServices) then
    begin
      APrior := nil;
      AItem := FWaitingServices;
      while Assigned(AItem) do
      begin
        if FindHInstance(AItem.Method.Code) = AInstance then
        begin
          ANext := AItem.Next;
          if Assigned(APrior) then
            APrior.Next := ANext
          else
            FWaitingServices := ANext;
          Dispose(AItem);
          AItem := ANext;
        end
        else
        begin
          APrior := AItem;
          AItem := AItem.Next;
        end;
      end;
    end;
  end;

begin
  // OutputDebugString(PChar('Clear module HInstance=' + IntToHex(AInstance,
  // 8) + ' ''s Services.'));
  Unregister(Self);
end;

constructor TQPluginsManager.Create;
begin
  inherited Create(IQPluginsManager, 'Manager');
  GlobalLocker := TQLocker.Create;
  _AddRef; // ���������֤����ĵ��ò����ͷ�����
  FNotifyMgr := TQNotifyManager.Create;
  FServices := TQServices.Create
    (StringToGuid('{EB72B93B-66BF-40C6-A412-6301DE149FC1}'), 'Services');
  Add(FServices as IQService);
  FRouters := TQServices.Create
    (StringToGuid('{C0E2C566-D5F0-4FD3-8BE6-4FFF042C0023}'), 'Routers');
  Add(FRouters as IQService);
  FLoaders := TQServices.Create
    (StringToGuid('{0BBAEE7C-ECD0-4CFA-A968-34BF071623DE}'), 'Loaders');
  Add(FLoaders as IQService);
end;

destructor TQPluginsManager.Destroy;
begin
  FRouters := nil;
  FServices := nil;
  FLoaders := nil;
  FActiveLoader := nil;
  FNotifyMgr.Clear;
  FNotifyMgr := nil;
  inherited;
end;

function TQPluginsManager.DoLoaderAction(AStartAction, AStopAction: BYTE;
  ARevert: Boolean): Boolean;
var
  I: Integer;
  AParams, AResult, AError, AProgress: IQParams;
  APath: QStringW;
  ALoaders: IQServices;
begin
  Result := True;
  ALoaders := Loaders;
  if ALoaders.Count > 0 then
  begin
    FNotifyMgr.Send(AStartAction, nil);
    AParams := TQParams.Create;
    AParams.Add('Sender', ptUnicodeString).AsString := NewString(GetName);
    AParams.Add('Action', ptUInt8).AsInteger := AStartAction;
    AResult := TQParams.Create;
    AProgress := TQParams.Create;
    AProgress.Add('Action', ptUInt8).AsInteger := AStartAction;
    AProgress.Add('Index', ptInt32);
    AProgress.Add('Count', ptInt32);
    AProgress.Add('Name', ptUnicodeString);
    if ARevert then
      I := ALoaders.Count - 1
    else
      I := 0;
    try
      repeat
        if Supports(ALoaders[I], IQLoader, FActiveLoader) then
        begin
          AProgress[1].AsInteger := I;
          AProgress[2].AsInteger := ALoaders.Count;
          FNotifyMgr.Send(NID_LOADERS_PROGRESS, AProgress);
          if not FActiveLoader.Execute(AParams, AResult) then
          begin
            AError := TQParams.Create;
            AError.Add('Sender', ptUnicodeString).AsString := NewString(APath);
            AError.Add('Action', ptUInt8).AsInteger := AStartAction;
            AError.Add('ErrorCode', ptUInt32).AsInt64 :=
              FActiveLoader.LastError;
            AError.Add('ErrorMsg', ptUnicodeString).AsString :=
              NewString(FActiveLoader.LastErrorMsg);
            FNotifyMgr.Send(NID_LOADER_ERROR, AError);
            Result := false;
          end;
        end;
        if ARevert then
        begin
          Dec(I);
          // ����������������صĲ���ṩ���Ǽ���������ʱ��ж�ؿ��ܻ�ж�ض��������������Ҫ���
          if I >= ALoaders.Count then
            I := ALoaders.Count - 1;
          if I < 0 then
            break;
        end
        else
        begin
          Inc(I);
          if I = ALoaders.Count then
            break;
        end;
      until 1 > 2;
    finally
      FActiveLoader := nil;
      // ���ͼ������֪ͨ
      FNotifyMgr.Send(AStopAction, nil);
    end;
  end;
end;

function PathRoot(var P: PWideChar): IQServices;
var
  AName: QStringW;
  I: Integer;
begin
  if CharInW(P,PathDelimiter) then
    Inc(P);
  Result := nil;
  AName := DecodeTokenW(P, PathDelimiter, NullChar, True);
  Lock;
  try
    for I := 0 to _PluginsManager.Count - 1 do
    begin
      if StrCmpW(_PluginsManager[I].Name, PWideChar(AName), True) = 0 then
      begin
        if Supports(_PluginsManager[I], IQServices, Result) then
          break;
      end;
    end;
  finally
    Unlock;
  end;
end;

function TQPluginsManager.ForcePath(APath: PWideChar): IQServices;
var
  P: PWideChar;
  AName: QStringW;
  AService: IQService;
  AParent: TQServices;
  I: Integer;
  AFound: Boolean;
begin
  P := PQCharW(APath);
  Result := Self;
  Lock;
  try
    while P^ <> #0 do
    begin
      AName := DecodeTokenW(P, PathDelimiter, NullChar, True);
      if Length(AName) > 0 then
      begin
        AFound := false;
        for I := 0 to Result.Count - 1 do
        begin
          AService := Result[I];
          if StrCmpW(AService.Name, PWideChar(AName), True) = 0 then
          begin
            if Supports(AService, IQServices, Result) then
            begin
              AFound := True;
              break
            end
            else
              raise QException.CreateFmt(SMismatchServicePath, [APath]);
          end;
        end;
        if not AFound then
        begin
          AParent := TQServices.Create(NewId, AName);
          Result.Add(AParent);
          Result := AParent;
        end;
      end;
    end;
  finally
    Unlock;
  end;
end;

function TQPluginsManager.GetActiveLoader: IQLoader;
begin
  Result := FActiveLoader;
end;

function TQPluginsManager.GetLoaders: IQServices;
begin
  Result := FLoaders;
end;

function TQPluginsManager.GetRouters: IQServices;
begin
  Result := FRouters;
end;

function TQPluginsManager.GetServices: IQServices;
begin
  Result := FServices;
end;

procedure TQPluginsManager.Notify(const AId: Cardinal; AParams: IQParams;
  var AFireNext: Boolean);
begin
  if AId = NID_MANAGER_FREE then
  begin
    ModuleUnloading(HInstance);
    _PluginsManager := nil;
  end;
end;

function TQPluginsManager.PathOf(AService: IQService): QStringW;
var
  AParent: IQServices;
begin
  Result := AService.Name;
  AParent := AService.Parent;
  while Assigned(AParent) do
  begin
    Result := QStringW(AParent.Name) + PathDelimiter^ + Result;
    AParent := AParent.Parent;
  end;
end;

procedure TQPluginsManager.ProcessQueuedCalls;
begin

end;

function TQPluginsManager.QueryInterface(const IID: TGuid; out Obj): HRESULT;
begin
  // ������ʵ�ֶ�IQNotifyManager�ӿڵĲ�ѯ
  if SameId(IID, IQNotifyManager) then
    Result := FNotifyMgr.QueryInterface(IID, Obj)
  else if SameId(IID, IQLocker) then
    Result := GlobalLocker.QueryInterface(IID, Obj)
  else
    Result := inherited QueryInterface(IID, Obj);
end;

procedure TQPluginsManager.RemoveServiceWait(ANotify: TQServiceCallback);
begin
  RemoveServiceWait(nil, ANotify);
end;

procedure TQPluginsManager.RemoveServiceWait(const AService: PQCharW;
  ANotify: TQServiceCallback);
var
  APrior, ANext, AItem, AFirst: PServiceWaitItem;
  ASvcPath: QStringW;
  ANotifyAddr: TMethod absolute ANotify;
begin
  ASvcPath := AService;
  APrior := nil;
  AFirst := nil;
  Lock;
  try
    AItem := FWaitingServices;
    while Assigned(AItem) do
    begin
      if (AItem.Method.Code = ANotifyAddr.Code) and
        ((not Assigned(AService)) or (AItem.Path = ASvcPath)) then
      begin
        ANext := AItem.Next;
        if Assigned(APrior) then
          APrior.Next := ANext
        else
          FWaitingServices := ANext;
        AItem.Next := AFirst;
        AFirst := AItem;
      end
      else
      begin
        APrior := AItem;
        AItem := AItem.Next;
      end;
    end;
  finally
    Unlock;
  end;
  while Assigned(AFirst) do
  begin
    ANext := AFirst.Next;
    Dispose(AFirst);
    AFirst := ANext;
  end;
end;

procedure TQPluginsManager.RemoveServiceWait(const AId: TGuid;
  ANotify: TQServiceCallback);
var
  APrior, ANext, AItem, AFirst: PServiceWaitItem;
  ANotifyAddr: TMethod absolute ANotify;
begin
  APrior := nil;
  AFirst := nil;
  Lock;
  try
    AItem := FWaitingServices;
    while Assigned(AItem) do
    begin
      if (AItem.Method.Code = ANotifyAddr.Code) and SameId(AId, AItem.Id) then
      begin
        ANext := AItem.Next;
        if Assigned(APrior) then
          APrior.Next := ANext
        else
          FWaitingServices := ANext;
        AItem.Next := AFirst;
        AFirst := AItem;
      end
      else
      begin
        APrior := AItem;
        AItem := AItem.Next;
      end;
    end;
  finally
    Unlock;
  end;
  while Assigned(AFirst) do
  begin
    ANext := AFirst.Next;
    Dispose(AFirst);
    AFirst := ANext;
  end;
end;

function TQPluginsManager.Replace(ANewManager: IQPluginsManager): Boolean;
var
  AParams: TQParams;
begin
  // �滻ʱ�㲥һ��֪ͨ�����еĲ�������������������������
  AParams := TQParams.Create;
  AParams.Add('Old', ptInt64).AsInt64 := IntPtr(Pointer(_PluginsManager));
  AParams.Add('New', ptInt64).AsInt64 := IntPtr(Pointer(ANewManager));
  FNotifyMgr.Send(NID_MANAGER_REPLACED, AParams);
  _PluginsManager := ANewManager;
  Result := True;
end;

procedure TQPluginsManager.ServiceReady(AService: IQService);
var
  AFirst, APrior, AItem, ANext: PServiceWaitItem;
begin
  AFirst := nil;
  Lock;
  try
    AItem := FWaitingServices;
    APrior := nil;
    while Assigned(AItem) do
    begin
      ANext := AItem.Next;
      if ((Length(AItem.Path) > 0) and (AItem.Path = ServicePath(AService))) or
        SameId(AService.GetId, AItem.Id) then
      begin
        if Assigned(APrior) then
          APrior.Next := ANext
        else
          FWaitingServices := ANext;
        if Assigned(AFirst) then
          AItem.Next := AFirst;
        AFirst := AItem;
      end
      else
        APrior := AItem;
      AItem := ANext;
    end;
  finally
    Unlock;
  end;
  while Assigned(AFirst) do
  begin
    ANext := AFirst.Next;
    if Assigned(AFirst.OnReady) then
      AFirst.OnReady(AService);
    Dispose(AFirst);
    AFirst := ANext;
  end;
end;

procedure TQPluginsManager.SetActiveLoader(ALoader: IQLoader);
begin
  FActiveLoader := ALoader;
end;

procedure TQPluginsManager.Start;
begin
  DoLoaderAction(NID_LOADERS_STARTING, NID_LOADERS_STARTED, false);
end;

function TQPluginsManager.Stop: Boolean;
begin
  Result := DoLoaderAction(NID_LOADERS_STOPPING, NID_LOADERS_STOPPED, True);
end;

function TQPluginsManager.WaitService(const AService: PQCharW;
  ANotify: TQServiceCallback): Boolean;
var
  AItem: PServiceWaitItem;
begin
  if Assigned(AService) and (AService^ <> #0) then
  begin
    New(AItem);
    AItem.Path := AService;
    AItem.OnReady := ANotify;
    Lock;
    try
      AItem.Next := FWaitingServices;
      FWaitingServices := AItem;
    finally
      Unlock;
    end;
    Result := True;
  end
  else
    Result := false;
end;

function TQPluginsManager.WaitService(const AId: TGuid;
  ANotify: TQServiceCallback): Boolean;
var
  AItem: PServiceWaitItem;
begin
  New(AItem);
  AItem.Id := AId;
  AItem.OnReady := ANotify;
  Lock;
  try
    AItem.Next := FWaitingServices;
    FWaitingServices := AItem;
  finally
    Unlock;
  end;
  Result := True;
end;

function TQPluginsManager._AddRef: Integer;
begin
  Result := inherited _AddRef;
end;

function TQPluginsManager._Release: Integer;
begin
  Result := inherited _Release;
end;

{ TQNotifyManager }

procedure TQNotifyManager.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    FreeObject(TQNotifyItem(FItems[I]));
  FItems.Clear;
end;

constructor TQNotifyManager.Create;
begin
  inherited Create;
  FItems := TQPointerList.Create;
  FItems.Add(TQNotifyItem.Create(Self, NID_MANAGER_REPLACED,
    'Manager.Replaced'));
  FItems.Add(TQNotifyItem.Create(Self, NID_MANAGER_FREE, 'Manager.Free'));
  FItems.Add(TQNotifyItem.Create(Self, NID_LOADERS_STARTING,
    'Manager.Loaders.Starting'));
  FItems.Add(TQNotifyItem.Create(Self, NID_LOADERS_STARTED,
    'Manager.Loaders.Started'));
  FItems.Add(TQNotifyItem.Create(Self, NID_LOADERS_STOPPING,
    'Manager.Loaders.Stopping'));
  FItems.Add(TQNotifyItem.Create(Self, NID_LOADERS_STOPPED,
    'Manager.Loaders.Stopped'));
  FItems.Add(TQNotifyItem.Create(Self, NID_LOADERS_PROGRESS,
    'Manager.Loaders.OnProgress'));
  FItems.Add(TQNotifyItem.Create(Self, NID_LOADER_ERROR,
    'Manager.Loaders.OnError'));
  FItems.Add(TQNotifyItem.Create(Self, NID_PLUGIN_LOADING,
    'Manager.Plugin.Loading'));
  FItems.Add(TQNotifyItem.Create(Self, NID_PLUGIN_LOADED,
    'Manager.Plugin.Loaded'));
  FItems.Add(TQNotifyItem.Create(Self, NID_PLUGIN_UNLOADING,
    'Manager.Plugin.Unloading'));
  FItems.Add(TQNotifyItem.Create(Self, NID_PLUGIN_UNLOADED,
    'Manager.Plugin.Unloaded'));
  FBeforeProcessNotify := TQNotifyItem.Create(Self, NID_NOTIFY_PROCESSING,
    'Manager.NotifyManager.Processing');
  FAfterProcessNotify := TQNotifyItem.Create(Self, NID_NOTIFY_PROCESSED,
    'Manager.NotifyManager.Processed');
  FItems.Add(FBeforeProcessNotify);
  FItems.Add(FAfterProcessNotify);
  FItems.Add(TQNotifyItem.Create(Self, NID_SERVICE_READY, 'Services.Ready'));
  FNextId := FItems.Count;
end;

destructor TQNotifyManager.Destroy;
begin
  Clear;
  FreeObject(FItems);
  inherited;
end;

procedure TQNotifyManager.DoNotify(AId: Cardinal; AParams: IQParams);
var
  I: Integer;
  AItem: TQNotifyItem;
  AItems: array of IQNotify;
  AFireNext: Boolean;
  AFireProcessNotify: Boolean;
  AProcessParams: IQParams;
begin
  Lock;
  try
    if AId < Cardinal(FItems.Count) then
    begin
      AItem := FItems[AId];
      SetLength(AItems, AItem.Count);
      for I := 0 to AItem.Count - 1 do
        AItems[I] := IQNotify(AItem.FItems[I]);
    end
    else
      SetLength(AItems, 0);
  finally
    Unlock;
  end;
  AFireProcessNotify := (AId <> NID_NOTIFY_PROCESSING) and
    (AId <> NID_NOTIFY_PROCESSED);
  if AFireProcessNotify then
  begin
    AProcessParams := TQParams.Create;
    AProcessParams.Add('Id', ptUInt32).AsInt64 := AId;
    AProcessParams.Add('Params', ptInterface).AsInterface := AParams;
    DoNotify(NID_NOTIFY_PROCESSING, AProcessParams);
  end;
  try
    AFireNext := True;
    for I := 0 to High(AItems) do
    begin
      AItems[I].Notify(AId, AParams, AFireNext);
      if not AFireNext then
        break;
    end;
  finally
    if AFireProcessNotify then
      DoNotify(NID_NOTIFY_PROCESSED, AProcessParams);
  end;
end;

function TQNotifyManager.EnumSubscribe(ANotifyId: Cardinal;
  ACallback: TQSubscribeEnumCallback; AParam: Int64): Integer;
var
  I: Integer;
  AItem: TQNotifyItem;
  AItems: array of IQNotify;
  AFireNext: Boolean;
begin
  Lock;
  try
    if ANotifyId < Cardinal(FItems.Count) then
    begin
      AItem := FItems[ANotifyId];
      SetLength(AItems, AItem.Count);
      for I := 0 to AItem.Count - 1 do
        AItems[I] := IQNotify(AItem.FItems[I]);
    end
    else
      SetLength(AItems, 0);
  finally
    Unlock;
  end;
  Result := 0;
  AFireNext := True;
  for I := 0 to High(AItems) do
  begin
    ACallback(AItems[I], AParam, AFireNext);
    Inc(Result);
    if not AFireNext then
      break;
  end;
end;

function TQNotifyManager.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQNotifyManager.GetId(const AIndex: Integer): Cardinal;
begin
  Result := TQNotifyItem(FItems[AIndex]).Id;
end;

function TQNotifyManager.GetName(const AIndex: Integer): PWideChar;
begin
  Result := PWideChar(TQNotifyItem(FItems[AIndex]).Name);
end;

procedure TQNotifyManager.HandlePost(AParams: IInterface);
var
  ANotifyParams: IQParams;
  ALastParam: IQParam;
  ANotifyId: Cardinal;
  AEvent: TEvent;
begin
  ANotifyParams := AParams as IQParams;
  ALastParam := ANotifyParams[ANotifyParams.Count - 1];
  AEvent := nil;
  if StrCmpW(ALastParam.Name, '@NID', True) = 0 then
  begin
    ANotifyId := Cardinal(ALastParam.AsInteger);
    if ANotifyParams.Count > 2 then
    begin
      ALastParam := ANotifyParams[ANotifyParams.Count - 2];
      if StrCmpW(ALastParam.Name, '@NVT', True) = 0 then
      begin
        AEvent := Pointer(ALastParam.AsInt64);
        ANotifyParams.Delete(ANotifyParams.Count - 1);
      end;
    end;
    ANotifyParams.Delete(ANotifyParams.Count - 1);
    DoNotify(ANotifyId, ANotifyParams);
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

function TQNotifyManager.IdByName(const AName: PWideChar): Cardinal;
var
  I: Integer;
begin
  Result := Cardinal(-1);
  Lock;
  try
    for I := 0 to FItems.Count - 1 do
    begin
      if TQNotifyItem(FItems[I]).Name = AName then
      begin
        Result := TQNotifyItem(FItems[I]).Id;
        Exit;
      end;
    end;
    if Result = Cardinal(-1) then
    begin
      Result := FNextId;
      Inc(FNextId);
      FItems.Add(TQNotifyItem.Create(Self, Result, AName));
    end;
  finally
    Unlock;
  end;
end;

function TQNotifyManager.NameOfId(const AId: Cardinal): PWideChar;
begin
  Lock;
  try
    if AId > Cardinal(FItems.Count) then
      Result := nil
    else
      Result := PWideChar(TQNotifyItem(FItems[AId]).Name);
  finally
    Unlock;
  end;
end;

procedure TQNotifyManager.Post(AId: Cardinal; AParams: IQParams);
begin
  // ׷�����һ������Ϊ֪ͨ��ID
  AParams.Add('@NID', ptInt32).AsInteger := Integer(AId);
  AsynCall(HandlePost, AParams);
end;

procedure TQNotifyManager.Send(AId: Cardinal; AParams: IQParams);
var
  AEvent: TEvent;
begin
  if MainThreadId = GetCurrentThreadId then
    DoNotify(AId, AParams)
  else
  begin
    if not Assigned(AParams) then
      AParams := TQParams.Create;
    AEvent := TEvent.Create;
    try
      AParams.Add('@EVT', ptInt64).AsInt64 := IntPtr(AEvent);
      Post(AId, AParams);
      AEvent.WaitFor(INFINITE);
    finally
      FreeAndNil(AEvent);
    end;
  end;
end;

function TQNotifyManager.Subscribe(ANotifyId: Cardinal;
  AHandler: IQNotify): Boolean;
var
  AItem: TQNotifyItem;
begin
  Lock;
  try
    if ANotifyId <= Cardinal(FItems.Count) then
    begin
      AItem := FItems[ANotifyId];
      AItem.Add(AHandler);
      Result := True;
    end
    else
      Result := false;
  finally
    Unlock;
  end;
end;

procedure TQNotifyManager.Unsubscribe(ANotifyId: Cardinal; AHandler: IQNotify);
begin
  Lock;
  try
    if ANotifyId <= Cardinal(FItems.Count) then
      TQNotifyItem(FItems[ANotifyId]).Remove(AHandler);
  finally
    Unlock;
  end;
end;

{ TQNotifyItem }

function TQNotifyItem.Add(ANotify: IQNotify): Integer;
begin
  ANotify._AddRef;
  Result := FItems.Add(Pointer(ANotify));
end;

procedure TQNotifyItem.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    IQNotify(FItems[I])._Release;
  FItems.Clear;
end;

constructor TQNotifyItem.Create(AOwner: TQNotifyManager; AId: Cardinal;
  AName: QStringW);
begin
  inherited Create;
  FOwner := AOwner;
  FItems := TQPointerList.Create;
  FId := AId;
  FName := AName;
end;

destructor TQNotifyItem.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited;
end;

function TQNotifyItem.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQNotifyItem.GetItems(AIndex: Integer): IQNotify;
begin
  Result := IQNotify(FItems[AIndex]);
end;

procedure TQNotifyItem.Remove(ANotify: IQNotify);
var
  I: Integer;
begin
  I := FItems.IndexOf(Pointer(ANotify));
  if I <> -1 then
  begin
    FItems.Delete(I);
    ANotify._Release;
  end;
end;

{ TQManagerChangeHandler }

procedure TQManagerChangeHandler.Notify(const AId: Cardinal; AParams: IQParams;
  var AFireNext: Boolean);
var
  AOld: Pointer;
begin
  if AId = NID_MANAGER_REPLACED then // ���������滻ʱ���滻���ر�����ֵ
  begin
    // Param[0]=Old,Param[1]=New
    AOld := Pointer(_PluginsManager);
{$IFDEF WIN32}
    AtomicExchange(Integer(_PluginsManager), Integer(AParams[1].AsInt64));
{$ELSE}
    AtomicExchange(Pointer(_PluginsManager), Pointer(AParams[1].AsInt64));
{$ENDIF}
    _PluginsManager._AddRef;
    IQPluginsManager(AOld) := nil;
  end;
end;

{ TQBaseLoader }

procedure TQBaseLoader.AddModule(AFileName: QStringW; AHandle: THandle);
var
  AItem: PQLoadedModule;
begin
  New(AItem);
  AItem.FileName := AFileName;
  AItem.Handle := AHandle;
  FItems.Add(AItem);
end;

procedure TQBaseLoader.AsynUnload(AParams: IInterface);
var
  AInstParams: IQParams;
  AInst: HINST;
begin
  AInstParams := AParams as IQParams;
  AInst := AInstParams[0].AsInt64;
  UnloadServices(AInst);
end;

procedure TQBaseLoader.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    RemoveModule(FItems[I]);
  FItems.Clear;
end;

constructor TQBaseLoader.Create(const AId: TGuid; AName, APath, AExt: QStringW;
  AIncSubDir: Boolean);
begin
  inherited Create(AId, AName);
  FPath := APath;
  FFileExt := AExt;
  FIncludeSubDir := AIncSubDir;
  FItems := TQPointerList.Create;
end;

destructor TQBaseLoader.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited;
end;

function TQBaseLoader.Execute(AParams, AResult: IQParams): Boolean;
begin
  Result := True;
  case AParams.ByName('Action').AsInteger of
    NID_LOADERS_STARTING:
      Start;
    NID_LOADERS_STOPPING:
      Stop;
  end;
end;

function TQBaseLoader.FileByHandle(AHandle: THandle): String;
var
  I: Integer;
  ALoaded: PQLoadedModule;
begin
  SetLength(Result, 0);
  for I := 0 to FItems.Count - 1 do
  begin
    ALoaded := FItems[I];
    if ALoaded.Handle = AHandle then
    begin
      Result := ALoaded.FileName;
      Exit;
    end;
  end;
end;

function TQBaseLoader.GetLoader: IQLoader;
begin
  Result := Self;
end;

function TQBaseLoader.GetModuleCount: Integer;
begin
  Result := FItems.Count;
end;

function TQBaseLoader.GetModuleName(AIndex: Integer): PWideChar;
begin
  Result := PWideChar(PQLoadedModule(FItems[AIndex]).FileName);
end;

function TQBaseLoader.GetModules(AIndex: Integer): HMODULE;
begin
  Result := PQLoadedModule(FItems[AIndex]).Handle;
end;

function TQBaseLoader.GetModuleState(AInstance: HINST): TQModuleState;
var
  I: Integer;
begin
  Result := msUnknown;
  if AInstance = FLoadingModule then
    Result := msLoading
  else if AInstance = FUnloadingModule then
    Result := msUnloading
  else
  begin
    Lock;
    try
      for I := 0 to FItems.Count - 1 do
      begin
        if PQLoadedModule(FItems[I]).Handle = AInstance then
        begin
          Result := msLoaded;
          break;
        end;
      end;
    finally
      Unlock;
    end;
  end;
end;

function TQBaseLoader.GetServiceSource(AService: IQService; ABuf: PWideChar;
  ALen: Integer): Integer;
begin
  Result := 0;
end;

function TQBaseLoader.GetState: TQLoaderState;
begin
  Result := FState;
end;

function TQBaseLoader.GetVersion(var AVerInfo: TQVersion): Boolean;
begin
  Result := True;
  FillChar(AVerInfo, SizeOf(TQVersion), 0);
  AVerInfo.Version.Major := 3;
  AVerInfo.Version.Release := 1;
  strcpyW(AVerInfo.Name, PWideChar(Name));
  strcpyW(AVerInfo.Company, 'QDAC team');
  strcpyW(AVerInfo.Description, 'Default Plugins Loader');
{$IFDEF UNICODE}
  GetModuleFileName
{$ELSE}
  GetModuleFileNameW
{$ENDIF}(HInstance, AVerInfo.FileName, MAX_PATH)
end;

function TQBaseLoader.HandleByFile(AFileName: QStringW): THandle;
var
  I: Integer;
  ALoaded: PQLoadedModule;
begin
  Result := 0;
  for I := 0 to FItems.Count - 1 do
  begin
    ALoaded := FItems[I];
    if ALoaded.FileName = AFileName then
    begin
      Result := ALoaded.Handle;
      Exit;
    end;
  end;
end;

function TQBaseLoader.InternalLoadServices(const AFileName: PWideChar): THandle;
begin
  Result := 0;
end;

function TQBaseLoader.InternalLoadServices(const AStream: TStream): THandle;
var
  AFileStream: TFileStream;
  AFileName: QStringW;
  function GetTempFileName: QStringW;
  var
    ATempDir: QStringW;
    I: Cardinal;
  begin
    I := GetCurrentProcessId;
{$IFDEF MSWINDOWS}
    SetLength(ATempDir, MAX_PATH);
    SetLength(ATempDir, GetTempPathW(MAX_PATH, PWideChar(ATempDir)));
    SetLength(Result, MAX_PATH);
    windows.GetTempFileNameW(PWideChar(ATempDir), 'QP_', I, PWideChar(Result));
    AFileName := PWideChar(Result);
    Result := AFileName;
{$ELSE}
{$IFDEF ANDROID}
    ATempDir := '/data/local/tmp/';
{$ELSE}
    ATempDir := '/tmp/';
{$ENDIF}
    while FileExists(ATempDir + 'QP_' + IntToStr(I)) do
      Inc(I);
    Result := ATempDir + 'QP_' + IntToStr(I);
{$ENDIF}
  end;

begin
  // Ĭ��ͨ��ʵ�ֲ�����ʱ�ļ��Ļ����������ݱ��浽�ļ���Ȼ����ô��ļ��м��صķ�ʽ��ʵ��
  AFileStream := TFileStream.Create(GetTempFileName, fmCreate);
  try
    AFileStream.CopyFrom(AStream, 0);
    FreeObject(AFileStream);
    AFileStream := nil;
    Result := LoadServices(PWideChar(AFileName));
  finally
    if Assigned(AFileStream) then
      FreeObject(AFileStream);
    sysutils.DeleteFile(AFileName);
  end;
end;

function TQBaseLoader.InternalUnloadServices(const AHandle: THandle): Boolean;
begin
  Result := True;
end;

function TQBaseLoader.LoadServices(const AStream: IQStream): THandle;
var
  AVclStream: TQStream;
  AParams: TQParams;
  ALastState: TQLoaderState;
begin
  AParams := TQParams.Create;
  FLoadingModule := 0;
  ALastState := FState;
  FState := lsLoading;
  AParams.Add('File', ptUnicodeString).AsString := '<Stream>';
  AParams._AddRef;
  (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_LOADING, AParams);
  PluginsManager.ActiveLoader := Self;
  AVclStream := NewStream(AStream);
  try
    Result := InternalLoadServices(AVclStream);
    if ALastState = lsIdle then
    begin
      if Result <> 0 then
        AddModule('', Result);
    end;
  finally
    (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_LOADED, AParams);
    if Assigned(AParams) then
    begin
      AParams._Release;
      PluginsManager.ActiveLoader := nil;
    end;
    FreeAndNil(AVclStream);
    FLoadingModule := 0;
    FState := ALastState;
  end;
end;

procedure TQBaseLoader.RemoveModule(AModule: PQLoadedModule);
begin
  Dispose(AModule);
end;

procedure TQBaseLoader.SetLoadingModule(AInstance: HINST);
begin
  FLoadingModule := AInstance;
end;

procedure TQBaseLoader.Start;
var
  AExts: QStringW;
  AInst: THandle;
  ANotifyMgr: IQNotifyManager;
  function IsMatch(AName: QStringW): Boolean;
  var
    pExts, P: PWideChar;
    AExt: QStringW;
  begin
    pExts := PQCharW(AExts);
    AExt := UpperCase(ExtractFileExt(AName));
    P := StrStrW(pExts, PQCharW(AExt));
    Result := false;
    if P <> nil then
    begin
      if (P = pExts) or (P[-1] = ';') or (P[-1] = ',') then
      begin
        Inc(P, Length(AExt));
        if (P^ = #0) or (P^ = ',') or (P^ = ';') then
        begin
          Result := True;
          if Assigned(OnAccept) then
            OnAccept(Self, AName, Result);
        end;
      end;
    end;
  end;

  procedure StartPlugins(APath: String);
  var
    sr: TSearchRec; // ��ϵͳ�ķ�װ�Ա��ƽ̨
  begin
    if FindFirst(APath + '*.*', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Attr and faDirectory) = 0 then
        // ��������Ŀ¼�µĶ���
        begin
          if IsMatch(sr.Name) then
          begin
            AInst := LoadServices(PWideChar(FPath + sr.Name));
            if AInst <> 0 then
              AddModule(FPath + sr.Name, AInst);
          end;
        end
        else if FIncludeSubDir and (sr.Name <> '.') and (sr.Name <> '..') then
          StartPlugins(APath + sr.Name +
{$IFDEF MSWINDOWS}'\'{$ELSE}'/'{$ENDIF});
      until FindNext(sr) <> 0;
    end;
  end;

begin
  AExts := UpperCase(FileExt);
  FState := lsLoading;
  ANotifyMgr := PluginsManager as IQNotifyManager;
  try
    ANotifyMgr.Send(NID_PLUGIN_LOADING, nil);
    StartPlugins(FPath);
  finally
    FState := lsIdle;
    ANotifyMgr.Send(NID_PLUGIN_LOADED, nil);
  end;
end;

procedure TQBaseLoader.Stop;
var
  I: Integer;
  AItem: PQLoadedModule;
begin
  if FItems.Count > 0 then
  begin
    FState := lsUnloading;
    (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_UNLOADING, nil);
    try
      for I := FItems.Count - 1 downto 0 do
      begin
        AItem := PQLoadedModule(FItems[I]);
        try
          UnloadServices(AItem.Handle);
        except
          on E: Exception do
{$IFDEF MSWINDOWS}
            OutputDebugString(PChar('�޷�����ж�ز�� ' + AItem.FileName + ':' +
              E.Message));
{$ENDIF}
        end;
      end;
      Clear;
    finally
      FState := lsIdle;
      (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_UNLOADED, nil);
    end;
  end;
end;

function TQBaseLoader.LoadServices(const AFileName: PWideChar): THandle;
var
  AParams: TQParams;
  ALastState: TQLoaderState;
begin
  Result := HandleByFile(AFileName);
  if Result = 0 then
  begin
    FLoadingModule := 0;
    ALastState := FState;
    FState := lsLoading;
    AParams := TQParams.Create;
    AParams.Add('File', ptUnicodeString).AsString := AFileName;
    AParams._AddRef;
    (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_LOADING, AParams);
    PluginsManager.ActiveLoader := Self;
    try
      Result := InternalLoadServices(AFileName);
      if (ALastState = lsIdle) then
      begin
        if Result <> 0 then
          AddModule(AFileName, Result);
      end;
      AParams.Add('Instance', ptInt64).AsInt64 := Result;
    finally
      (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_LOADED, AParams);
      if Assigned(AParams) then
      begin
        AParams._Release;
        PluginsManager.ActiveLoader := nil;
      end;
      FLoadingModule := 0;
      FState := ALastState;
    end;
  end;
end;

function TQBaseLoader.UnloadServices(const AHandle: THandle;
  AWaitDone: Boolean): Boolean;
var
  AParams: TQParams;
  I: Integer;
  ALastState: TQLoaderState;
begin
  if AWaitDone then
  begin
    FUnloadingModule := AHandle;
    ALastState := FState;
    FState := lsUnloading;
    AParams := TQParams.Create;
    AParams.Add('Instance', ptInt64).AsInt64 := AHandle;
    AParams.Add('File', ptUnicodeString).AsString := FileByHandle(AHandle);
    AParams._AddRef;
    PluginsManager.ActiveLoader := Self;
    (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_UNLOADING, AParams);
    try
      Result := InternalUnloadServices(AHandle);
    finally
      (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_UNLOADED, AParams);
      if Assigned(AParams) then
      begin
        PluginsManager.ActiveLoader := nil;
        AParams._Release;
        for I := 0 to FItems.Count - 1 do
        begin
          if PQLoadedModule(FItems[I]).Handle = AHandle then
          begin
            RemoveModule(FItems[I]);
            FItems.Delete(I);
            break;
          end;
        end;
      end;
      FUnloadingModule := 0;
      FState := ALastState;
    end;
  end
  else
  begin
    begin
      PluginsManager.AsynCall(AsynUnload, NewParams([AHandle]));
      Result := True;
    end;
  end;
end;

procedure RegisterServices(AParent: PWideChar; AServices: array of IQService);
var
  AContainer: IQServices;
  I: Integer;
  AMgr: IQPluginsManager;
begin
  AMgr := PluginsManager;
  Lock;
  try
    AContainer := AMgr.ForcePath(AParent);
    for I := 0 to High(AServices) do
    begin
      AContainer.Add(AServices[I]);
    end;
  finally
    Unlock;
  end;
  for I := 0 to High(AServices) do
    AMgr.ServiceReady(AServices[I]);
end;

procedure UnregisterServices(APath: PWideChar; AServices: array of QStringW);
var
  AParent: IQServices;
  AItem: IQService;
  I, J: Integer;
begin
  if Supports(FindService(nil, APath), IQServices, AParent) then
  begin
    for I := 0 to High(AServices) do
    begin
      for J := 0 to AParent.Count - 1 do
      begin
        AItem := AParent[J];
        if StrCmpW(AItem.Name, PWideChar(AServices[I]), True) = 0 then
        begin
          AParent.Remove(AItem);
          break;
        end;
      end;
    end;
  end;
end;

function GetCurrentFileName: QStringW;
begin
  SetLength(Result, MAX_PATH);
  SetLength(Result,
{$IFDEF UNICODE}GetModuleFileName{$ELSE}GetModuleFileNameW{$ENDIF}(HInstance,
    PWideChar(Result), MAX_PATH));
end;

{ TQLocker }

constructor TQLocker.Create;
begin
  FLocker := TCriticalSection.Create;
end;

destructor TQLocker.Destroy;
begin
  FreeObject(FLocker);
  inherited;
end;

procedure TQLocker.Lock; stdcall;
begin
  FLocker.Enter;
end;

procedure TQLocker.Unlock; stdcall;
begin
  FLocker.Leave;
end;

{ TQStringService }

function TQStringService.NewString(S: PWideChar): IQString;
begin
  Result := TQUnicodeString.Create(S);
end;

{ TQInterfaceHolder }

constructor TQInterfaceHolder.Create(AOwner: TComponent;
  AInterface: IInterface);
begin
  inherited Create(AOwner);
  FInterface := AInterface;
end;

constructor TQInterfaceHolder.Create(AOwner: TComponent);
begin
  inherited;
end;

initialization

{$IFDEF MSWINDOWS}
  PluginsManagerNameSpace := 'Local\QPluginsManager_PID_' +
  IntToStr(GetCurrentProcessId);
{$ELSE}
{$IFDEF ANDROID}
  PluginsManagerNameSpace := '/data/local/tmp/QPluginsManager_PID_' +
  IntToStr(GetCurrentProcessId);
{$ELSE}
  PluginsManagerNameSpace := '/tmp/QPluginsManager_PID_' +
  IntToStr(GetCurrentProcessId);
{$ENDIF}
{$ENDIF}
_ActiveLoader := PluginsManager.ActiveLoader;
if Assigned(_ActiveLoader) then
  _ActiveLoader.SetLoadingModule(HInstance);

finalization

if _PluginsManager <> nil then
begin
  if HInstance = OwnerInstance then
  begin
    PluginsManager.Stop;
    (PluginsManager as IQNotifyManager).Send(NID_MANAGER_FREE, nil);
  end
  else
    _ActiveLoader := nil;
  UnregisterManager;
end;

end.
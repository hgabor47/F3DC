unit gl3dcontrols;

{: GL3DControls<p>

   3DUI by Gabor Horvath<p>

   <b>History : </b><font size=-1><ul>
      <li>17/10/2010 - ReDevelop :)
                       Controls:
                       Mouse middle + mousemove = turn around target
                       Mouse right + mousemove = turn around target
                       Moude left = close to target
                       Mouse right =
      <li>04/08/2008 - First 3DControls is finished
                       TGl3dcontrolButton,TGl3dcontrolEdit,TGl3dcontrolMemo
                       Known bugs:
                       Memo>
      <li>20/07/2008 - First codes
   <b>Bugs : </b><font size=-1><ul>
      <li>A1. When an Behaviour Event is working and I want to exit: exit is fail
      <li>A2. 1 line memo is not working
   </ul></font>
}

interface

uses types,messages,forms,applicationfileio,math,controls,classes,SysUtils,dialogs,
  glwindows,windows,keyboard,stdctrls,vectortypes,glcrossplatform,glbitmapfont,
  vectorgeometry,glbehaviours,glmovement,AsyncTimer,GLFullScreenViewer,
  gltexture,glfile3ds,globjects,geometryBB,glWindowsfont, glmaterial,glcontext,
  GLCadencer,GLThorFX,glvectorfileobjects, glscene,glColor,glpolyHedron,glskydome,
  glgeomobjects, glshadowplane, graphics;

var
  ScaleBase:TVector3f ;  //Vectorscale Base for objects

const
  C3dCameraSpeed      = 150;  // average multiplier
  C3dCameraMinSpeed   = 20;
  C3dCameraMinSpeed2  = 0.1;
  C3dCameraMaxSpeed   = 190;
  C3dCameraMaxSpeed2  = 20;
  C3dCameraScrollStep :double = 30;
  C3dCameraFar        = 220;
  C3dCameraNear       = 100;

  //TAG ID Definitions
  ControlDefaultBottom=40;
  ControlDefaultTop=41;
  ControlDefaultBack=42;
  ControlPartTag = 44;
  ControlPartNoneTag = 45;
  ControlMemoIndexStartTag = 1000;

// Proxy ID Definitions *for GLScene editor
// All object reference point are topleft
  StretchNone = 0;
  StretchW    = 1; //w idth
  StretchH   = 2; //h eight
  StretchD   = 4; //d epth
  StretchWH  = 3;
  StretchWD  = 5;
  StretchHD  = 6;
  StretchWHD = 7;
// Rarely : 0, 1, 2, 3

//thors default
  CThorColor : array[0..3] of tcolor = (clRed,clGreen,clBlue,clYellow);

// the filename = viewname + filenameparts
//   ex: "combobox_tl.3ds"
     FilenamePartTL = '_tl';
     FilenamePartTR = '_tr';
     FilenamePartT = '_t';
     FilenamePartBL = '_bl';
     FilenamePartBR = '_br';
     FilenamePartB = '_b';
     FilenamePartL = '_l';
     FilenamePartR = '_r';
     FilenamePart = '';    // main part

filenameparts : array[0..8] of string[5] =
    (FilenamePartTL,FilenamePartT,FilenamePartTR,
    FilenamePartL,FilenamePart,FilenamePartR,
    FilenamePartBL,FilenamePartB,FilenamePartBR);

    C3dFontHeight = 30;
    C3dFontHeight2 = 36;
    C3dFontScale = 100/C3dFontheight;

type
  TRGB = record
    r,g,b,w:byte;
  end;
  TGl3dcontrolbase = class;

//Classes

  pRbehaviourRecord = ^RbehaviourRecord;
  RbehaviourRecord = record
    obj:TGLBaseSceneObject;
    aBehaviour:TGLBehaviourClass;
    pathindex:integer;
    starttime:tdatetime; //starttime now +    [ 0 - 10min ] after 10min will deleted
    wait:tdatetime;
    next:pRbehaviourRecord;  //nil = NoNext
    deletetime:tdatetime;
  end;

  RObjMove = record
    lastMouseWorldPos:Tvector;
    obj:TGl3dcontrolbase;
  end;
				
  TBEmode = (beFill,beSphereFill,beDrawSphere,beTwoLayer);

  { TForm3d }

  TForm3d = class(TComponent)
  private
    mx,my:double;
    cameraDummy,cameratarget:TGLDummyCube;
    camera:TGLCamera;
    light,warninglight:TGLLightSource;
    fCameraDistance:double;
    fLastTargetObject:TGl3dcontrolbase;

    vBehaviourTimer: TAsyncTimer;
    BehaviourList:tlist;

    fcursor: TGLBaseSceneObject;
    ffocusedObject:TGl3dcontrolbase;

    FViewer: TGLFullScreenViewer;
    FOnKeyPress: TKeyPressEvent;
    FOnKeyDown: controls.TKeyEvent;
    FOnKeyUp: controls.TKeyEvent;
    FMainKeyPress: TKeyPressEvent;
    FMainKeyDown: controls.TKeyEvent;
    FMainKeyUp: controls.TKeyEvent;
    fMainMouseDown : TMouseEvent;
    fMainMouseUp : TMouseEvent;
    fMainMouseMove : TMouseMoveEvent;
    fMainMouseWheel : TMouseWheelEvent;

    FOnMouseDown: TMouseEvent;
    FOnMouseMove: TMouseMoveEvent;
    FOnMouseUp: TMouseEvent;
    FOnMouseWheel: TMouseWheelEvent;
    FWarning: boolean;
    FTexturePath: string;

    objMove:RObjMove;
    movingOnZ : Boolean;


    procedure SetViewer(const Value: TGLFullScreenViewer);
    procedure setCursor(const Value: TGLBaseSceneObject);
    procedure InitCursor;
    procedure clearfocus;
    procedure SetfocusedObject(const Value: TGl3dcontrolbase);
    procedure SetOnMouseDown(const Value: TMouseEvent);
    procedure SetOnMouseMove(const Value: TMouseMoveEvent);
    procedure SetOnMouseUp(const Value: TMouseEvent);
    procedure SetOnMouseWheel(const Value: TMouseWheelEvent);
    procedure BehaviourTimer(Sender: TObject);
    procedure BehaviourListclear;
    procedure PathTravelStop(Sender: TObject; Path: TGLMovementPath;
      var Looped: boolean);
    procedure setcamera;
    procedure goCameraTo(obj: TGl3dcontrolbase; distance: double);overload;
    procedure goCameraTo(distance:double);overload;
    procedure SetWarning(const Value: boolean);
    procedure SetTexturePath(const Value: string);
    procedure goObjectMove(x, y: integer);
    procedure goObjectMoveStart(obj: TGl3dcontrolbase; x, y: integer);
    function  MouseWorldPos(obj: TGLBaseSceneObject; x, y: Integer): TVector;
    procedure GLThorFXManagerCalcPoint(Sender: TObject; PointNo: Integer; var x,
      y, z: Single);
    procedure cadencerprogress(Sender: TObject; const deltaTime,newTime: Double);
  public
    controlslist:tlist;
    rootdummy:TGLDummyCube;
    defaultfont:TGLWindowsBitmapFont;
    environment:TGLDummyCube;
    exCadencer:TGLCadencer;

    constructor Create(AOwner: TComponent;fullviewer:TGLFullscreenviewer;cadencer:TGLCadencer); overload;
    constructor Create(AOwner: TComponent); override;overload;
    destructor  Destroy;override;
    procedure performdestroy;
    procedure keypress(Sender: TObject; var Key: Char);
    procedure keyup(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure keydown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure mouseup(Sender: TObject; Button: TMouseButton;Shift: TShiftState; X, Y: Integer);
    procedure mousedown(Sender: TObject; Button: TMouseButton;Shift: TShiftState; X, Y: Integer);
    procedure mousemove(Sender: TObject; Shift: TShiftState;X, Y: Integer);
    procedure mousewheel(Sender: TObject; Shift: TShiftState;
                 WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    function AddBehaviourEvent(obj:TGLBaseSceneObject;
        aBehaviour:TGLBehaviourClass;
        pathindex:integer;
        waitms:integer; //starttime now +    [ 0 - 10min ] after 10min will deleted
                        // if <0 then no threaded start
                        //     possible start from another event
        next:pRbehaviourRecord):pRbehaviourRecord;  //-1 = NoNext
    procedure BuildEnvironment(mode:TBEmode;basecolor:Tcolor=$00AC937D;bgcolor:Tcolor=$00AC937D;colordistance:single=0.1;density:integer=80;skydome:boolean=true;envdistance:integer=1000);
  published
    property Viewer:TGLFullScreenViewer read FViewer write SetViewer;
    property Cursor:TGLBaseSceneObject read fcursor write setCursor;
    property focusedObject:TGl3dcontrolbase  read FfocusedObject write SetfocusedObject;
    property OnKeyDown: controls.TKeyEvent read FOnKeyDown write FOnKeyDown;
    property OnKeyPress: TKeyPressEvent read FOnKeyPress write FOnKeyPress;
    property OnKeyUp: controls.TKeyEvent read FOnKeyUp write FOnKeyUp;
    property OnMouseDown : TMouseEvent read FOnMouseDown write SetOnMouseDown;
    property OnMouseUp : TMouseEvent read FOnMouseUp write SetOnMouseUp;
    property OnMouseMove : TMouseMoveEvent read FOnMouseMove write SetOnMouseMove;
    property OnMouseWheel : TMouseWheelEvent read FOnMouseWheel write SetOnMouseWheel;
    property Warning:boolean read FWarning write SetWarning;
    property TexturePath:string read FTexturePath write SetTexturePath;
  end;

  VInnerVector = array[0..1] of TVector3f;
Rnode = record
      position,scale,rotation:Tvector4f;
      speed:double;
end;
RMotionParams = record
   objtag:integer;
   node:Rnode;
end;
AMotionParams = array of RMotionParams;
AAMotionParams = array of AMotionParams;

TGL3DControlBase = class(TGLDummyCube)
private
    dummy          : TGLDummyCube;
    fCursorVisible : boolean;
    FOnClick       : TNotifyEvent;
    FOnKeyPress    : TKeyPressEvent;
    FOnKeyDown     : controls.TKeyEvent;
    FOnKeyUp       : controls.TKeyEvent;
    fEnter         : boolean;    // false= Enter is row braker char True= ...next Control
    fpadding       : Tvector3f;
    fmotionparams  : AAMotionParams; // in childrens
//    fthors         : array of TVector4f; //for user thor

    wl,wr,ht,hb,w,h,d,width100,height100,depth100:double;  //W idth H eight R ight L eft T op B ottom
    firstViewPartChildrenIndex:integer;

    fform3d:Tform3d;
    fviewName: string;
    fautoloadview: boolean;
    fwidth,fheight:double;
    Fselected: boolean;
    Ftabstop: boolean;
    fPartnumber:integer; // Parts number fix:  1 or 9
    fcenter:TGLDummyCube;
    thorcenter:TGLDummyCube;
    Fdepth: double;
    fviewobject: TGLBaseSceneObject;

    procedure setwidth(const Value: double);
    procedure setheight(const Value: double);
    procedure Setdepth(const Value: double);
    function  BoundBox:VInnerVector;
    procedure SetSelected(const Value: boolean);

    procedure keypress(Sender: TObject; var Key: Char);virtual;
    procedure keyup(Sender: TObject; var Key: Word;Shift: TShiftState);virtual;
    procedure keydown(Sender: TObject; var Key: Word;Shift: TShiftState);virtual;
    procedure setViewName(const Value: string);
    procedure clearView;
    procedure refreshview; virtual;
    procedure loadView;
    procedure SetCursorVisible(const Value: boolean);
    procedure Settabstop(const Value: boolean);
    procedure AddMotion(objectTag:integer;_index,step:integer;pos,sca,rot:TVector4f;speed:double);
    procedure ClearMotion;
    procedure Assignmotion(_index:integer);
    function  findObjectWithTag(_tag:integer):TGLBaseSceneObject;
    procedure SetThorEnabled(const Value: boolean);
    function  getThorEnabled: boolean;

    property CursorVisible:boolean read FCursorVisible write SetCursorVisible;
public
      fbuttons       : array of TGL3DControlBase;
      thor           : TGLThorFXManager;

			constructor Create(AOwner : TComponent); override;
      procedure   init(_form3d:Tform3d;_width,_height,_depth:double);
      destructor  Destroy;override;
      procedure   setForm3d(value:Tform3d);
      procedure   focusedObject;
      procedure   refresh;virtual;abstract;
      function    center:TGLDummyCube;
      procedure   padding(left,top,_depth:double);
      procedure   AddButton(value:TGL3DControlBase);
//      procedure   AddThor(value:Tvector4f);overload;
//      procedure   AddThor(value:Tvector4f;thorindex:integer);overload;
//      procedure   ClearThor;

published
      property viewName:string read fviewName write setViewName;
      property viewObject:TGLBaseSceneObject read fviewobject write fviewobject;
      property autoloadview:boolean read fautoloadview write fautoloadview default false;
      //   -----W-----
      //
      //   tl   t   tr    |     0 1 2
      //   l    ..   r    H     3 4 5
      //   bl   b   br    |     6 7 8
      //    adjusted : t,b for W and l,r for H
      property width:double read fwidth write setwidth ;
      property height:double read fheight write setheight ;
      property depth:double  read Fdepth write Setdepth;
      property Form3d:Tform3d read fform3d write setForm3d ;
      property selected:boolean read Fselected write SetSelected;
      property tabstop:boolean read Ftabstop write Settabstop;

    property OnClick: TNotifyEvent read FOnClick write FOnClick;
    property OnKeyDown: controls.TKeyEvent read FOnKeyDown write FOnKeyDown;
    property OnKeyPress: TKeyPressEvent read FOnKeyPress write FOnKeyPress;
    property OnKeyUp: controls.TKeyEvent read FOnKeyUp write FOnKeyUp;
    property ThorEnabled:boolean read getThorEnabled write SetThorEnabled;
end;


TGl3dcontrolButton = class (TGl3dcontrolbase)
private
    procedure setfocus;
public
published
end;


TGl3dcontrolTextBase = class (TGl3dcontrolbase)
private
    fInnerBox      :VInnerVector;
    FBitmapFont:TGLWindowsBitmapFont;
    ffontscale: double;
    fdefaultColor:TGLColor;
    Procedure SetBitmapFont(NewFont : TGLWindowsBitmapFont);
    Function  GetBitmapFont : TGLWindowsBitmapFont;
    function  getDefaultColor:TGLColor;virtual;
    procedure SetDefaultColor(const Value: TGLColor);virtual;
    procedure setfontscale(const Value: double);
    procedure fontrefresh;virtual;abstract;
    function getTitle: String;
    procedure setTitle(const Value: String);
public
    ftitle        : TGLFlattext;
  	constructor Create(AOwner : TComponent); override;
    destructor  Destroy;override;
    procedure   init(_Form3d:Tform3d;_width,_height,_depth:double;_BitmapFont : TGLWindowsBitmapFont);
    procedure   refresh;virtual;
published
    property BitmapFont : TGLWindowsBitmapFont read GetBitmapFont write SetBitmapFont;
    property FontScale : double read ffontscale write setfontscale;
    property FontColor : TGLColor read GetDefaultColor write SetDefaultColor;
    property Title:String read getTitle write setTitle;
end;


TGl3dcontrolText = class (TGl3dcontrolTextbase)
private
    fText:string;
    fcursorpos     : integer;
    fviewablepos   : integer;
    gltextf        : TGLFlattext;
//    fInnerBox      :VInnerVector;

    fflat: boolean;
    fMaxChars: integer;
    fMaxLength: integer;
    FOnResult: TNotifyEvent;
    FOnChange: TNotifyEvent;
    function  GetDefaultColor: TGLColor;override;
    procedure SetDefaultColor(const Value: TGLColor);override;
    function  getText: string;virtual;
    procedure setText(const Value: string);virtual;
    procedure setflat(const Value: boolean);
    procedure setfontscale(const Value: double);

    procedure setMaxChars(const Value: integer);
    procedure setMaxLength(const Value: integer);virtual;
    procedure textrefresh;virtual;
    procedure setcursorpos(Value: integer);

    procedure keypress(Sender: TObject; var Key: Char);override;
    procedure keyup(Sender: TObject; var Key: Word;Shift: TShiftState);override;
    procedure keydown(Sender: TObject; var Key: Word;Shift: TShiftState);override;
    procedure Setviewablepos(Value: integer);

    procedure refreshview;override;
    procedure lengthverify;virtual;
    procedure fontrefresh;override;

    property  viewablepos:integer read Fviewablepos write Setviewablepos;

public
  	constructor Create(AOwner : TComponent); override;
    destructor Destroy;override;
    procedure   init(_Form3d:Tform3d;_width,_height,_depth:double;_BitmapFont : TGLWindowsBitmapFont;
               maxChars,ViewableChars:integer);
    procedure refresh;override;
published
    property CursorPos:integer read fcursorpos write setcursorpos;
    property Text:string read getText write setText;
    property Flat:boolean read fflat write setflat;
    property maxChars:integer read fMaxChars write setMaxChars;
    property ViewableChars:integer read fMaxLength write setMaxLength;

    property OnResult : TNotifyEvent  read FOnResult write FOnResult; // AFTER ENTER KEY
    property OnChange : TNotifyEvent  read FOnChange write FOnChange; // AFTER ANY TEXT CHANGE

end;


TGl3dcontrolEdit = class (TGl3dcontrolText)
private
end;



TGl3dcontrolMemo = class (TGl3dcontrolText)
private
    fRowNum: integer;
    fViewableRows: integer;
    startpos,row,col:integer; // for lengthverify
    startrow:integer;


    procedure setRowNum(const Value: integer);
    procedure setViewableRows(const Value: integer);
    procedure textrefresh;override;
    procedure setMaxLength(const Value: integer);override;
    function  getText: string;override;
    procedure setText(const Value: string);override;
    procedure lengthverify;override;
    procedure lengthSet(srow,scol:integer);
    procedure keydown(Sender: TObject; var Key: Word;Shift: TShiftState);override;
    function  cursor2xy(cpos:integer):tpoint;
    function  xy2cursor(pos:tpoint):integer;
    procedure refreshview;override;
public

  	constructor Create(AOwner : TComponent);override;
    destructor Destroy;override;
    procedure init(_Form3d:Tform3d;_width,_height,_depth:integer;_BitmapFont : TGLWindowsBitmapFont;
               _RowNum,_ViewableRows,_ViewableChars:integer);

    property RowNum:integer read fRowNum write setRowNum;
    property ViewableRows:integer read fViewableRows write setViewableRows;
end;

AGLStatusObj = array of TGLBaseSceneObject;

TGL3dControlCheck = class (TGl3dcontroltextBase)
private
    statusobjlist:AGLStatusObj; // 1x1 dimensioned objects
    fstatus: integer;
    gltextf:TGLFlatText;
    procedure fontrefresh;override;
    procedure clearStatusObjList;
    procedure destroyStatusObjList;
    procedure refreshStatusObjList;
    procedure setstatus(const Value: integer);
    procedure clearstatus;
    procedure Settext(const Value: string);
    function  gettext:string;
    procedure click(Sender: TObject);
public
  	constructor Create(AOwner : TComponent);override;
    destructor  Destroy;override;
    procedure   init(_Form3d:Tform3d;_width,_height,_depth:double;_BitmapFont : TGLWindowsBitmapFont;_Text:string);
    procedure   refresh;override;
    procedure   setStatusObjectList(value: array of TGLBaseSceneObject);
published
    property status:integer read fstatus write setstatus;
    property text:string read gettext write Settext;
end;

AGLChecks = array of TGL3dControlCheck;

TGl3dcontrolRadio = class (TGl3dcontroltextbase)
private
    rowposition:double;
    statusobjects:array of TGLBaseSceneObject; // 1x1 dimensioned objects
    fItems:AGLChecks;
    Fitemindex: integer;
    Fmultiselect: boolean;
    procedure fontrefresh;override;
    procedure Setitemindex(const Value: integer);
    procedure Setmultiselect(const Value: boolean);
    procedure refreshStatusObjectList;
    procedure click(Sender: TObject);
    function  indexof(value: TGl3dcontrolCheck): integer;
public
  	constructor Create(AOwner : TComponent);override;
    destructor  Destroy;override;
    procedure   refresh;override;
    procedure   setStatusObjectList(value: array of TGLBaseSceneObject);
    procedure   clear;
    procedure   Add(value: string);
published
    property multiselect:boolean read Fmultiselect write Setmultiselect;
    property itemindex:integer read Fitemindex write Setitemindex;
    property Items:AGLChecks read fItems;

end;



RBase = record
    pivot:TGLDummyCube;
    control:TGl3dcontrolbase;
end;
pRBase = ^Rbase;
ABase = array of RBase;
TAnimationStyle = (asCombo,asFan,as2DMatrix);
RMatrixParameter = record
   shift:tvector4f;
   containposition:TVector4f;
   boxposition:tvector4f;
   boxscale:tvector4f;
end;



TGL3dcontrolGroup = class (TGl3dcontrolTextbase)
private
    contain          : TGLDummyCube;
    fControls        : ABase;
    fCollapsed       : boolean;
    fAnimationSpeed  : double;
    fAnimationStyle  : TAnimationStyle;
    FCollectionWaitMs: integer;
    FCaption         : TCaption;
    procedure SetAnimationSpeed(const Value: double);
    procedure SetAnimationStyle(const Value: TAnimationStyle);
    procedure SetCollectionWaitMs(const Value: integer);
    procedure SetCaption(const Value: TCaption);
    procedure fontrefresh;override;
public
    fParamsMatrix: RMatrixParameter;

  	constructor Create(AOwner : TComponent);override;
    destructor  Destroy;override;
    procedure   refresh;override;
    procedure   collapse;
    procedure   expand;
    function    add(control:TGl3dcontrolbase;referencepoint:TVector3f):TGl3dcontrolbase;
    procedure   clear(newparent:TGLBaseSceneObject);virtual;
    procedure   setAnimationMatrix(value:RMatrixParameter);overload;
    procedure   setAnimationMatrix(
                  shift:tvector4f;
                  containposition:TVector4f;
                  boxposition:tvector4f;
                  boxscale:tvector4f);overload;
published
    property Items:ABase read fControls;
    property AnimationStyle:TAnimationStyle read FAnimationStyle write SetAnimationStyle;
    property AnimationSpeed:double read FAnimationSpeed write SetAnimationSpeed;
    property CollectionWaitMs:integer   read FCollectionWaitMs write SetCollectionWaitMs;
    property Collapsed:boolean read fCollapsed;
    property Caption:TCaption read FCaption write SetCaption;
end;


TGl3dcontrolCombo = class (TGl3dcontrolGroup)
  private
    FDropDownCount: integer;
    FItems: TstringList;
    statusobjects:array of TGLBaseSceneObject; // 1x1 dimensioned objects

    procedure SetDropDownCount(const Value: integer);
    procedure SetItems(const Value: TstringList);
    procedure clear;
    procedure createrows(value:integer);
    procedure refreshStatusObjectList;
public
  	constructor Create(AOwner : TComponent);override;
    destructor  Destroy;override;
    procedure setStatusObjectList(value: array of TGLBaseSceneObject);
published
    property DropDownCount:integer read FDropDownCount write SetDropDownCount;
    property Items:TstringList read FItems ;
end;





//Static helper functions

function getProxyFromObjects(parentobj:TGLBaseSceneobject;value:array of TGLBaseSceneobject;width,height,depth:double):TGLDummyCube;
function getAbsoluteScale(this:TGLBaseSceneObject):tvector3f;
function CreateGL3DControlEdit(
          _position:Tvector3f;
          PARENT:TGLBaseSceneObject;
          FORM3D:Tform3d;
          width,height,depth:double;
          BitmapFont : TGLWindowsBitmapFont;
          maxChars,ViewableChars:integer;
          paddingleft,paddingtop,paddingdepth:double;
          _viewname:string;
          defaulttext:string
          ):TGl3dcontrolEdit;



function lighter(c:tcolor;volume:integer):tcolor;
function darker(c:tcolor;volume:integer):tcolor;


implementation
			   
function lighter(c:tcolor;volume:integer):tcolor;
var rgb:^trgb;
    a:word;
begin
     rgb:=@c;
     a:=rgb^.r+volume;
     if a>255 then rgb^.r:=255 else rgb^.r:=a;
     a:=rgb^.g+volume;
     if a>255 then rgb^.g:=255 else rgb^.g:=a;
     a:=rgb^.b+volume;
     if a>255 then rgb^.b:=255 else rgb^.b:=a;
     rgb^.w:=0;
     result:=tcolor(rgb^);
end;
function darker(c:tcolor;volume:integer):tcolor;
var rgb:^trgb;
    a:integer;
begin
     rgb:=@c;
     a:=rgb^.r-volume;
     if a<0 then rgb^.r:=0 else rgb^.r:=a;
     a:=rgb^.g-volume;
     if a<0 then rgb^.g:=0 else rgb^.g:=a;
     a:=rgb^.b-volume;
     if a<0 then rgb^.b:=0 else rgb^.b:=a;
     rgb^.w:=0;
     result:=tcolor(rgb^);
end;



//Value.TAG contained the stretch information
function getProxyFromObjects(parentobj:TGLBaseSceneobject;value:array of TGLBaseSceneobject;width,height,depth:double):TGLDummyCube;
var i:integer;
    g:TGLBInertia;
    px:TGLProxyObject;
begin
     result:=tgldummycube(parentobj.AddNewChild(tgldummycube));
     for I := 0 to length(value) - 1 do
     begin
         px:=TGLProxyObject(result.AddNewChild(TGLProxyObject));
         with px do
         begin
              MasterObject:=value[i];
              ProxyOptions:=[pooObjects,pooEffects];
              visible:=true;
              Scale.SetVector(1,1,1);                          //100 !
              if (value[i].tag and StretchW)=StretchW then
                 scale.X:=1*width;
              if (value[i].tag and StretchH)=StretchH then
                 scale.X:=1*height;
              if (value[i].tag and StretchD)=StretchD then
                 scale.X:=1*depth;

              GetOrCreateBehaviour(TGLBInertia);
              behaviours[0].Assign(tglbinertia(value[i].GetOrCreateBehaviour(TGLBInertia)));
              GetOrCreateBehaviour(TGLmovement);
              behaviours[1].Assign(tglMovement(value[i].GetOrCreateBehaviour(tglMovement)));
         end;
     end;
end;


function CreateGL3DControlEdit(
          _position:Tvector3f;
          PARENT:TGLBaseSceneObject;
          FORM3D:Tform3d;
          width,height,depth:double;
          BitmapFont : TGLWindowsBitmapFont;
          maxChars,ViewableChars:integer;
          paddingleft,paddingtop,paddingdepth:double;
          _viewname:string;
          defaulttext:string
          ):TGl3dcontrolEdit;
begin
     result:=nil;
     if form3d = nil then exit;

     if ((parent=nil) and (form3d.rootdummy<>nil)) then
         result:=TGl3dcontrolEdit(form3d.rootdummy.AddNewChild(TGl3dcontrolEdit))
     else
     begin
         if (parent<>nil) then
         begin
              result:=TGl3dcontrolEdit(PARENT.AddNewChild(TGl3dcontrolEdit));
         end;
     end;
     if (result<>nil) then
     begin
       result.FontColor.AsWinColor:=clBlack;
       if ((bitmapfont=nil) and (form3d.defaultfont<>nil)) then
           result.init(form3d,width,height,depth,form3d.defaultfont,maxChars,ViewableChars)
       else
           result.init(form3d,width,height,depth,bitmapfont,maxChars,ViewableChars);
       result.padding(paddingleft,paddingtop,paddingdepth);
       result.viewName:=_viewname;
       result.Text:=defaulttext;
       result.Position.SetPoint(_position[0],_position[1],_position[2]);
     end;
end;





function getAbsoluteScale(this:TGLBaseSceneObject):tvector3f;
var v1,v2:tvector3f;
    up,dir:tvector3f;
begin
      up:=this.up.AsAffineVector;
      dir:=this.Direction.AsAffineVector;

      this.up.SetVector(0,1,0);
      this.direction.SetVector(0,0,1);
      setvector(v1,0,0,0);
      setvector(v2,1,1,1);
      v1:=this.AbsoluteToLocal(v1);
      v2:=this.AbsoluteToLocal(v2);
      this.up.AsAffineVector:=up;
      this.Direction.AsAffineVector:=dir;

      result:=vectorsubtract(v2,v1);
      absvector(result);
end;

{ TGl3dcontrolbase }

constructor TGl3dcontrolbase.Create(AOwner: TComponent);
begin
  inherited create(aowner);
  fform3d:=nil;
  self.ShowAxes:=false;
  CursorVisible :=false;  //no cursor
  tabstop:=true;
  fEnter:=true;
  fcenter:=TGlDummyCube(self.AddNewChild(TGlDummyCube));
  scale.SetVector(scalebase[0],scalebase[1],scalebase[2]);
  dummy:=TGlDummyCube(self.AddNewChild(TGlDummyCube));
  dummy.Scale.SetVector(1,1,1);
  thorcenter:=TGlDummyCube(self.AddNewChild(TGlDummyCube));

  thor:=TGLThorFXManager.Create(self);
  thor.Disabled:=true;
//  thor.target.SetPoint(0,0,-1);
  thor.target.SetPoint(5,0,0);
  thor.core:=false;
  thor.Glowsize:=1;
  thor.Maxpoints:=4;
  thor.Vibrate:=0;
  thor.Wildness:=0;
  thor.OuterColor.red  :=1;
  thor.OuterColor.green:=1;
  thor.OuterColor.blue :=1;
  thor.InnerColor.red  :=1;
  thor.InnerColor.green:=1;
  thor.InnerColor.blue :=0;
  thor.InnerColor.Alpha:=0.3;

  TGLBThorFX(thorcenter.GetOrCreateEffect(TGLBThorFX)).manager:=thor;
  thorcenter.Position.SetPoint(0,0,-0.5);
end;

destructor TGl3dcontrolbase.Destroy;
begin
  thor.Destroy;
  SELF.Form3d:=nil;
  fcenter.destroy;
  thorcenter.destroy;
  dummy.Destroy;
  inherited destroy;
end;



procedure TGL3DControlBase.AddButton(value: TGL3DControlBase);
begin
     setlength(fButtons,length(fbuttons)+1);
     fbuttons[length(fbuttons)-1]:=value;
     value.MoveTo(self);
end;

procedure TGL3DControlBase.AddMotion(objectTag:integer;_index,step: integer;pos,sca,rot:TVector4f;speed:double);
var node:tglpathnode;
begin
     if _index>=length(fmotionparams) then
     begin
       setlength(fmotionparams,_index+1);
     end;
     if step>=length(fMotionParams[_index]) then
     begin
          setlength(fmotionparams[_index],step+1);
     end;
//     fMotionParams[index][step].node:=TGLpathNode.Create(nil); // try ... except
     fMotionParams[_index][step].objtag:=objecttag;
     try fMotionParams[_index][step].node.scale:=sca; except end;
     try fMotionParams[_index][step].node.Rotation:=rot;except end;
     try fMotionParams[_index][step].node.position:=pos; except end;
     try fMotionParams[_index][step].node.Speed:=speed; except end;
end;

{procedure TGL3DControlBase.AddThor(value: Tvector4f; thorindex: integer);
begin
     addthor(vectormake(value[0],value[1],value[2],thorindex));
end;

procedure TGL3DControlBase.AddThor(value: Tvector4f);
begin
     setlength(fThors,length(fThors)+1);
     fThors[length(fThors)-1]:=value;
end;
}

procedure TGL3DControlBase.AssignMotion(_index: integer);
var mov:tglmovement;
    path:TGLMovementPath;
    node:TGLPathNode;
    obj:TGLBaseSceneObject;
    i:integer;
begin
    obj:=nil;
    if _index<length(fmotionParams) then
    begin
         if length(fmotionParams[_index])>0 then
         begin
              obj:=findObjectWithTag(fmotionParams[_index][0].objtag);
              if assigned(obj) then
              begin
                   mov:=tglmovement(obj.GetOrCreateBehaviour(TGLmovement));
                   path:=mov.AddPath;
                   path.PathSplineMode:=lsmLines;
                   for i := 0 to length(fmotionParams[_index]) - 1 do
                   begin
                       node := path.AddNode;
                       node.PositionAsVector := fmotionParams[_index][i].node.Position;
                       node.ScaleAsVector := fmotionParams[_index][i].node.Scale;
                       node.RotationAsVector := fmotionParams[_index][i].node.Rotation;
                       node.Speed:=fmotionParams[_index][i].node.Speed;
                   end;
              end;
              Form3d.addBehaviourEvent(obj,TGLMovement,mov.PathCount-1,000,nil);
         end;
    end;
end;

function TGl3dcontrolbase.findObjectWithTag(_tag:integer):TGLBaseSceneObject;

    function search(obj:TGLBaseSceneobject):TGLBaseSceneobject;
    var i:integer;
    begin
         result:=nil;
         for i := 0 to obj.Count - 1 do
         begin
           if obj.children[i].Tag=_tag then
           begin
             result:=obj.children[i];
             break;
           end;
           if obj.children[i].Count>0 then //children
           begin
                result:=search(children[i]);
           end;
           if assigned(result) then
              exit;
         end;
    end;


begin
     result:=search(self);
end;

function TGl3dcontrolbase.Boundbox: VInnerVector;
begin
     result[0][0]:=wl;
     result[0][1]:=ht;
     result[0][2]:=-d/2;
     result[1][0]:=w+wl;
     result[1][1]:=h+ht;
     result[1][2]:=d/2;
end;

procedure TGl3dcontrolbase.refreshview;
var fre:TGLFreeform;
    i:integer;
    s:string;
    min,max,v:TAffineVector;
    vv:Tvector3f;
begin
   if viewname<>'' then
   begin

     width100:=width*100;     // in 3dstudio the 1x1 box = 100x100 units
     height100:=height*100;
     depth100:=depth*100;
     for i := 0 to {length(filenameparts)}fPartnumber - 1 do
     begin
          begin
               fre:=TGLFreeform(self.dummy.Children[firstViewPartChildrenIndex+i]);
               fre.Scale.SetVector(1,1,1);
               fre.GetExtents(min,max);
               v:=vectorsubtract(max,min);
               case i of
               0: begin
                        if fpartnumber>1 then
                        begin
                             wl:=v[0];ht:=v[2];
                             fre.position.SetPoint((wl/2),-(ht/2),0);
                        end
                        else
                        begin
                             wl:=0;ht:=0;
                             ht:=0;hb:=0;
                             w:=width100;h:=height100;d:=depth100;
                             fre.position.SetPoint((w/2),-(h/2),d/2);
                             fre.Scale.X:=(w/v[0]);
                             fre.Scale.y:=(h/v[1]);
                             fre.scale.z:=(d/v[2]);
                        end;
                  end;
               1: begin
                        fre.position.SetPoint(width100/2,-(ht/2),0);
                  end;
               4: begin
                        fre.position.SetPoint(width100/2,-(height100/2),0);
                  end;
               2: begin
                        wr:=v[0];
                        w:=math.max(width100-wr-wl,0);
                        fre.position.SetPoint(width100-(wr/2),-(ht/2),0);

                        TGLFreeform(self.dummy.Children[1+firstViewPartChildrenIndex]).GetExtents(min,max);
                        v:=vectorsubtract(max,min);
                        TGLFreeform(self.dummy.Children[1+firstViewPartChildrenIndex]).Scale.X:=(w/v[0]);
                  end;
               3: begin
                        fre.position.SetPoint((wl/2),-(height100/2),0);
                        //scale
                  end;
               5: begin
                        fre.position.SetPoint(width100-(wr/2),-(height100/2),0);
                        //scale
                  end;
               6: begin
                       hb:=v[2];
                       h:=math.max(height100-ht-hb,0);
                       fre.position.SetPoint((wl/2),-(height100-(hb/2)),0);

                       TGLFreeform(self.dummy.Children[3+firstViewPartChildrenIndex]).GetExtents(min,max);
                       v:=vectorsubtract(max,min);
                       TGLFreeform(self.dummy.Children[3+firstViewPartChildrenIndex]).Scale.y:=(h/v[1]);

                       TGLFreeform(self.dummy.Children[4+firstViewPartChildrenIndex]).GetExtents(min,max);
                       v:=vectorsubtract(max,min);
                       TGLFreeform(self.dummy.Children[4+firstViewPartChildrenIndex]).Scale.y:=(h/v[1]);
                       TGLFreeform(self.dummy.Children[4+firstViewPartChildrenIndex]).Scale.x:=(w/v[0]);

                       TGLFreeform(self.dummy.Children[5+firstViewPartChildrenIndex]).GetExtents(min,max);
                       v:=vectorsubtract(max,min);
                       TGLFreeform(self.dummy.Children[5+firstViewPartChildrenIndex]).Scale.y:=(h/v[1]);

                  end;
               7: begin
                       fre.position.SetPoint(width100/2,-(height100-(hb/2)),0);
                       fre.Scale.x:=(w/v[0]);
                  end;
               8: begin
                       fre.position.SetPoint(width100-(wr/2),-(height100-(hb/2)),0);
                  end;
               end;
          end;
     end;
   end;
   vv:=getAbsoluteScale(self);
   thorcenter.Scale.SetVector(vv[0],vv[1],0.3*vv[2]);
   thor.Glowsize:=50/vv[0];
end;

procedure TGl3dcontrolbase.SetCursorVisible(const Value: boolean);
begin
  FCursorVisible := Value;
end;


procedure TGl3dcontrolbase.Setdepth(const Value: double);
begin
  Fdepth := Value;
  refreshview;
end;

function TGl3dcontrolbase.center: TGLDummyCube;
var v:tvector3f;
begin
     v:=getAbsoluteScale(self);
     result:=fcenter;
     result.Position.SetPoint({width*v[0]}(w+wl+wr)/2,{height*v[1]}-(h+ht+hb)/2,0);
     result.Direction.AsAffineVector:=self.Direction.AsAffineVector;
     result.up.AsAffineVector:=self.up.AsAffineVector;
end;

procedure TGL3DControlBase.ClearMotion;
var i,j:integer;
begin
     for i := 0 to length(fmotionParams) - 1 do
     begin
//       for j := 0 to length(fmotionparams[i]) - 1 do
//       begin
//         fmotionparams[i][j].node.Destroy;
//       end;
       setlength(fmotionparams[i],0);
     end;
     setlength(fmotionparams,0);
end;

{procedure TGL3DControlBase.ClearThor;
begin
     setlength(fThors,0);
end;
}
procedure TGl3dcontrolbase.clearView;
var i:integer;
begin
     for I := count-1 downto 0 do
     begin
          if ((self.dummy.children[i].tag=ControlPartTag) or (self.dummy.children[i].tag=ControlPartNoneTag)) then
          begin
               self.dummy.Children[i].Destroy;
          end;
     end;
end;


procedure TGl3dcontrolbase.loadView;
var i:integer;
    s:string;
    fre:TGLFreeform;
    mat1:TGLMaterial;
begin
     if not fileexists(fviewname+filenameparts[1]+'.3ds') then
          fPartnumber:=1
     else
          fPartnumber:=length(filenameparts);

     firstViewPartChildrenIndex:=self.dummy.Count;
     for i := 0 to {length(filenameparts)}fPartnumber - 1 do
     begin
         s:=fviewname+filenameparts[i]+'.3ds';
         fre:=TGLFreeform(self.dummy.AddNewChild(TGLFreeform));

         if fileexists(s) then
         begin
            fre.MaterialLibrary:=tglmateriallibrary.create(nil);
            fre.LoadFromFile(s);
            fre.Tag:=ControlPartTag;
            fre.Visible:=true;
            fre.Material.BlendingMode:=bmTransparency;
         end
         else
         begin
              fre.Tag:=ControlPartNoneTag;
              fre.Visible:=false;
         end;
     end;
     refreshview;
end;


procedure TGl3dcontrolbase.padding(left, top, _depth: double);
begin
     fPadding[0]:=left;
     fPadding[1]:=top;
     fPadding[2]:=_depth;
end;

procedure TGl3dcontrolbase.focusedObject;
begin
     self.Form3d.focusedObject:=self;
end;

procedure TGl3dcontrolbase.init(_form3d: Tform3d; _width, _height,_depth: double);
begin
     setform3d(_form3d);
     setWidth(_width);
     setHeight(_height);
     setDepth(_depth);
end;

function TGL3DControlBase.getThorEnabled: boolean;
begin
     result:= not thor.Disabled;
end;
{
procedure TGl3dcontrolbase.init(Form3d: Tform3d; width, height,depth: double);
begin
     setform3d(form3d);
     setWidth(width);
     setHeight(height);
     setDepth(depth);
end;
}
procedure TGl3dcontrolbase.keydown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

end;

procedure TGl3dcontrolbase.keypress(Sender: TObject; var Key: Char);
begin

end;

procedure TGl3dcontrolbase.keyup(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

end;

procedure TGl3dcontrolbase.SetSelected(const Value: boolean);
begin
  FSelected := Value;
end;

procedure TGl3dcontrolbase.Settabstop(const Value: boolean);
begin
  Ftabstop := Value;
end;

procedure TGL3DControlBase.SetThorEnabled(const Value: boolean);
begin
  thor.Disabled:=not value;
end;

procedure TGl3dcontrolbase.setForm3d(value: Tform3d);
var i:integer;
begin
     if value<>fform3d then
     begin
        if assigned(fform3d) then
        begin
            try
             i:=fform3d.controlslist.IndexOf(self);
             if i>-1 then
                fform3d.controlslist.Delete(i);
            finally
            end;
        end;
        fform3d:=value;
        if value<>nil then
        begin
            fform3d.controlslist.Add(self);
        end;
     end;
end;

procedure TGl3dcontrolbase.setheight(const Value: double);
begin
  fheight := Value;
  refreshview;
end;



procedure TGl3dcontrolbase.setViewName(const Value: string);
begin
  if value<>fviewname then
  begin
       if fviewname<>'' then
       begin
            clearView;
       end;
       fviewName := Value;
       loadView;
  end;
end;

procedure TGl3dcontrolbase.setwidth(const Value: double);
begin
     fWidth:=value;
     refreshview;
end;


{ TGl3dcontrolButton }


procedure TGl3dcontrolButton.setfocus;
begin
  setSelected(true);
  if assigned(fOnClick) then
     fOnclick(self);
end;

{ TGl3dcontrolEdit }

constructor TGl3dcontrolText.Create(AOwner: TComponent);
begin
  inherited;
  CursorVisible :=true;  //no cursor
//  fDefaultColor:=TGLColor.create(Aowner);
  gltextf:=TGLFlatText(self.dummy.AddNewChild(TGLFlattext));
  gltextf.Text:=text;
  gltextf.Options:=[ftoTwoSided];
  fviewablepos:=0;
  fcursorpos:=0;
  refresh;
end;


procedure TGl3dcontrolText.textrefresh;
var    _w:double;
begin
      if length(ftext)>maxChars then
         ftext:=copy(ftext,1,maxChars);

      gltextf.text:=copy(ftext,fviewablepos+1,ViewableChars);
//length(ftext)-ViewableChars+1

      if assigned(form3d) and assigned(Form3d.Cursor) then
      begin
        if assigned(bitmapfont) then
        begin
             _w:=gltextf.BitmapFont.TextWidth(copy(ftext,fviewablepos,cursorpos-fviewablepos));
             self.Form3d.Cursor.Position.SetPoint(_w,-C3dFontHeight/2,0);
        end;
      end;
end;

procedure TGl3dcontrolText.keydown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
     if assigned(fOnKeyDown) then
        fOnKeyDown(Sender,Key,shift);
     if key=VK_LEFT then
     begin
          cursorpos:=cursorpos-1;
          if cursorpos<viewablepos then
              viewablepos:=viewablepos-1;
          key:=0;
          textrefresh;
     end;
     if key=VK_RIGHT then
     begin
          cursorpos:=cursorpos+1;
          if cursorpos>viewablepos+viewablechars then
          begin
              viewablepos:=viewablepos+1;
          end;
          key:=0;
          textrefresh;
     end;
     if key=VK_HOME then
     begin
          cursorpos:=0;
          viewablepos:=0;
          key:=0;
          textrefresh;
     end;
     if key=VK_END then
     begin
          cursorpos:=maxlongint;
          viewablepos:=cursorpos-viewablechars; //14-4 = 10
          key:=0;
          textrefresh;
     end;
     if key=VK_RETURN then
     begin
          if assigned(fOnResult) then
             fOnResult(self);
     end;
     if key=VK_DELETE then
     begin
            fText:=copy(fText,1,max(cursorpos,0))+copy(fText,cursorpos+2,length(fText)+1);
            cursorpos:=cursorpos;
            if cursorpos<viewablepos then
                viewablepos:=viewablepos-1;

     end;
end;

procedure TGl3dcontrolText.lengthverify;
begin
//
end;


procedure TGl3dcontrolText.keypress(Sender: TObject; var Key: Char);
begin
     if assigned(fOnKeyPress) then
        fOnKeyPress(Sender,Key);


     if key=chr(8)  then
     begin
        Text:=copy(Text,1,max(cursorpos-1,0))+copy(Text,cursorpos+1,length(Text)+1);
        cursorpos:=cursorpos-1;
        if cursorpos<viewablepos then
            viewablepos:=viewablepos-1;
     end
     else
     begin
          if (fEnter and (key<chr(32))) then
            exit;

          if length(text)<maxChars then
          begin
             Text:=copy(Text,1,cursorpos)+key+copy(Text,cursorpos+1,length(Text)+1);
             lengthverify;

             cursorpos:=cursorpos+1;
             if cursorpos>viewablepos+viewablechars then
                viewablepos:=viewablepos+1;

             // Viewable chars setting ... ??

          end;
     end;

     textrefresh;

     if assigned(fOnChange) then
        fOnChange(self);
end;


procedure TGl3dcontrolText.keyup(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
     if assigned(fOnKeyUp) then
        fOnKeyUp(Sender,Key,shift);
end;

procedure TGl3dcontrolText.refresh;
begin
  inherited refresh;
  gltextf.Scale.SetVector(c3dfontscale*fFontScale,c3dfontscale*fFontScale,c3dfontscale*fFontScale);
  fInnerBox:=Boundbox;
  gltextf.Position.SetPoint(fInnerBox[0][0]+fpadding[0],-fInnerBox[0][1]-fpadding[1],((fInnerBox[0][2]+fInnerBox[1][2])/2) +fpadding[2]);
  textrefresh;
end;

procedure TGl3dcontrolText.refreshview;
begin
  inherited;          /// ooooouch brrr... :)
  gltextf.movedown;
  gltextf.movedown;
  gltextf.movedown;
  gltextf.movedown;
  gltextf.movedown;
  gltextf.movedown;
  gltextf.movedown;
  gltextf.movedown;
  gltextf.movedown;

end;


destructor TGl3dcontrolText.destroy;
begin
  if ((assigned(gltextf)) and (gltextf<>nil)) then
  gltextf.Destroy;
//  fDefaultColor.Destroy;
  inherited destroy;
end;

procedure TGl3dcontrolText.fontrefresh;
begin
   gltextf.BitmapFont:=FBitmapFont;
end;


function TGl3dcontrolText.GetDefaultColor: TGLColor;
begin
     result:=glTextf.ModulateColor;
end;

function TGl3dcontrolTextBase.GetBitmapFont: TGLWindowsBitmapFont;

Begin
  Result := Nil;
  if Assigned(FBitmapFont) then
     Result := FBitmapFont
  else
End;



function TGl3dcontrolTextBase.getDefaultColor: TGLColor;
begin
     result:=fdefaultcolor;
end;

function TGl3dcontrolTextBase.getTitle: String;
begin
     result:=ftitle.text;
end;

procedure TGl3dcontrolTextBase.init(_Form3d: Tform3d; _width, _height,_depth: double;
  _BitmapFont: TGLWindowsBitmapFont);
begin
     inherited init(_form3d,_width,_height,_depth);
     setbitmapfont(_bitmapfont);

end;


procedure TGl3dcontrolTextBase.refresh;
begin
     //set ftitle position
//     ftitle.Scale.SetVector(c3dfontscale*fFontScale,c3dfontscale*fFontScale,c3dfontscale*fFontScale);
//     ftitle.Position.AsAffineVector:=Affinevectormake(0,0,0);
//     ftitle.Layout:=tlBottom;
end;

procedure TGl3dcontrolTextBase.SetDefaultColor(const Value: TGLColor);
begin
  if assigned(fdefaultcolor) then
  begin
    fdefaultColor.Destroy;
  end;
  FDefaultColor.Assign(value);
end;



function TGl3dcontrolText.getText: string;
begin
     result:=fText;
end;

procedure TGl3dcontrolText.init(_Form3d: Tform3d;
  _width, _height,_depth: double;_BitmapFont: TGLWindowsBitmapFont;maxChars,ViewableChars:integer);
begin
     inherited init(_form3d,_width,_height,_depth,_bitmapfont);
     setMaxChars(maxchars);
     setMaxLength(ViewableChars);
end;

procedure TGl3dcontrolTextBase.SetBitmapFont(NewFont: TGLWindowsBitmapFont);
Begin
   if NewFont<>FBitmapFont then begin
      if Assigned(FBitmapFont) then
      Begin
         FBitmapFont.RemoveFreeNotification(Self);
         FBitmapFont.UnRegisterUser(Self);
      End;
      FBitmapFont:=NewFont;
      if assigned(FBitmapFont) then
         FBitmapFont.Font.Height:=-C3dFontHeight;
      if Assigned(FBitmapFont) then begin
         FBitmapFont.RegisterUser(Self);
         FBitmapFont.FreeNotification(Self);
      end;
   end;
   if Assigned(FBitmapFont) then begin
      ftitle.BitmapFont:=Fbitmapfont;
      fontrefresh;
      refresh;
   end;

End;

procedure Tform3d.setCursor(const Value: TGLBaseSceneObject);
begin
   if value<>fcursor then
   begin
        fcursor:=value;
        InitCursor;
   end;
end;

procedure Tform3d.InitCursor;
begin
     if assigned(focusedObject) then
     begin
          if focusedObject is TGl3dcontrolText then
          begin
               fcursor.MoveTo(TGl3dcontrolText(focusedObject).gltextf);
//               Fcursor.Parent:=TGl3dcontrolText(focusedObject).gltextf;
               Fcursor.Visible:=TGl3dcontrolText(focusedObject).fCursorVisible;
//               fcursor.Scale.SetVector(
//                 (1/TGl3dcontrolText(focusedObject).Scale.x)/TGl3dcontrolText(focusedObject).gltextf.Scale.X,
 //                (1/TGl3dcontrolText(focusedObject).Scale.z)/TGl3dcontrolText(focusedObject).gltextf.Scale.y,
 //                (1/TGl3dcontrolText(focusedObject).Scale.z)/TGl3dcontrolText(focusedObject).gltextf.Scale.z);
               fcursor.Scale.SetVector(
                 (10)/TGl3dcontrolText(focusedObject).gltextf.Scale.X,
                 (10)/TGl3dcontrolText(focusedObject).gltextf.Scale.y,
                 (10)/TGl3dcontrolText(focusedObject).gltextf.Scale.z);
               TGl3dcontrolText(focusedobject).refresh;
          end;
     end;
end;

procedure TGl3dcontrolText.setcursorpos(Value: integer);
begin
  if value<0 then value:=0;
  if value>length(ftext) then value:=length(ftext);

  fcursorpos := Value;
  textrefresh;
end;


procedure TGl3dcontrolText.SetDefaultColor(const Value: TGLColor);
begin
     inherited;
     glTextf.ModulateColor:=value;
end;

procedure TGl3dcontrolText.setflat(const Value: boolean);
begin
  fflat := Value;
end;



procedure TGl3dcontrolText.setfontscale(const Value: double);
begin

end;

procedure TGl3dcontrolTextbase.setfontscale(const Value: double);
begin
  ffontscale := Value;
  refresh;
end;

procedure TGl3dcontrolTextBase.setTitle(const Value: String);
begin
     ftitle.text:=value;
end;

procedure TGl3dcontrolText.setMaxChars(const Value: integer);
begin
  fMaxChars := Value;
  if fmaxchars<0 then fmaxchars:=maxlongint;
  
end;

procedure TGl3dcontrolText.setMaxLength(const Value: integer);
begin
  fMaxLength := Value;
end;


procedure TGl3dcontrolText.setText(const Value: string);
begin
     fText:=value;
     refresh;
     if assigned(fOnChange) then
        fOnChange(self);
end;

procedure TGl3dcontrolText.Setviewablepos(Value: integer);
begin
  if value<0 then value:=0;
  if value>length(ftext) then value:=length(ftext);
     
  Fviewablepos := Value;
end;

{ T3DForm }


procedure TForm3d.clearfocus;
var i:integer;
begin
     for I := 0 to controlslist.Count - 1 do
     begin
         TGl3dcontrolbase(controlslist[i]).selected:=false;
     end;
end;

{procedure TForm3d.ClearThors;
var i:integer;
begin
     for i := 0 to length(thors) - 1 do
     begin
          thors[i].Destroy;
     end;
     setlength(thors,0);
end;
}
constructor TForm3d.Create(AOwner: TComponent);
var glscene:TGLScene;
    //view: TGLFullscreenviewer;
    cam:TGLCamera;
    stat:array[0..2] of TGLBaseSceneObject;
    curs:TGLBaseSceneObject;
    iner:TGLBInertia;

    test:TGLBaseSceneObject;
begin
  inherited Create (AOwner);
  tform(aowner).Left:=1440;
  decimalseparator:='.';
  randomize;
  controlslist:=tlist.create;
  BehaviourList:=tlist.Create;
  exCadencer:=TGLCadencer.Create(AOwner);
  excadencer.OnProgress:=@cadencerprogress;


  vBehaviourTimer:=TAsyncTimer.Create(self);
  vBehaviourTimer.Interval:=1; // 100ms
  vBehaviourTimer.ThreadPriority:=tpNormal;
  vBehaviourTimer.OnTimer:=@BehaviourTimer;
  vBehaviourTimer.enabled:=true;
  Setvector(ScaleBase,0.1,0.1,0.1);

//SCREEN,SCENE
  Viewer := TGLFullscreenviewer.Create(AOwner);
  viewer.Form:=tform(aowner);
  viewer.Width:=1440;
  viewer.Height:=900;
  viewer.Buffer.AntiAliasing:=csa16x;
  viewer.buffer.ContextOptions:=[roDoubleBuffer,roOpenGL_ES2_Context];
  viewer.Buffer.BackgroundColor:=$bbbbbb;
  viewer.Active:=true;
  glscene:=TGLScene.Create(AOwner);

//CAMERA
  fCameraDistance:=C3dCameraNear;
  cam:=TGLCamera(glscene.Objects.AddNewChild(TGLCamera));
  cam.DepthOfView:=1000;
  cam.Position.Z:=153;
  viewer.Camera:=cam;
  setcamera;
  TGLMovement(cam.GetOrCreateBehaviour(TGLMovement)).StartPathTravel;

//  test:=VIEWER.Buffer.GetPickedObject(111,111);

//ROOT DUMMY
  with TGLDummyCube(glscene.Objects.AddNewChild(TGLDummyCube)) do
  begin
      name := 'firstdummy';
  end;
  rootdummy:=TGLDummyCube(glscene.Objects.AddNewChild(TGLDummyCube));

//STAT
  stat[0]:=glscene.Objects.AddNewChild(TGLDodecahedron);
  TGLDodecahedron(stat[0]).Material.FrontProperties.Diffuse.AsWinColor:=clGray;
  stat[1]:=glscene.Objects.AddNewChild(TGLDodecahedron);
  TGLDodecahedron(stat[1]).Material.FrontProperties.Diffuse.AsWinColor:=clGreen;
  stat[2]:=glscene.Objects.AddNewChild(TGLCube);
  TGLDodecahedron(stat[2]).Material.FrontProperties.Diffuse.AsWinColor:=clRed;

//CURSOR
  curs:=glscene.Objects.AddNewChild(TGLCube);
  TGLCube(curs).Material.FrontProperties.Diffuse.AsWinColor:=clBlack;
  TGLCube(curs).CubeDepth:=7;
  TGLCube(curs).CubeHeight:=4;
  TGLCube(curs).CubeWidth:=1;
  iner:=TGLBInertia(curs.GetOrCreateBehaviour(TGLBInertia));
  iner.PitchSpeed:=180;
  cursor:=curs;

//CADENCER GO
  with exCadencer do
  begin
      scene:=glscene;
      sleeplength:=-1;
      //FixedDeltaTime:=0.1;
      //MinDeltaTime:=0.01;
      //MaxDeltaTime:=1.2;
      Timemultiplier:=1;
      mode:=cmASAP;
      enabled:=true;
  end;

//FONT
  defaultfont:=TGLWindowsBitmapFont.Create(AOwner);
  with TGLWindowsBitmapFont(defaultfont).Font do
  begin
       name:='Arial';
       size:=10;
  end;

//  viewer.Active:=true;
end;

constructor TForm3d.Create(AOwner: TComponent;fullviewer:TGLFullscreenviewer;cadencer:TGLCadencer);
begin
     inherited Create (AOwner);
     randomize;
     decimalseparator:='.';
     controlslist:=tlist.create;
     BehaviourList:=tlist.Create;

     vBehaviourTimer:=TAsyncTimer.Create(self);
     vBehaviourTimer.Interval:=100; // 100ms
     vBehaviourTimer.threadPriority:=tphigher;
     vBehaviourTimer.OnTimer:=@BehaviourTimer;
     vBehaviourTimer.enabled:=true;
     fCameraDistance:=C3dCameraNear;
     if cadencer=nil then
        exCadencer:=TGLCadencer.Create(AOWner)
     else
        excadencer:=cadencer;

     Viewer := fullviewer;

     Setvector(ScaleBase,0.1,0.1,0.1);
     decimalseparator:='.';
end;


destructor TForm3d.destroy;
var
  i: Integer;
begin
  viewer.Active:=false;


  while controlslist.count>0 do
  begin
       if assigned(controlslist[0]) then
          TGl3dcontrolbase(controlslist[0]).Destroy;

  end;
  controlslist.destroy;
  vbehaviourtimer.OnTimer:=nil;
  vbehaviourtimer.Enabled:=false;
  exCadencer.Destroy;

  viewer.Camera.Scene.Destroy;
  viewer.Destroy;

  //vBehaviourTimer.destroy;
  BehaviourListclear;
  BehaviourList.Destroy;

  //inherited destroy;

end;

procedure TForm3d.performdestroy;
begin
  while controlslist.count>0 do
  begin
       if assigned(controlslist[0]) then
          TGl3dcontrolbase(controlslist[0]).Destroy;
  end;

  vbehaviourtimer.OnTimer:=nil;
  vbehaviourtimer.Enabled:=false;
  //viewer.Active:=false;
  BehaviourListclear;
end;

{function TForm3d.AddThor:TGLThorFXManager;
begin
     setlength(thors,length(thors)+1);
     thors[length(thors)-1]:=TGLThorFXManager.Create(self);
     thors[length(thors)-1].OnCalcPoint:=GLThorFXManagerCalcPoint;
     thors[length(thors)-1].Cadencer:=exCadencer;


     if length(thors)<length(CThorColor) then
     begin //default
       thors[length(thors)-1].OuterColor.asWincolor:=CThorColor[length(thors)-1];
     end;
     thors[length(thors)-1].GlowSize:=0.2;
     thors[length(thors)-1].Maxpoints:=2;
     thors[length(thors)-1].Wildness:=0;
     result:=thors[length(thors)-1];
end;
}
procedure TForm3d.GLThorFXManagerCalcPoint(Sender: TObject; PointNo: Integer;
  var x, y, z: Single);
begin
     
end;

procedure TForm3d.cadencerprogress(Sender: TObject; const deltaTime,newTime: Double);
begin
     //application.ProcessMessages;
end;

procedure TForm3d.BehaviourListclear;
var i:integer;
begin
     for i := 0 to behaviourlist.count - 1 do
     begin
       freemem(behaviourlist[i]);
     end;
     behaviourlist.Clear;
end;

function TForm3d.AddBehaviourEvent(obj: TGLBaseSceneObject;
  aBehaviour: TGLBehaviourClass; pathindex, waitms:integer; next: pRbehaviourRecord):pRbehaviourRecord;
var p:pRbehaviourRecord;
begin
     getmem(p,sizeof(RbehaviourRecord));
     behaviourlist.Add(p);
     p^.obj:=obj;
     p^.aBehaviour:=aBehaviour;
     p^.pathindex:=pathindex;
     if waitms>=0 then //
          p^.starttime:=now()
     else
          p^.starttime:=0;
     p^.wait:=((1/86400000)*waitms);
     p^.next:=next;
     p^.deletetime:=now()+((1/86400)*600); // 10minutes
     result:=p;
end;


procedure TForm3d.BehaviourTimer(Sender: TObject);
var n:tdatetime;
    p:pRbehaviourRecord;
    mov:TGLMovement;
    inertia:TGLBInertia;
    i:integer;
begin
     n:=now;
     i:=0;
     while i<behaviourlist.Count do
     begin
          p:=pRbehaviourRecord(behaviourlist[i]);
          if ((p^.starttime<>0) and (n>(p^.starttime+p^.wait))) then
          begin
               if p^.aBehaviour=TGLMovement then
               begin
                    mov:=TGLMovement(p^.obj.GetOrCreateBehaviour(TGLMovement));
                    mov.ActivePathIndex:=p^.pathindex;
                    mov.StartPathTravel;
                    mov.OnPathTravelStop:=@PathTravelStop;
               end;
               if p^.aBehaviour=TGLBInertia then
               begin
                    inertia:=TGLBInertia(p^.obj.GetOrCreateBehaviour(p^.aBehaviour));
               end;
               if assigned(p^.next) then
               begin
                    p^.next^.starttime:=now();
               end;
               freemem(behaviourlist[i]);
               behaviourlist.Delete(i);
          end
          else
          begin
              if n>p^.deletetime then
              begin
                   freemem(behaviourlist[i]);
                   behaviourlist.Delete(i);
              end
              else
                  inc(i);
          end;
     end;
end;

procedure TForm3d.PathTravelStop(Sender: TObject;
    Path: TGLMovementPath; var Looped: boolean);
begin
  if sender is TGLMovement then
  begin
    TGLMovement(sender).ClearPaths;
  end;
end;



procedure TForm3d.keydown(Sender: TObject; var Key: Word; Shift: TShiftState);
var i,j:integer;
begin
     if assigned(self.FMainKeyDown) then
        fmainkeydown(sender,key,shift);

     if ((key=VK_F4) and (shift = [ssAlt])) then
     begin
         self.performdestroy;
         exit;
     end;
     if key=VK_RETURN then
     begin
          if assigned(focusedObject) then
          begin
               if focusedObject.fEnter then
               begin
                 j:=0;
                 repeat
                       i:=controlslist.IndexOf(focusedobject);
                       inc(i);
                       if i>=controlslist.count then
                          i:=0;
                       inc(j);
                 until ((TGl3dcontrolbase(controlslist[i]).tabstop=true) or (j=controlslist.count));
                 if j<>controlslist.count then
                 begin
                      self.focusedObject:=TGl3dcontrolbase(controlslist[i]);
                 end;
               end;
          end;
     end;


// controls

     for I := 0 to controlslist.Count - 1 do
     begin
         if TGl3dcontrolbase(controlslist[i]).Selected then
         begin
              TGl3dcontrolbase(controlslist[i]).keydown(sender,key,shift);
         end;
     end;

// self
     if assigned(fOnKeyDown) then
        fonkeydown(sender,key,shift);

end;

procedure TForm3d.keyup(Sender: TObject; var Key: Word; Shift: TShiftState);
var i:integer;
begin
     if assigned(self.FMainKeyUp) then
        fmainkeyup(sender,key,shift);

// controls

     for I := 0 to controlslist.Count - 1 do
     begin
         if TGl3dcontrolbase(controlslist[i]).Selected then
         begin
              TGl3dcontrolbase(controlslist[i]).keyup(sender,key,shift);
         end;
     end;

// self
     if assigned(fOnKeyUp) then
        fonkeyup(sender,key,shift);


end;


procedure TForm3d.mousedown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var picked:TGLBaseSceneObject;
    i,j:integer;
begin
     mx:=x/10;
     my:=y/10;

     if assigned(self.FMainMouseDown) then
        fmainMouseDown(sender,button,shift,x,y);

// picked test
     try
        if assigned(self.fViewer.Buffer) then
           picked:=self.fViewer.Buffer.GetPickedObject(x,y);
     finally
     end;
     if assigned(picked) then
     begin
          for i := 0 to controlslist.Count - 1 do
          begin
               j:=TGl3dcontrolbase(controlslist[i]).IndexOfChild(picked);
               if j=-1 then
                  j:=TGl3dcontrolbase(controlslist[i]).dummy.IndexOfChild(picked);
               if j<>-1 then
               begin
                    if assigned(TGl3dcontrolbase(controlslist[i]).FOnClick) then
                       TGl3dcontrolbase(controlslist[i]).FOnClick(TGl3dcontrolbase(controlslist[i]));
                    TGl3dcontrolbase(controlslist[i]).focusedObject;
                    if  (ssRight in shift) then
                    begin
                         goCamerato(TGl3dcontrolbase(controlslist[i]),C3dCameraFar);
                    end
                    else
                    begin
                         if  ssLeft in shift then
                         begin
                              goCamerato(TGl3dcontrolbase(controlslist[i]),fCameraDistance);
                         end
                         else
                         if  ssMiddle in shift then
                         begin
                              goObjectMoveStart(TGl3dcontrolbase(controlslist[i]),x,y);
                         end;
                    end;
               end;
          end;
     end;



// self
     if assigned(fOnMouseDown) then
        fonMouseDown(sender,button,shift,x,y);


end;

procedure TForm3d.mousemove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin

    if assigned(self.FMainMouseMove) then
        fmainMouseMove(sender,shift,x,y);


    if ssRight in shift then
    begin
       self.FViewer.Camera.MoveAroundTarget(my-(y/10),mx-(x/10));
    end;
    if ssMiddle in shift then
    begin
         if (ssShift in Shift)<>movingOnZ then begin
            movingOnZ:=(ssShift in Shift);
            objmove.lastMouseWorldPos:=MouseWorldPos(objmove.obj,x, y);
         end;
         goObjectMove(x,y);
    end;
    mx:=x/10;
    my:=y/10;

// self
    if assigned(fOnMouseMove) then
        fonMousemove(sender,shift,x,y);
end;

procedure TForm3d.mouseup(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
     if assigned(self.FMainMouseUp) then
        fmainMouseUp(sender,button,shift,x,y);

// self
     if assigned(fOnMouseUp) then
        fonMouseUp(sender,button,shift,x,y);

end;

procedure TForm3d.mousewheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
     if assigned(self.FMainMouseWheel) then
        fmainMouseWheel(sender,shift,wheeldelta,mousepos,handled);

// self
     if wheelDelta>0 then
     begin
          fCameraDistance:=Math.max(fCameraDistance-C3dCameraScrollStep,1.5);

     end
     else
     begin
          fCameraDistance:=fCameraDistance+C3dCameraScrollStep
     end;
     goCamerato(fCameraDistance);




     if assigned(fOnMouseWheel) then
        fonMouseWheel(sender,shift,wheeldelta,mousepos,handled);

end;


procedure TForm3d.BuildEnvironment(mode:TBEmode;basecolor:Tcolor=$00AC937D;bgcolor:Tcolor=$00AC937D;colordistance:single=0.1;density:integer=80;skydome:boolean=false;envdistance:integer=1000);
var glscene:TGLScene;
    i,j:integer;
    l:TGLLines;
    glcolor:TGLColor;
    clVector1:tcolorvector;
    node:TGLLinesNode;
    nodevector,nodebase:TAffineVector;
    fenvdistance,layerdistance:single;
    dome:TGLBaseSceneObject;

//     basecolor:tcolor=$00AC937D;
//     colordistance=0.2;
//     envdistance=1000;
//     density=400;
//     part = 2;


     procedure nearto(var vector1:TVector4f;distance:single);
     var vector2:TVector4f;
     begin
          setvector(Vector2,
              (distance*random())-(distance/2),
              (distance*random())-(distance/2),
              (distance*random())-(distance/2));
          addvector(vector1,vector2);
     end;

begin
     if not assigned(camera.Scene) then exit;
     glscene:=camera.Scene;
     environment:=TGLDummyCube(glscene.Objects.AddNewChild(TGLDummyCube));
     viewer.Buffer.BackgroundColor:=bgcolor;

     if skydome then
     begin
       dome:=glscene.FindSceneObject('firstdummy');
       if assigned(dome) then
       begin
         with TGLEarthSkyDome(dome.AddNewChild(TGLEarthSkyDome)) do
         begin
           direction.SetVector(0.05,0.95,0.05,0);
           skycolor.AsWinColor:=bgcolor;
           deepcolor.aswincolor:=darker(bgcolor,80);
         end;
       end;
     end;

     for i:= 0 to density do
     begin
         l:=TGLLines(environment.AddNewChild(TGLLines));
         l.Options:=[loUseNodeColorForLines];
         l.nodesaspect:=lnaInvisible;
         l.linewidth:=1;
         l.division:=9;


         if mode = beTwoLayer then
         begin
           fenvdistance:=envdistance*2;
           layerdistance:=(1-((i mod 2)*2))* envdistance/3;
           setvector(nodevector,random-0.5,0,random-0.5);
           //normalizevector(nodevector);
           setvector(nodebase,0,layerdistance,0);
           combinevector(nodebase,nodevector,fenvdistance);
           l.Position.AsAffineVector:=nodebase;

           l.SplineMode:=lsmCubicSpline;
           l.LineWidth:=1;
//           l.Direction.SetVector(0,0,1);
           for j:=0 to 6 do
           begin
               node:=tgllinesnode(l.Nodes.Add);
 {color}
               glcolor:=tglcolor.CreateInitialized(self,ConvertWinColor(basecolor));
               clVector1:=glcolor.color;
               nearto(clvector1,colordistance);
               glcolor.Color:=clvector1;
               node.Color:=glcolor;
               glcolor.destroy;
 {position}
               fenvdistance:=envdistance/10;
               setvector(nodevector,random-0.5,random-0.5,random-0.5);
               normalizevector(nodevector);
               setvector(nodebase,0,0,0);
               combinevector(nodebase,nodevector,fenvdistance);
               node.asAffinevector:=nodebase;
           end;
           l.Scale.y:=0.4;

         end
         else
           if mode = beDrawSphere then
           begin
             fenvdistance:=envdistance/2;
             setvector(nodevector,random-0.5,random-0.5,random-0.5);
             normalizevector(nodevector);
             setvector(nodebase,0,0,0);
             combinevector(nodebase,nodevector,fenvdistance);
             l.Position.AsAffineVector:=nodebase;
             l.SplineMode:=lsmCubicSpline;
             l.LineWidth:=1;
             l.Direction:=l.Position;
             for j:=0 to 6 do
             begin
                 node:=tgllinesnode(l.Nodes.Add);
   {color}
                 glcolor:=tglcolor.CreateInitialized(self,ConvertWinColor(basecolor));
                 clVector1:=glcolor.color;
                 nearto(clvector1,colordistance);
                 glcolor.Color:=clvector1;
                 node.Color:=glcolor;
                 glcolor.destroy;
   {position}
                 fenvdistance:=envdistance/10;
                 setvector(nodevector,random-0.5,random-0.5,random-0.5);
                 normalizevector(nodevector);
                 setvector(nodebase,0,0,0);
                 combinevector(nodebase,nodevector,fenvdistance);
                 node.asAffinevector:=nodebase;
             end;
             l.Scale.Z:=0.5;
           end
           else
           begin
              l.SplineMode:=lsmBezierSpline;
              for j:=0 to 2 do
              begin
                  node:=tgllinesnode(l.Nodes.Add);
    {color}
                  glcolor:=tglcolor.CreateInitialized(self,ConvertWinColor(basecolor));
                  clVector1:=glcolor.color;
                  nearto(clvector1,colordistance);
                  glcolor.Color:=clvector1;
                  glcolor.Alpha:=0.2;
                  node.Color:=glcolor;
                  glcolor.destroy;
    {position}
                   if mode = beFill then
                   begin
                        setvector(nodevector,random(envdistance)-(envdistance/2),random(envdistance)-(envdistance/2),random(envdistance)-(envdistance/2));
                        node.asAffinevector:=nodevector;
                   end;
                   if mode = beSphereFill then
                   begin
                        fenvdistance:=envdistance/2;
                        setvector(nodevector,random-0.5,random-0.5,random-0.5);
                        normalizevector(nodevector);
                        setvector(nodebase,0,0,0);
                        combinevector(nodebase,nodevector,fenvdistance);
                        node.asAffinevector:=nodebase;
                   end;
              end;
           end;
     end;

end;

procedure TForm3d.keypress(Sender: TObject; var Key: Char);
var i:integer;
begin
     if assigned(self.FMainKeyPress) then
        fmainkeypress(sender,key);

// controls

     for I := 0 to controlslist.Count - 1 do
     begin
         if TGl3dcontrolbase(controlslist[i]).Selected then
         begin
              TGl3dcontrolbase(controlslist[i]).keypress(sender,key);
         end;
     end;

// self
     if assigned(fOnKeyPress) then
        fonkeypress(sender,key);

end;


procedure TForm3d.SetfocusedObject(const Value: TGl3dcontrolbase);
begin
     clearfocus;
     value.Selected:=true;
     ffocusedObject:=value;
     InitCursor;
end;


procedure TForm3d.SetOnMouseDown(const Value: TMouseEvent);
begin
  FOnMouseDown := Value;
end;

procedure TForm3d.SetOnMouseMove(const Value: TMouseMoveEvent);
begin
  FOnMouseMove := Value;
end;

procedure TForm3d.SetOnMouseUp(const Value: TMouseEvent);
begin
  FOnMouseUp := Value;
end;

procedure TForm3d.SetOnMouseWheel(const Value: TMouseWheelEvent);
begin
  FOnMouseWheel := Value;
end;

procedure TForm3d.SetTexturePath(const Value: string);
begin
  FTexturePath := Value;
  //glFile3ds.path3ds:=value;
  //raise EAbort.create('FILE3DS read path ??');
end;

procedure TForm3D.goObjectMoveStart(obj:TGl3dcontrolbase;x,y:integer);
begin
     objmove.lastMouseWorldPos:=MouseWorldPos(obj,x, y);
     objmove.obj:=obj;
end;
procedure TForm3D.goObjectMove(x,y:integer);
var
   newPos : TVector;
begin
     newPos:=MouseWorldPos(objmove.obj,x, y);
     if assigned(self.focusedObject) and (VectorNorm(objmove.lastMouseWorldPos)<>0) then
     begin
          focusedobject.Position.Translate(vectorsubtract(newpos,objmove.lastMouseWorldPos));
     end;
     objmove.lastMouseWorldPos:=newpos;
end;
function TForm3D.MouseWorldPos(obj:TGLBaseSceneObject;x, y : Integer) : TVector;
var
   v : TVector;
begin
   y:= Viewer.Height-y;
   if Assigned(obj) then begin
      SetVector(v, x, y, 0);
      if movingOnZ then
         viewer.Buffer.ScreenVectorIntersectWithPlaneXZ(v, obj.Position.Y, Result)
      else
         Viewer.Buffer.ScreenVectorIntersectWithPlaneXY(v, obj.Position.Z, Result);
   end else SetVector(Result, NullVector);
end;

procedure TForm3D.SetViewer(const Value: TGLFullScreenViewer);
var cam:TGLCamera;
begin
  FViewer := Value;
  fmainkeyup:=fviewer.OnKeyUp;
  fmainkeyDown:=fviewer.OnKeyDown;
  fmainkeyPress:=fviewer.OnKeyPress;
  fviewer.OnKeyUp:=@keyup;
  fviewer.OnKeyDown:=@keydown;
  fviewer.OnKeyPress:=@keypress;

  fmainmouseup:=fviewer.OnMouseUp;
  fmainmouseDown:=fviewer.OnMouseDown;
  fmainmousemove:=fviewer.OnMousemove;
  fmainmouseWheel:=fviewer.OnMouseWheel;

  fviewer.OnMouseUp:=@mouseup;
  fviewer.OnMouseDown:=@mousedown;
  fviewer.OnMousemove:=@mousemove;
  fviewer.OnMouseWheel:=@mouseWheel;

  setcamera;
//  self.FViewer.Camera:=camera;
//  cam:=self.FViewer.Camera;
  //exCadencer.Scene:=self.FViewer.Camera.Scene;

end;


procedure TForm3d.SetWarning(const Value: boolean);
var
    path:TGLMovementpaths;
    ine:TGLBInertia;
    node:tglpathnode;
begin
  FWarning := Value;
  if value then
  begin
    light.Diffuse.SetColor(0.2,0.2,0.2,1);
    warninglight.Diffuse.SetColor(1,0,0,1);
    ine:=TGLBInertia(warninglight.GetOrCreateBehaviour(TGLBInertia));
    ine.pitchSpeed:=400;
  end
  else
  begin
    light.Diffuse.SetColor(1,1,1,1);
    warninglight.Diffuse.setcolor(0,0,0,0);
    ine:=TGLBInertia(warninglight.GetOrCreateBehaviour(TGLBInertia));
    ine.pitchSpeed:=0;
    warninglight.Direction.AsAffineVector:=camera.Direction.AsAffineVector;
  end;
end;

procedure TForm3d.goCameraTo(distance:double);
begin
     goCameraTo(fLastTargetObject,distance);
end;


procedure TForm3d.goCameraTo(obj: TGl3dcontrolbase;distance:double);
var
    path:TGLMovementpaths;
    mov:TGLMovement;
    I:INTEGER;
    traveldistance:single;
    d:double;
    node:tglpathnode;
    _abs:double;
begin
//target
   if assigned(obj) then
   begin
     mov:=TGLMovement(cameratarget.GetOrCreateBehaviour(TGLMovement));
     mov.StopPathTravel;
     path:=mov.Paths;
     path.Clear;
     with path.Add do
     begin
       ShowPath:=false;
       with nodes.Add do
       begin
            positionAsVector:=cameratarget.AbsolutePosition;
              speed:=900;
       end;
       with nodes.Add do
       begin
            positionAsVector:=obj.center.AbsolutePosition;
            RollAngle:=obj.RollAngle;
            TurnAngle:=obj.TurnAngle;
            PitchAngle:=obj.PitchAngle;
              speed:=400;
       end;
         d:=sqr((NodeDistance(nodes[0],nodes[1])/100));
         traveldistance:=Math.max(Math.min(d/C3dCameraSpeed,C3dCameraMaxSpeed2),C3dCameraMinSpeed2);
       nodes[0].Speed:=traveldistance*nodes[0].Speed;
       nodes[1].Speed:=traveldistance*nodes[1].Speed;
     end;
     if ((d>0.0002) or ((fLastTargetObject=obj) and (d>0))) then
     begin
          mov.ActivePathIndex:=0;
          mov.StartPathTravel;
     end;

//camera
       mov:=TGLMovement(camera.GetOrCreateBehaviour(TGLMovement));
     mov.StopPathTravel;
     path:=mov.Paths;
     path.Clear;
     with path.Add do
     begin
       PathSplineMode:=lsmBezierSpline;
       ShowPath:=false;
       node:=nodes.Add;
         node.positionAsVector:=camera.AbsolutePosition;
       node.speed:=10;

       node:=nodes.Add;
       _abs:=10/vectorgeometry.VectorLength(getAbsoluteScale(obj));
       node.positionAsVector:=vectoradd(obj.center.AbsolutePosition,vectorscale(obj.center.Direction.asvector,distance*_abs));
       node.speed:=1;

       d:=sqr((NodeDistance(nodes[0],nodes[1])/100));
       traveldistance:=math.max(math.min(d/C3dCameraSpeed,C3dCameraMaxSpeed),C3dCameraMinSpeed);
       nodes[0].Speed:=traveldistance*nodes[0].Speed;
       nodes[1].Speed:=traveldistance*nodes[1].Speed;
     end;
     if ((d>0.002) or ((fLastTargetObject=obj) and (d>0))) then
     begin
          mov.ActivePathIndex:=0;
          mov.StartPathTravel;
     end;

     fLastTargetObject:=obj;
   end;
end;



{procedure tform3d.setcamera;
var i:integer;
    mov:TGLMovement;
begin
  if assigned(fviewer.Camera) then // with parent dummy and with light
  begin
       if fviewer.Camera.Parent is TGLdummyCube then
       begin
            cameraDummy:=TGLDummyCube(fviewer.Camera.Parent);
            camera:=fviewer.Camera;

            light:=nil;
//search LightSource
            for i := 0 to cameradummy.count - 1 do
            begin
                 if ((light=nil) and (cameradummy.Children[i] is TGLLightSource)) then
                 begin
                      light:=TGLLightSource(cameradummy.Children[i]);
                      light.Name:='headlight';
                 end
                 else
                   if ((warninglight=nil) and (cameradummy.Children[i] is TGLLightSource)) then
                   begin
                      warninglight:=TGLLightSource(cameradummy.Children[i]);
                      warninglight.name:='warninglight';
                   end;
            end;
            if not assigned(light) then
            begin
                 light:=TGlLightSource(cameradummy.Scene.Objects.AddNewChild(TGlLightSource));
                 light.LightStyle:=lsSpot;
            end;
            if not assigned(warninglight) then
            begin
                 warninglight:=TGlLightSource(cameradummy.Scene.Objects.AddNewChild(TGlLightSource));
                 warninglight.LightStyle:=lsParallel;
                 warninglight.Ambient.AsWinColor:=clBlack;
            end;


//Search target dummy
            cameratarget:=TGLDummyCube(camera.Scene.findSceneObject('cameratarget'));
            if not assigned(cameratarget) then
            begin
                 cameratarget:=TGlDummyCube(camera.Scene.Objects.AddNewChild(TGlDummyCube));
                 cameratarget.Name:='cameratarget';
            end;
            camera.TargetObject:=cameratarget;
       end;
  end;
end;
}



procedure tform3d.setcamera;
var i:integer;
    mov:TGLMovement;
begin
  if assigned(fviewer.Camera) then // with parent dummy and with light
  begin
//       if fviewer.Camera.Parent is TGLdummyCube then
       begin
//            cameraDummy:=TGLDummyCube(fviewer.Camera.Parent);
            camera:=fviewer.Camera;

            light:=nil;
//search LightSource
            for i := 0 to camera.count - 1 do
            begin
                 if ((light=nil) and (camera.Children[i] is TGLLightSource)) then
                 begin
                      light:=TGLLightSource(camera.Children[i]);
                      light.Name:='headlight';
                 end
                 else
                   if ((warninglight=nil) and (camera.Children[i] is TGLLightSource)) then
                   begin
                      warninglight:=TGLLightSource(camera.Children[i]);
                      warninglight.name:='warninglight';
                   end;
            end;
            if not assigned(light) then
            begin
                 light:=TGlLightSource(camera.Scene.Objects.AddNewChild(TGlLightSource));
                 light.LightStyle:=lsSpot;
            end;
            if not assigned(warninglight) then
            begin
                 warninglight:=TGlLightSource(camera.Scene.Objects.AddNewChild(TGlLightSource));
                 warninglight.LightStyle:=lsParallel;
                 warninglight.Ambient.AsWinColor:=clBlack;
            end;


//Search target dummy
            cameratarget:=TGLDummyCube(camera.Scene.findSceneObject('cameratarget'));
            if not assigned(cameratarget) then
            begin
                 cameratarget:=TGlDummyCube(camera.Scene.Objects.AddNewChild(TGlDummyCube));
                 cameratarget.Name:='cameratarget';
            end;
            camera.TargetObject:=cameratarget;
       end;
  end;
end;



{ TGl3dcontrolMemo }

constructor TGl3dcontrolMemo.Create(AOwner: TComponent);
begin
  inherited create(aowner);
  fEnter:=false; //multirows with enter
  startrow:=0;
end;


destructor TGl3dcontrolMemo.Destroy;
begin
  inherited;
end;



function TGl3dcontrolMemo.getText: string;
begin
     result:=fText;
end;

procedure TGl3dcontrolMemo.setMaxLength(const Value: integer);
begin
  inherited;
end;


procedure TGl3dcontrolMemo.setRowNum(const Value: integer);
begin
  fRowNum := Value;
end;

procedure TGl3dcontrolMemo.setText(const Value: string);
begin
  inherited SETTEXT(value);
end;

procedure TGl3dcontrolMemo.setViewableRows(const Value: integer);
begin
     if fViewableRows<>value then
     begin
       fViewableRows := Value;
     end;
end;



procedure TGl3dcontrolMemo.textrefresh;
var    _w:double;
     s:string;
     i,_row,_col:integer;
     _startpos:integer;
     hh:double;

     procedure getrow;
     var j:integer;
     begin
          _startpos:=xy2cursor(Types.point(1,startrow))+1;
//               row:=(cursorpos div fmaxlength);
//               col:=(cursorpos mod fmaxlength);
          _row:=0;
          _col:=0;
          for j := 1 to min(length(s),cursorpos) do
          begin
            if s[j]=chr(13) then
            begin
               _col:=-1;
               inc(_row);
               _startpos:=j+1;
            end;
            inc(_col);
          end;
     end;

var posfrom,posto:integer ;

begin
      if length(text)>maxChars then
         text:=copy(text,1,maxChars);

      if ((fviewablerows>0) and (cursor2xy(cursorpos).Y-startrow > fviewableRows)) then
      begin
           inc(startrow);
      end;
      if ((fviewablerows>0) and (cursor2xy(cursorpos).Y-startrow < 1)) then
      begin
           dec(startrow); if startrow<0 then startrow:=0;
                          
      end;

      s:=text;
      posfrom:=xy2cursor(types.point(1,startrow))+1;
      posto:=xy2cursor(types.point(maxlongint,fviewableRows+startrow));
      gltextf.text:=copy(s,posfrom,posto-posfrom+1);
//length(ftext)-ViewableChars+1

      if assigned(form3d) and assigned(Form3d.Cursor) then
      begin
        if assigned(bitmapfont) then
        begin
             if fviewableRows>0 then
             begin
               getrow;
               _w:=gltextf.BitmapFont.TextWidth(copy(s,_startpos,_col));
               hh:=bitmapfont.CharHeight;
               self.Form3d.Cursor.Position.SetPoint(_w,-((_row-startrow)*{C3dFontHeight2}hh)-(hh{C3dFontHeight2}/2),0);
             end;
        end;
      end;
end;

function TGl3dcontrolMemo.cursor2xy(cpos: integer): tpoint;
var j:integer;
    s:string;
begin
  s:=text;
  result.X:=0;
  result.Y:=0;
  if ((length(s)<1)) then //??? or -1
     exit;

  j:=1;
  while j<=length(s) do
  begin
       if cpos<0 then //??? or -1
          exit;
       if s[j]=chr(13) then
       begin
            result.x:=0;
            inc(result.y);
       end
       else
       begin
            inc(result.x);
       end;
       dec(cpos);
       inc(j);
  end;
end;

function TGl3dcontrolMemo.xy2cursor(pos: tpoint): integer;
var
    s:string;
begin
  s:=text;
  result:=0;
  if ((length(s)<1)) then //??? or -1
     exit;

  result:=0;
  while result<=length(s) do
  begin
       if s[result]=chr(13) then
       begin
            dec(pos.y);
            if pos.y<0 then
            begin
               dec(result); // before enter
               exit;
            end;
       end;
       if pos.y=0 then
       begin
            dec(pos.x);
            if pos.x=0 then
               exit;
            if pos.x<0 then
            begin
               dec(result);
               exit;
            end;

       end;
       inc(result);
  end;
end;

procedure TGl3dcontrolMemo.init(_Form3d: Tform3d; _width, _height,_depth: integer;
  _BitmapFont: TGLWindowsBitmapFont; _RowNum, _ViewableRows,
  _ViewableChars: integer);
begin
     inherited init(_form3d,_width,_height,_depth,_bitmapfont,-1,_ViewableChars);
     setRowNum(_rownum);
     setViewableRows(_ViewableRows);
end;


procedure TGl3dcontrolMemo.keydown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
   p:tpoint;
begin
  inherited;
     if key=VK_UP then
     begin
          lengthverify;
          p:=cursor2xy(cursorpos);
          cursorpos:=xy2cursor(types.point(p.X,max(p.y-1,0)));

          if cursorpos<viewablepos then
              viewablepos:=viewablepos-1;
          key:=0;
          textrefresh;
     end;
     if key=VK_DOWN then
     begin
          lengthverify;
          p:=cursor2xy(cursorpos);
          cursorpos:=xy2cursor(types.point(p.X,p.y+1));

          if cursorpos>viewablepos+viewablechars then
          begin
              viewablepos:=viewablepos+1;
          end;
          key:=0;
          textrefresh;
     end;

end;

procedure TGl3dcontrolMemo.lengthSet(srow,scol:integer);
     // row, col -> cursorpos;
var j:integer;
    s,s2:string;
    arow,acol,astartpos:integer;
begin
  inherited;

  s:=text;
  astartpos:=1;
  arow:=0;
  acol:=0;
  j:=1;
  while j<=length(s) do
  begin
       if s[j]=chr(13) then
       begin
            acol:=0;
            inc(arow);
            s2:=s2+s[j];
            astartpos:=length(s2);
       end
       else
       begin
            if acol<scol then
            begin
                 s2:=s2+s[j];
                 inc(acol);
                 fcursorpos:=acol+astartpos; // megvan a sor
            end
            else
            begin
                if arow=srow then
                   exit;
                s2:=s2+chr(13);
                acol:=0;
            end;
       end;
       inc(j);
  end;
end;

procedure TGl3dcontrolMemo.lengthverify;
var j:integer;
         s,s2:string;
begin
  inherited;

  s:=text;
  startpos:=1;
  row:=0;
  col:=0;
  j:=1;
  while j<=length(s) do
  begin
       if s[j]=chr(13) then
       begin
            col:=0;
            inc(row);
            s2:=s2+s[j];
            startpos:=length(s2);
       end
       else
       begin
            if col<(fmaxLength-1) then
            begin
                 s2:=s2+s[j];
                 inc(col);
            end
            else
            begin
                s2:=s2+chr(13);
                col:=0;
            end;
       end;
       inc(j);
  end;
  text:=s2;
end;

procedure TGl3dcontrolMemo.refreshview;
begin
  inherited;          /// ooooouch brrr... :)
  gltextf.movedown;
  gltextf.movedown;
  gltextf.movedown;
  gltextf.movedown;
  gltextf.movedown;
  gltextf.movedown;
  gltextf.movedown;
  gltextf.movedown;
end;

{ TGl3dcontrolTextBase }

constructor TGl3dcontrolTextBase.Create(AOwner: TComponent);
begin
  inherited;
  ffontscale:=1;
  fdefaultColor:=TGLColor.Create(nil);
  ftitle:=TGLFlatText(self.AddNewChild(TGLFlattext));
  ftitle.Layout:=TGLTextlayout.tlBottom;
  ftitle.text:='Title';
  ftitle.Scale.SetVector(c3dfontscale*(fFontScale/3),c3dfontscale*(fFontScale/3),c3dfontscale*(fFontScale/3));
  ftitle.Position.AsAffineVector:=Affinevectormake(0,0,0);
end;

destructor TGl3dcontrolTextBase.Destroy;
begin
  ftitle.destroy;
  if assigned(Bitmapfont) then
     BitmapFont:=nil;
  fdefaultColor.Destroy;
  inherited;
end;


{ TGl3dcontrolRadio }


procedure TGl3dcontrolCheck.clearStatusObjList;
begin
     setlength(statusobjlist,0);

end;


procedure TGL3dControlCheck.click(Sender: TObject);
begin
     status:=status+1;
     if status>=length(statusobjlist) then
        status:=0;
end;

procedure TGl3dcontrolCheck.destroyStatusObjList;
var i:integer;
begin
     for i := 0 to length(statusobjlist) - 1 do
     begin
       statusobjlist[i].destroy;
     end;
     clearStatusObjList;
end;

procedure TGl3dcontrolRadio.Add(value: string);
var va:tvector3f;
begin
     setlength(fitems,length(fitems)+1);
     if length(fitems)<2 then
     begin
       rowposition:=0;
       fitems[length(fitems)-1]:=TGl3dcontrolCheck(self.dummy.AddNewChild(TGl3dcontrolCheck));
     end
     else
     begin
       va:=getAbsoluteScale(self);
       rowposition:=100;//*va[1];
       fitems[length(fitems)-1]:=TGl3dcontrolCheck(fitems[length(fitems)-2].AddNewChild(TGl3dcontrolCheck));
     end;
     fitems[length(fitems)-1].init(self.Form3d,self.width,self.height,self.depth,self.BitmapFont,value);
     fitems[length(fitems)-1].Scale.setvector(1,1,1);
     fitems[length(fitems)-1].setStatusObjectList(self.statusobjects);
     fitems[length(fitems)-1].Position.setpoint(0,-rowposition,0);
     fitems[length(fitems)-1].padding(self.fpadding[0],self.fpadding[1],self.fpadding[2]);
     fitems[length(fitems)-1].status:=0;
     fitems[length(fitems)-1].FOnClick:=@click;
     fitems[length(fitems)-1].text:=value;
end;

procedure TGl3dcontrolCheck.init(_Form3d: Tform3d; _width, _height,_depth: double;
  _BitmapFont: TGLWindowsBitmapFont; _Text: string);
begin
     inherited init(_form3d,_width,_height,_depth,_bitmapfont);
     settext(_text);
end;

procedure TGl3dcontrolRadio.clear;
var
  i,c: Integer;

begin
     c:=length(fItems);
     for i := c-1 downto 0 do    //down because the first's parent is self
                                 // another parent are the previous tcheck..
     begin
          if assigned(TGl3dcontrolCheck(fItems[i])) then
             TGl3dcontrolCheck(fItems[i]).destroy;
     end;
     setlength(fItems,0);
end;

procedure TGl3dcontrolRadio.click(Sender: TObject);
begin
     if sender is TGl3dcontrolCheck then
     begin
          if fmultiselect then
          begin
               TGl3dcontrolCheck(sender).click(self);
          end
          else
          begin
               itemindex:=indexOf(TGl3dcontrolCheck(sender));
          end;
     end;
end;

function TGl3dcontrolRadio.indexof(value:TGl3dcontrolCheck):integer;
begin
     for result := 0 to length(items) - 1 do
     begin
          if value=items[result] then
             exit;
     end;
end;

constructor TGl3dcontrolRadio.Create(AOwner: TComponent);
begin
  inherited;
  setlength(fitems,0);
  rowposition:=0;
end;

destructor TGl3dcontrolRadio.Destroy;
begin
  clear;
  inherited;
end;

procedure TGl3dcontrolRadio.fontrefresh;
begin
     //
end;

procedure TGl3dcontrolRadio.refresh;
begin
     inherited refresh;
end;

procedure TGl3dcontrolRadio.refreshStatusObjectList;
var i:integer;
begin
     for i := 0 to length(fitems) - 1 do
     begin
          fitems[i].setStatusObjectList(statusobjects);
     end;
end;

procedure TGl3dcontrolRadio.Setitemindex(const Value: integer);
var i:integer;
begin
  if fitemindex<length(items) then
  begin
       for I := 0 to length(items) - 1 do
       begin
            items[i].status:=0;
       end;
       Fitemindex := Value;
       items[Fitemindex].status:=1;
  end;
end;



procedure TGl3dcontrolRadio.Setmultiselect(const Value: boolean);
begin
  Fmultiselect := Value;
end;

procedure TGl3dcontrolRadio.setStatusObjectList(
  value: array of TGLBaseSceneObject);
var i:integer;
begin
     setlength(statusobjects,length(value));
     for I := 0 to length(value) - 1 do
     begin
         statusobjects[i]:=value[i];
     end;
     refreshStatusObjectList;
end;

{ TGL3dControlCheck }

constructor TGL3dControlCheck.Create(AOwner: TComponent);
begin
  inherited;
  setlength(statusobjlist,0);
  fOnclick:=@click;
end;

destructor TGL3dControlCheck.Destroy;
begin
  if assigned(gltextf) then
     gltextf.destroy;
  inherited;
end;

procedure TGL3dControlCheck.fontrefresh;
begin
   if assigned(gltextf) then   
      gltextf.BitmapFont:=FBitmapFont;
end;

function TGL3dControlCheck.gettext: string;
begin
     result:='';
     if assigned(gltextf) then
        result:=gltextf.text;
end;


procedure TGL3dControlCheck.clearstatus;
var i:integer;
begin
     for i := 0 to length(statusobjlist) - 1 do
     begin
          if assigned(statusobjlist[i]) then
             TGLProxyObject(statusobjlist[i]).visible:=false;
     end;
end;


procedure TGL3dControlCheck.refresh;
var v:VInnerVector;
    va:Tvector3f;
begin
     inherited refresh;

     clearstatus;
     if ((length(statusobjlist)>fstatus) and assigned(statusobjlist[fstatus])) then
     begin
          with TGLProxyObject(statusobjlist[fstatus]) do
          begin
               visible:=true;
          end;
     end;
     refreshStatusObjList;
end;

procedure TGL3dControlCheck.refreshStatusObjList;
var i:integer;
    v:VInnerVector;
    va:Tvector3f;
begin
     for I := 0 to length(statusobjlist) - 1 do
     begin
         with TGLProxyObject(statusobjlist[i]) do
         begin
              v:=BoundBox;
              va:=getAbsoluteScale(self);
              position.SetPoint(
                   v[0][0]{+va[0]/2}+50+fpadding[0],
                   -v[0][1]{-va[1]/2}-50-fpadding[1],
                   v[0][2]{+va[2]/2)}+fpadding[2]); // oops this static but not problem :)
         end;
     end;

end;

procedure TGL3dControlCheck.setstatus(const Value: integer);
begin
  if fstatus>=length(statusobjlist) then fstatus:=length(statusobjlist)-1;
  if fstatus<0 then fstatus:=0;

  fstatus := Value;
  refresh;
end;

procedure TGL3dControlCheck.setStatusObjectList(
  value: array of TGLBaseSceneObject);
var i:integer;
    g:TGLBInertia;
    t:double;
//    v1:tvector3f;
//    v:VInnerVector;
//    va:Tvector3f;
begin
     destroyStatusObjList;
     setlength(statusobjlist,length(value));
     for I := 0 to length(value) - 1 do
     begin
         statusobjlist[i]:=TGLProxyObject(self.AddNewChild(TGLProxyObject));
         with TGLProxyObject(statusobjlist[i]) do
         begin
              MasterObject:=value[i];
              ProxyOptions:=[pooObjects,pooEffects];
              visible:=false;

//              v1:=getAbsoluteScale(self);
//              Scale.SetVector(v1[0]*10,v1[1]*10,v1[2]*10);
              Scale.SetVector(100,100,100);
              GetOrCreateBehaviour(TGLBInertia);
              behaviours[0].Assign(tglbinertia(value[i].GetOrCreateBehaviour(TGLBInertia)));
              GetOrCreateBehaviour(TGLmovement);
              behaviours[1].Assign(tglMovement(value[i].GetOrCreateBehaviour(tglMovement)));

//              v:=BoundBox;
//              va:=getAbsoluteScale(self);
//              position.SetPoint(v[0][0]+va[0]{/2}+fpadding[0],-v[0][1]-{va[1]/2}500-fpadding[1],(va[2]/10)+v[0][2]+fpadding[2]); // oops this static but not problem :)

         end;
     end;
end;

procedure TGL3dControlCheck.Settext(const Value: string);
var va:tvector3f;
begin
  if not assigned(gltextf) then
  begin
       if value<>'' then   // if empty and not created, then stay notcreated state
       begin
         gltextf:=TGLFlatText(self.AddNewChild(TGLFlattext));
         gltextf.Options:=[ftoTwoSided];
         gltextf.BitmapFont:=self.BitmapFont;
         gltextf.movedown;
         gltextf.movedown;
       end;
  end;
  if assigned(gltextf) then
  begin
    gltextf.ModulateColor:=self.fdefaultColor;
    gltextf.Scale.SetVector(c3dfontscale*fFontScale,c3dfontscale*fFontScale,c3dfontscale*fFontScale);
    fInnerBox:=Boundbox;
    va:=getAbsoluteScale(self);
    gltextf.Position.SetPoint(fInnerBox[0][0]+{va[0]}100+fpadding[0],-fInnerBox[0][1]-fpadding[1],(va[2]/10)+fInnerBox[0][2]+fpadding[2]);
    gltextf.Text:=value;
    refresh;
  end;
end;

{ TGl3dcontrolCombo }


constructor TGl3dcontrolGroup.Create(AOwner: TComponent);
var dd:tgldummycube;
    sw:TGLShadowPlane;
begin
  inherited;
  setlength(fControls,0);
  fAnimationStyle:=asCombo;
  fAnimationSpeed:=1;
  fcollapsed:=true;
  fParamsMatrix.shift:=vectorMake(10,3,0);
  fparamsMatrix.containposition:=vectormake(0,0,10);
//  fparamsMatrix.boxposition:=vectormake(-500,-600,-200);//vectormake(-500,-600,-200);
//  fparamsMatrix.boxscale:=vectormake(4,9,0.1);

{
  with TGLCube(self.AddNewChild(TGLCube)) do
  begin
       tag:=ControlDefaultBottom;
       visible:=true;
  end;
  sw:=TGLShadowPlane(self.AddNewChild(TGLShadowPlane));
  sw.ShadowColor.AsWinColor:=clltGray;
  with sw do
  begin
       tag:=ControlDefaultBack;
       visible:=true;
  end;
  with TGLCylinder(dummy.AddNewChild(TGLCylinder)) do
  begin
     up.setvector(1,0,0);
     tag:=ControlDefaultTop;
     visible:=true;
  end;
}
  contain:=TGlDummyCube(self.AddNewChild(TGlDummyCube));
  contain.Scale.SetVector(0,0,0);
//  sw.ShadowingObject:=contain;
end;

destructor TGl3dcontrolGroup.Destroy;
begin
  setlength(fControls,0);
  contain.Destroy;
  inherited;
end;


procedure TGl3dcontrolGroup.refresh;
var sw:TGLBaseSceneObject;
    v:tvector3f;
begin
  inherited;
{  clearMotion;
  v:=getAbsoluteScale(self);
  AddMotion(ControlDefaultTop   ,0,0,vectormake(0,0,0),vectormake(0,0,0),vectormake(0,0,0),40*v[0]);
//orig  AddMotion(ControlDefaultTop   ,0,1,vectormake(100,0,0),vectormake(30,1050,30),vectormake(0,0,0),400);
  AddMotion(ControlDefaultTop   ,0,1,vectormake(5*width*v[0],0,0),vectormake(30,10*width*v[0],30),vectormake(0,0,0),100*v[0]);

  AddMotion(ControlDefaultback  ,1,0,vectormake(0,0,0),vectormake(0,0,0),vectormake(0,0,0),40*v[0]);
//o  AddMotion(ControlDefaultback  ,1,1,vectormake(100,0,0),vectormake(900,10,10),vectormake(0,0,0),300);
//o  AddMotion(ControlDefaultBack  ,1,2,vectormake(100,-250,00),vectormake(1000,500,10),vectormake(0,0,0),400);
  AddMotion(ControlDefaultback  ,1,1,vectormake(5*width*v[0],0,0),vectormake(9*width*v[0],10,10),vectormake(0,0,0),40*v[0]);
  AddMotion(ControlDefaultBack  ,1,2,vectormake(5*width*v[0],-5*height*v[1],00),vectormake(10*width*v[0],10*height*v[1],10),vectormake(0,0,0),10*v[0]);

  AddMotion(ControlDefaultBottom,2,0,vectormake(0,0,0),vectormake(0,0,0),vectormake(0,0,0),40*v[0]);
  AddMotion(ControlDefaultBottom,2,1,vectormake(5*width*v[0],-1*height*v[1],0),vectormake(10*width*v[0],10,10),vectormake(0,0,0),40*v[0]);
  AddMotion(ControlDefaultBottom,2,2,vectormake(5*width*v[0],-10*height*v[1],0),vectormake(10*width*v[0],10,10),vectormake(0,0,0),70*v[0]);

  sw:=self.findObjectWithTag(ControlDefaultBack);
  if assigned(sw) and (sw is TGLShadowPlane) and assigned(form3d)then
  begin
     TGLShadowPlane(sw).ShadowedLight:=self.Form3d.light;
     TGLShadowPlane(sw).Style:=[];
     TGLShadowPlane(sw).Shadowoptions:=[];
  end;
}
end;


procedure TGl3dcontrolGroup.setAnimationMatrix(shift, containposition,
  boxposition, boxscale: tvector4f);
begin
     self.fParamsMatrix.shift:=shift;
     self.fParamsMatrix.containposition:=containposition;
     self.fParamsMatrix.boxposition:=boxposition;
     self.fParamsMatrix.boxscale:=boxscale;
     self.fAnimationStyle:=as2DMatrix;
end;

procedure TGl3dcontrolGroup.setAnimationMatrix(value: RMatrixParameter);
begin
     self.fParamsMatrix:=value;
     self.fAnimationStyle:=as2DMatrix;
end;

procedure TGl3dcontrolGroup.SetAnimationSpeed(const Value: double);
begin
  FAnimationSpeed := Value;
end;

procedure TGl3dcontrolGroup.SetAnimationStyle(const Value: TAnimationStyle);
begin
  FAnimationStyle := Value;
end;


procedure TGl3dcontrolGroup.SetCaption(const Value: TCaption);
begin
  FCaption := Value;
end;

procedure TGl3dcontrolGroup.SetCollectionWaitMs(const Value: integer);
begin
  FCollectionWaitMs := Value;
end;

function TGl3dcontrolGroup.add(control: TGl3dcontrolbase;
  referencepoint: TVector3f):TGl3dcontrolbase;
var r:pRBase;
begin
     setlength(fcontrols,length(fcontrols)+1);
     r:=@fcontrols[length(fcontrols)-1];
     r^.control:=control;
     control.Scale.SetVector(1,1,1); //scale  normal =1
     if Length(fcontrols)>1 then
     begin
          r^.pivot:=TGlDummyCube({self.}fcontrols[length(fcontrols)-2].pivot.AddNewChild(TGlDummyCube));
     end
     else
     begin
          r^.pivot:=TGlDummyCube(self.contain.AddNewChild(TGlDummyCube));
     end;
//     r.pivot.Scale.SetVector(1/control.scale.x,1/control.scale.y,1/control.scale.z);
//     r.pivot:=TGlDummyCube(self.AddNewChild(TGlDummyCube));
     r^.control.MoveTo(r^.pivot);
     r^.control.Position.AsAffineVector:=referencepoint;
     result:=r^.control;
end;

procedure TGl3dcontrolGroup.clear(newparent:TGLBaseSceneObject);
var i:integer;
begin
     for i := 0 to length(fcontrols) - 1 do
     begin
          if newparent=nil then
             fcontrols[i].control.Destroy
          else
             fcontrols[i].control.MoveTo(newparent);
          fcontrols[i].pivot.Destroy;
     end;
     setlength(fcontrols,0);
end;

procedure TGl3dcontrolGroup.collapse;
begin
     fcollapsed:=true;
end;

procedure TGl3dcontrolGroup.expand;
var i,a:integer;
    mov:TGLmovement;
    node:TGLPathnode;
    path:tglmovementpath;
    v:tvector3f;

const
    t9x9 : array[0..8,0..2] of double = (
      (-1,-1,0),(1,0,0),(1,0,0),
      (0,-1,0),(-1,0,0),(-1,0,0),
      (0,-1,0),(1,0,0),(1,0,0));

begin
     if not fcollapsed then
     begin
        collapse;
        exit;
     end;

     fcollapsed:=false;
     v:=getAbsoluteScale(self);

     case AnimationStyle of
     asCombo:
     begin
       for i := 0 to length(fControls) - 1 do
       begin
            if i>0 then
            begin
              mov:=tglmovement(fcontrols[i].pivot.GetOrCreateBehaviour(TGLmovement));
              path:=mov.AddPath;
              with path.AddNode do
              begin
                   PositionAsVector:=vectormake(0,0,0);
                   speed:=AnimationSpeed*vectorlength(v);
              end;
              with path.AddNode do
              begin
                   PositionAsVector:=vectormake(0,-100{*v[1]},0);
                   speed:=1*vectorlength(v);
              end;
              Form3d.addBehaviourEvent(fcontrols[i].pivot,TGLMovement,0,((i)*FCollectionWaitMs),nil); //first, nonext
            end;
       end;
     end;
     asFan:
     begin
       for i := 0 to length(fControls) - 1 do
       begin
            if i>0 then
            begin
              mov:=tglmovement(fcontrols[i].pivot.GetOrCreateBehaviour(TGLmovement));
              path:=mov.AddPath;
              with path.AddNode do
              begin
//                   PositionAsVector:=fcontrols[i].control.LocalToAbsolute(vectorMake(0,0,0));// vectormake(0,0,0);
//                   v[1]:=v[1]-1;
                   PositionAsVector:=vectormake(0,0,0);
                   speed:=AnimationSpeed*vectorlength(v);
              end;
              with path.AddNode do
              begin
//                   PositionAsVector:=v;//vectormake(0,-1,0);
//                   PositionAsVector:=vectormake(0,0,1*(1/v[2]));
                   PositionAsVector:=vectormake(0,0,1);
                   RollAngle:=20;
                   speed:=1*vectorlength(v);
              end;
              Form3d.addBehaviourEvent(fcontrols[i].pivot,TGLMovement,0,((i)*FCollectionWaitMs),nil); //first, nonext
            end;
       end;
     end;
     as2DMatrix:
     begin
//contain
       mov:=tglmovement(self.contain.GetOrCreateBehaviour(TGLmovement));
       path:=mov.AddPath;
       node:=path.AddNode;
       node.ScaleAsVector:=vectormake(0,0,0);
       node.PositionAsVector:=vectormake(0,0,0);
       node.speed:=1;
       node:=path.AddNode;
       node.PositionAsVector:=self.fParamsMatrix.containposition;
       node.ScaleAsVector:=vectormake(1,1,1);
       node.speed:=100;
       Form3d.addBehaviourEvent(self.contain,TGLMovement,0,100,nil);
{
//box
       mov:=tglmovement(self.dummy.GetOrCreateBehaviour(TGLmovement));
       path:=mov.AddPath;
       node:=path.AddNode;
       node.ScaleAsVector:=vectormake(1,1,1);
       node.PositionAsVector:=vectormake(0,0,0);
       node.speed:=500;
       node:=path.AddNode;
       node.PositionAsVector:=vectormake(fparamsMatrix.boxposition[0],1,fparamsMatrix.boxposition[2]);
       node.ScaleAsVector:=vectormake(fparamsMatrix.boxscale[0],1,fparamsMatrix.boxscale[2]);
       node.speed:=500;
       node:=path.AddNode;
       node.PositionAsVector:=self.fParamsMatrix.boxposition;
       node.ScaleAsVector:=fparamsMatrix.boxscale;
       node.speed:=500;
       Form3d.addBehaviourEvent(self.dummy,TGLMovement,0,000,nil);
}
{       self.Assignmotion(0);
       self.Assignmotion(1);
       self.Assignmotion(2);
}
       for i := 0 to length(fControls) - 1 do
       begin
//            fcontrols[i].pivot.Children[0].Visible  :=true;
            if i>0 then
            begin
              mov:=tglmovement(fcontrols[i].pivot.GetOrCreateBehaviour(TGLmovement));
              path:=mov.AddPath;
              node:=path.AddNode;
              node.PositionAsVector:=vectormake(0,0,0);
              fcontrols[i].pivot.Position.SetPoint(0,0,0);
              node.speed:=AnimationSpeed*vectorlength(v);

//              path:=mov.AddPath;
              node:=path.AddNode;
              node.PositionAsVector:=vectormake(
                       fParamsMatrix.shift[0]*t9x9[i][0]*{v[0]}100,
                       fParamsMatrix.shift[1]*t9x9[i][1]*{v[1]}100,
                       fParamsMatrix.shift[2]*t9x9[i][2]*{v[2]}100);
              node.speed:=5*AnimationSpeed*vectorlength(v);

              Form3d.addBehaviourEvent(fcontrols[i].pivot,TGLMovement,0,((i)*FCollectionWaitMs),nil); //first, nonext
            end;
       end;
     end;

     end; //case

end;


procedure TGl3dcontrolGroup.fontrefresh;
begin
//
end;



{ TGl3dcontrolCombo }

constructor TGl3dcontrolCombo.Create(AOwner: TComponent);
begin
  inherited;
  fitems:=Tstringlist.Create;
  clear;
end;

destructor TGl3dcontrolCombo.Destroy;
begin
     fitems.Destroy;
  inherited;
end;

procedure TGl3dcontrolCombo.SetDropDownCount(const Value: integer);
begin
  if value<>FDropDownCount then
  begin
    clear;
    createrows(value);
  end;
  FDropDownCount := Value;
end;

procedure TGl3dcontrolCombo.SetItems(const Value: TstringList);
begin
  FItems := Value;
end;

procedure TGl3dcontrolCombo.clear;
begin
     inherited clear(nil);
end;
procedure TGl3dcontrolCombo.setStatusObjectList(
  value: array of TGLBaseSceneObject);
var i:integer;
begin
     setlength(statusobjects,length(value));
     for I := 0 to length(value) - 1 do
     begin
         statusobjects[i]:=value[i];
     end;
     refreshStatusObjectList;
end;

procedure TGl3dcontrolCombo.refreshStatusObjectList;
var i:integer;
begin
     for i := 0 to length(fcontrols) - 1 do
     begin
          if fcontrols[i].control is TGl3dcontrolCheck then
          begin
               TGl3dcontrolCheck(fcontrols[i].control).setStatusObjectList(statusobjects);
          end;
     end;
end;

procedure TGl3dcontrolCombo.createrows(value:integer);
var i:integer;
    c:TGl3dcontrolCheck;
begin
     for i := 0 to value - 1 do
     begin
          c:=TGl3dcontrolCheck(add(TGl3dcontrolCheck(dummy.AddNewChild(TGl3dcontrolCheck)),affinevectormake(0,0,0)));
          c.FontColor.AsWinColor:=0;
          c.init(form3d,width,height,depth,bitmapfont,'Row '+inttostr(i));
          c.status:=1;
     end;
end;



begin
     ScaleBase[0]:=0.1;
     ScaleBase[1]:=0.1;
     ScaleBase[2]:=0.1;
end.




unit gl3dc20;

{$mode objfpc}{$H+}
{$define ANIDELAYED}

interface

uses
  Classes, SysUtils,Math,
  FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, inifiles,
  ctOpenGLES1xCanvas, ctOpenGLES2xCanvas, GLScene, GLObjects,
  GLVectorFileObjects, GLSLanguage, GLCameraController, GLImposter, GLCadencer,
  GLSmoothNavigator, GLSimpleNavigation, GLMaterial, GLMaterialEx, glColor, GLTexture,
  GLPhongShader, GLLCLViewer, BaseClasses, VectorGeometry,GeometryBB,
  GLRendercontextinfo,BGRABitmapTypes,BGRABitmap;

const
  SYS_SCALE = 0.01;
  MESH_CONTENT = 'CONTENT';

  BGRARed: TBGRAPixel = (blue: 0; green: 0; red: 255; alpha: 255);
  BGRAGreen: TBGRAPixel = (blue: 0; green: 255; red: 0; alpha: 255);
  BGRAYellow: TBGRAPixel = (blue: 0; green: 255; red: 255; alpha: 255);
  BGRABlue: TBGRAPixel = (blue: 255; green: 0; red: 0; alpha: 255);
  BGRABackground:TBGRAPixel = (blue: 1; green: 1; red: 1; alpha: 0);

  conX = -100;
  conY = -200;
type

  ESystemCreate = class of Exception;
  EControl = class of Exception;
  EScript = class of Exception;

  { TForm1 }

  TVoxel = TAffineVector;
  PVoxel = ^TVoxel;

  Astring = array of string;

  RAnime = record
    anistream: tmemorystream;
    filename: string[255];
  end;

  { TAnimodel }

  TAnimode = (animOnce, AnimFull, AnimStep);

  RAnimodelsection = record
    sectionname: string[100];   //pl> open
    Value: integer;        // 0,1
    ifrom: integer;  //firstframe
    ito: integer;    //lastframe
  end;

  RAnimodelobjects = record
    objname: string[100];
    objtype: string[100];
    objsize: TVoxel;
  end;

  TSystem = class;
  TUniverse = class;
  TGL3DControlClass = class;
  TGL3DControl = class;


  { TGLDrawPlane }

  TGLDrawPlane = class(TGLPlane)
  private
    Fcontentsize: TVoxel;
    fcurrentplaneindex: integer;
    Ffont: Tfont;
    FplaneDistance: single;
    Fplanesnum: integer;
    Fposition: TVoxel;
    Fsize: TVoxel;
    Ftext: string;
    pic:TBGRABitmap;



    procedure init(AOwner: TComponent; size: TPoint);
    procedure AssignBitmapToTexture;
    function  getcurrentplaneindex: integer;
    procedure Setcontentsize(AValue: TVoxel);
    procedure setcurrentplaneindex(AValue: integer);
    procedure Setfont(AValue: Tfont);
    procedure SetplaneDistance(AValue: single);
    procedure Setplanesnum(AValue: integer);
    procedure Settext(AValue: string);
    procedure fontChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;overload;
    constructor Create(AOwner: TComponent;size:TPoint); overload;
    constructor Create(AOwner: TComponent;size:TVoxel); overload;
    destructor Destroy; override;
    procedure buildlist(var rci: TRenderContextInfo); override;
    procedure StructureChanged; override;
    procedure DoProgress(const progressTime: TProgressTimes); override;
    function  getBitmap(planeindex:integer):TBGRABitmap;overload;
    function getBitmap: TBGRABitmap;overload;
    function  getPlane(planeindex:integer):TGLDrawPlane;overload;
    function  getPlane:TGLDrawPlane;overload;
    procedure refresh;

    property text : string read Ftext write Settext;
    property contentsize: TVoxel read Fcontentsize write Setcontentsize;
    property font:Tfont read Ffont write Setfont;

    property planesnum:integer read Fplanesnum write Setplanesnum;
    property planeDistance:single read FplaneDistance write SetplaneDistance;
    property currentplaneindex:integer read getcurrentplaneindex write setcurrentplaneindex;

  end;


  {Egy animáció betöltése BLENDER exportból}
  TAnimodel = class
    files: TStringList;
  private
    Fname: string;
    function EOF(Sender: TGL3DControl): boolean;
    procedure once(Sender: TGL3DControl);
    procedure Setname(AValue: string);
    function Next(Sender: TGL3DControl): boolean;
  public
    theme: string;
    {filename section:    slider_standard.gl3dc    name=slider,theme=standard}
    animes: array of RAnime;
    anisections: array of RAnimodelsection;
    aniobjects: array of RAnimodelobjects;
    materialnames:tstringlist;

    constructor Create(const _name: string; const modelfiles: string);
    destructor Destroy;
    function  Count: integer;
    procedure reset(var index: integer);

    procedure drawframe(Sender: TGL3DControl);
    procedure process(Sender: TGL3DControl);


    property Name: string read Fname write Setname;
  end;


  RAni = record
    animodelindex: integer;   //TAnimodels[index]
    animodel: Tanimodel;
    sectionindex: integer;    // selected section index
    startframe: integer;      //startframe
    endframe: integer;        //lastframe
    //frameindex:integer;      //actual frame

    Control_Voxel: TVoxel;            //Control parameters
    Control_SectionName: string[100];      //overload the initial parameter sectionname
    Control_SectionValue: integer;    //overload the initial parameter sectionvalue

    animodelname: string[100];             //reminder
    theme: string[100];
    sectionname: string[100];
    sectionvalue: integer;
  end;
  PAni = ^Rani;


  { TAnimodels }
  {Animációk tárolója
   hivatkozás:      animodels("name","open")
               name = az animáció elnevezése (a blender fájl nevével egyenértékű
               open = egy animációs részlet melyet a Blender markerek jeleznek}
  TAnimodels = class
  private
    FlistOfAnimodels: TList;
    function indexOfSection(index: integer; sectionname: string;
      sectionvalue: integer): integer;
    procedure SetlistOfAnimodels(AValue: TList);
  public
    constructor Create;
    destructor Destroy;
    procedure clearlist;
    procedure add(Value: TAnimodel);
    function indexOf(index: integer): TAnimodel;
    function indexOf(Name, theme: string): integer;
    function indexOf(Name, theme: string; var index: integer): TAnimodel;
    property listOfAnimodels: TList read FlistOfAnimodels write SetlistOfAnimodels;
    function animodel(Name: string; theme: string; sectionname: string;
      sectionvalue: integer): PAni;  //slider,standard,open,2
  end;



  { TMultiverse }

  TMultiverse = class
  private
    dummy: TGLDummyCube;
    Fanimodels: TAnimodels;
    FlistOfControlClass: TList;
    //lehetséges controllok listája. Ezek lehetőségek. Konkrétan a használat a Systemben
    FlistOfSystem: TList;         //létrehozott rendszerek
    FlistOfUniverse: TList;       //létrehozott univerzumok
    procedure Setanimodels(AValue: TAnimodels);
    procedure SetlistOfControlClass(AValue: TList);
    procedure SetlistOfSystem(AValue: TList);
    procedure SetlistOfUniverse(AValue: TList);
  public
    constructor Create(_parent: TGLDummycube);
    destructor Destroy;
    function addUniverse: TUniverse;
    function addSystem(_parent: TUniverse): TSystem;
    {Addsystem parent=nil == listOfUniverse[0]}
    function addControlClass(parentcontrol: TGL3DControlClass): TGL3DControlClass;
    function findControlClass(controlname: string): TGL3DControlClass;
    function findControlClassIndex(controlname: string): integer;

    function Universe(index: integer = 0): TUniverse;
    function System(index: integer = 0): TSystem;
    procedure loadanimodelsfromscriptfile(filename:string='');

    procedure process;

    property listOfUniverse: TList read FlistOfUniverse write SetlistOfUniverse;
    property listOfSystem: TList read FlistOfSystem write SetlistOfSystem;
    property listOfControlClass: TList read FlistOfControlClass
      write SetlistOfControlClass;
    property animodels: TAnimodels read Fanimodels write Setanimodels;


  end;


  { TUniverse }

  TUniverse = class
  private
    parent: TMultiverse;
    dummy: TGLDummyCube;
  public
    constructor Create(_parent: TMultiverse);
    destructor Destroy;
    procedure addSystem;
  end;

  { TSystem }
  TSystem = class
  private
    dummy: TGLDummyCube;
    FlistOfControl: TList; //TGL3DControl
    FlistOfParent: TList;
    procedure SetlistOfControl(AValue: TList);
    procedure SetlistOfParent(AValue: TList);
  public
    constructor Create(parent: TUniverse);
    destructor Destroy;
    function add(controlname: string): TGL3DControl;
    function Universe: TUniverse;
  published

    property listOfControl: TList read FlistOfControl write SetlistOfControl;
    property listOfParentUniverse: TList read FlistOfParent write SetlistOfParent;
  public
    procedure process;
  end;


  { TGL3DControlClass }
  TGL3DControlClass = class
  private
    Fname: string;
    procedure Setname(AValue: string);

  protected
    coreAnimodelIndex: integer;
    AnicontentList: TList; //RAni

  public
    mode: TAnimode;
    parent: TGL3DControlClass;

    constructor Create(parentcontrol: TGL3DControlClass);
    destructor Destroy;
    procedure clearAnicontentList;
    function Add(newsectionname: string; newsectionvalue: integer;
      Voxel: TAffineVector; animodel: PAni): PAni; overload;
    function Add(Voxel: TAffineVector; animodel: PAni): PAni; overload;
    function Add(animodel: PAni): PAni; overload;
    function indexOf(Value: integer): PAni;
    function find(sectionname: string; sectionvalue: integer): PAni;
    function Count: integer;

    property Name: string read Fname write Setname;
  end;


  TControlInfo = class

    Voxel: TVoxel;
  end;

  AUserMaterial = record
    materialname:string;
    filename:string;
    data:Tmemorystream;
  end;
  PUserMaterial=^AUserMaterial;
  { TUsermaterials }

  TUsermaterials = class
  private
     function indexOf(materialname:string):integer;
  public
     items:Tlist;
     constructor create;
     destructor destroy;
     function getMaterialByName(materialname:string):PUserMaterial;
     procedure add(materialname:string;filename:string);
     function delete(materialname:string):boolean;
     procedure clear;
  end;


  TGL3DControl = class
  private
    FAnimation: PAni;
    fDummycontent:TGLDummyCube;
    fDummy:TGLDummyCube;
    fuserMaterials:TUserMaterials;

    Fanimationrun: boolean;
    Fcontentsize: TVoxel;
    FControlClass: TGL3DControlClass;
    Fframeindex: integer;
    Fmode: TAnimode;
    Fname: string;
    Fparent: TGL3DControl;
    FparentSystem: TSystem;
    Fposition: TVoxel;
    FsimpleBackgroundFile: string;
    FsimpleBackgroundRadius: single;
    Fsize: TVoxel;
    fCanvas:TGLDrawplane;

    function getCanvas: TGLDrawplane;
    function getDummy: TGLDummycube;
    function getDummycontent: TGLDummycube;
    procedure positionRefresh(AValue: TVoxel);
    procedure Setanimationrun(AValue: boolean);
    procedure Setcontentsize(AValue: TVoxel);
    procedure SetControlClass(AValue: TGL3DControlClass);
    procedure setDummy(AValue: TGLDummycube);
    procedure Setframeindex(AValue: integer);
    procedure Setmode(AValue: TAnimode);
    procedure Setname(AValue: string);
    procedure Setparent(AValue: TGL3DControl);
    procedure SetparentSystem(AValue: TSystem);
    procedure Setposition(AValue: TVoxel);
    procedure SetsimpleBackgroundFile(AValue: string);
    procedure SetsimpleBackgroundRadius(AValue: single);
    procedure Setsize(AValue: TVoxel);
    procedure SetAnimation(AValue: PAni);

  public


    //Voxel: TVoxel;
    constructor Create(_ControlClass: TGL3DControlClass);
    destructor Destroy;
    procedure action(section: string; Value: integer; animode: TAnimode);
    procedure show;
    procedure hide;
    procedure process;
    procedure AddCanvas(Planenum:integer=1;planedistance:double=0.02);
    function  materialnames:tstringlist;
    procedure loadmaterialfromfile(materialname,filename:string);

    property size: TVoxel read Fsize write Setsize;
    property contentsize: TVoxel read Fcontentsize write Setcontentsize;
    property position: TVoxel read Fposition write Setposition;
    property Animation: PAni read FAnimation write SetAnimation;
  published
    property ControlClass: TGL3DControlClass read FControlClass write SetControlClass;
    property Name: string read Fname write Setname;
    property parent: TGL3DControl read Fparent write Setparent;
    property parentSystem: TSystem read FparentSystem write SetparentSystem;
    property simpleBackgroundFile: string read FsimpleBackgroundFile
      write SetsimpleBackgroundFile;
    property simpleBackgroundRadius: single
      read FsimpleBackgroundRadius write SetsimpleBackgroundRadius;
    property mode: TAnimode read Fmode write Setmode;
    property frameindex: integer read Fframeindex write Setframeindex;
    property animationrun:boolean read Fanimationrun write Setanimationrun;
    property Dummycontent:TGLDummycube read getDummycontent;
    property Dummy: TGLDummycube read getDummy write setDummy;
    property Canvas:TGLDrawplane read getCanvas;
    //actual frame
  end;


  { TGL3DControls }
  TGL3DControls = class
  private
    FlistOfControl: TList;
    procedure SetlistOfControl(AValue: TList);

  public
    constructor Create;
    destructor Destroy;
    function add(control: TGL3DControlClass): integer;
    property listOfControl: TList read FlistOfControl write SetlistOfControl;
  end;


function findFreeform(parent: TGLDummyCube): TGLFreeform;
procedure minVector(var v1:TVoxel;vmin:TVoxel);
procedure maxVector(var v1:TVoxel;vmax:TVoxel);
implementation

{ TUsermaterials }

function TUsermaterials.indexOf(materialname: string): integer;
var
  i: Integer;
begin
     result:=-1;
     for i:=0 to items.count -1 do
     begin
       if PUserMaterial(items[i])^.materialname=materialname then
       begin
         result:=i;
         exit;
       end;
     end;
end;

constructor TUsermaterials.create;
begin
     items:=tlist.Create;
end;

destructor TUsermaterials.destroy;
begin
     clear;
     items.Destroy;
end;

function TUsermaterials.getMaterialByName(materialname: string): PUserMaterial;
var c:integer;
begin
     c:=indexOf(materialname);
     if c<0 then
        result:=nil
     else
        result:=items[c];
end;

procedure TUsermaterials.add(materialname: string; filename: string);
var c:integer;
    mat:pusermaterial;
begin
     c:=indexOf(materialname);
     if c=-1 then
     begin
        getmem(mat,sizeof(AUserMaterial));
        items.Add(mat);
     end
     else
     begin
       mat:=pusermaterial(items[c]);
       if assigned(mat^.data) then
          mat^.data.Destroy;
     end;
     mat^.materialname:=materialname;
     mat^.filename:=filename;
     mat^.data:=Tmemorystream.Create;
     if fileexists(filename) then
        mat^.data.LoadFromFile(filename);
end;

function TUsermaterials.delete(materialname: string): boolean;
var c:integer;
begin
     result:=true;
     c:=indexOf(materialname);
     if c>-1 then
     begin
          result:=false;
          if assigned(PUsermaterial(items[c])^.data) then
          begin
             pUserMaterial(items[c])^.data.Destroy;
             freemem(items[c]);
             items.Delete(c);
             result:=true;
          end;
     end;
end;

procedure TUsermaterials.clear;
var
  i: Integer;
begin
     for i:=0 to items.Count-1 do
     begin
       if assigned(pUserMaterial(items[i])^.data) then
         pUserMaterial(items[i])^.data.Destroy;
       freemem(items[i]);
       items[i]:=nil;
     end;
     items.Clear;
end;

procedure TGL3DControl.SetAnimation(AValue: PAni);
begin
  if FAnimation = AValue then
    Exit;
  FAnimation := AValue;
end;

procedure TGL3DControl.SetControlClass(AValue: TGL3DControlClass);
begin
  if FControlClass = AValue then
    Exit;
  FControlClass := AValue;
end;

procedure TGL3DControl.setDummy(AValue: TGLDummycube);
begin
     fdummy:=avalue;
     if ((fdummy<>nil ) and (fdummycontent=nil)) then
     begin
          fdummycontent:=TGLDummyCube(fdummy.AddNewChild(TGLDummyCube));
     end;
end;

procedure TGL3DControl.Setanimationrun(AValue: boolean);
begin
  if Fanimationrun=AValue then Exit;
  Fanimationrun:=AValue;
end;


procedure TGL3DControl.Setframeindex(AValue: integer);
begin
  if Fframeindex = AValue then
    Exit;
  Fframeindex := AValue;
end;

procedure TGL3DControl.Setmode(AValue: TAnimode);
begin
  if Fmode = AValue then
    Exit;
  Fmode := AValue;
end;

procedure TGL3DControl.Setname(AValue: string);
begin
  if Fname = AValue then
    Exit;
  Fname := AValue;
end;

procedure TGL3DControl.Setparent(AValue: TGL3DControl);
begin
  if Fparent = AValue then
    Exit;
  Fparent := AValue;
  if parent<>nil then
  begin
       dummy.Parent:=parent.dummy;
  end;
  //dummy := TGLDummyCube(parent.dummy.AddNewChild(TGLDummyCube));

end;

procedure TGL3DControl.SetparentSystem(AValue: TSystem);
begin
  if FparentSystem = AValue then
    Exit;
  FparentSystem := AValue;
end;


procedure TGL3DControl.positionRefresh(AValue: TVoxel);

  function getcontent(dmy:TGLDummycube):TMeshObject;
  var freeform:TGLFreeform;
  begin
    result:=nil;
    freeform := findFreeform(dmy);
    if freeform<>nil then
    begin
      result:=freeform.MeshObjects.FindMeshByName(MESH_CONTENT); //felettes contentje
    end
  end;


var
  v,v2:TAABB;
  obj,obj2:TMeshObject;
  meret,meret2,meret3,voxel1,p1:TVoxel;
  z:double;
  conZ:integer;
begin
  if parent <> nil then
  begin
       obj:=getcontent(parent.Dummy);
       obj2:=getcontent(Dummy);
       if obj <> nil then
       begin
            obj.GetExtents(v);
            meret:=vectorsubtract(v.max,v.min);
//            maxvector(meret,affinevectormake(1,1,1));
            voxel1:=vectordivide(meret,parent.Fcontentsize);

            conZ:=round(parent.Fcontentsize[2]);
            case conZ of
               conX: voxel1[2]:=voxel1[0];
               conY: voxel1[2]:=voxel1[1];
            end;

            dummy.scale.AsAffineVector:=vectorscale(voxel1,self.fsize);

            z:=0;
            if obj2<>nil then
            begin
              obj2.GetExtents(v2);
              meret2:=vectorsubtract(v2.max,v2.min);
//              maxvector(meret2,affinevectormake(1,1,1));
              z:=meret[2]+(2*(meret2[2]*dummy.scale.AsAffineVector[2]));/// Why >:((( 2x
            end;

            p1:=vectorscale(voxel1,Avalue);
            p1[0]:=v.min[0]+p1[0];
            p1[1]:=v.max[1]-p1[1];
            p1[2]:=v.min[2]+p1[2]+z;
            dummy.position.AsAffineVector:=p1;

       end;
  end
  else
  begin
      dummy.position.AsAffineVector:=vectorscale(avalue,SYS_SCALE);
      dummy.scale.AsAffineVector:=vectorscale(fsize,SYS_SCALE);
  end;

end;

procedure TGL3DControl.Setposition(AValue: TVoxel);
begin
  if vectorequals(avalue,FPosition) then
    Exit;
  Fposition := AValue;
  positionrefresh(AValue);
end;
procedure TGL3DControl.Setsize(AValue: TVoxel);
begin
  if vectorequals(avalue,fsize) then
    Exit;
  Fsize := AValue;
  positionrefresh(fposition);
  //dummy.Scale.AddScaledVector(SYS_SCALE,avalue);
end;
procedure TGL3DControl.Setcontentsize(AValue: TVoxel);
begin
  if vectorequals(avalue,fcontentsize) then
     Exit;
  AValue[0]:=abs(Avalue[0]);
  AValue[1]:=abs(Avalue[1]);
  // Z lehet minus ConX , ConY
  Fcontentsize:=AValue;
end;

procedure TGL3DControl.SetsimpleBackgroundFile(AValue: string);
var
  b: tglBaseSceneobject;
begin
  if FsimpleBackgroundFile = AValue then
    Exit;
  FsimpleBackgroundFile := AValue;
  b := dummy.FindChild('simplebackground', False);
  if AValue = '' then
  begin
    if b <> nil then
      b.Destroy;
  end
  else
  begin
    if b <> nil then
    begin
      if b is TGLSphere then
      begin
        TGLSphere(b).material.texture.Image.LoadFromFile(avalue);
      end;
    end
    else
    begin
      with TGLSphere(dummy.AddNewChild(TGLSphere)) do
      begin
        material.texture.Image.LoadFromFile(avalue);
        material.Texture.Disabled := False;
      end;
    end;
  end;

end;

procedure TGL3DControl.SetsimpleBackgroundRadius(AValue: single);
var
  b: tglBaseSceneobject;
begin
  if FsimpleBackgroundRadius = AValue then
    Exit;
  FsimpleBackgroundRadius := AValue;
  b := dummy.FindChild('simplebackground', False);
  if b = nil then
    exit;
  if not (b is TGLSphere) then
    exit;
  TGLSphere(b).Radius := avalue;
end;


constructor TGL3DControl.Create(_ControlClass: TGL3DControlClass);
begin
  self.FControlClass := _controlclass;
  animation := nil;
  parent:=nil;
  setvector(fsize,100,100,100);
  setvector(fcontentsize,640,640,640);
  fcanvas:=nil;
  fuserMaterials:=TUserMaterials.Create;
end;

destructor TGL3DControl.Destroy;
begin

     if assigned(dummycontent) then
        dummycontent.Destroy;
     if assigned(dummy) then
        dummy.Destroy;
     fuserMaterials.destroy;

end;

procedure TGL3DControl.action(section: string; Value: integer; animode: TAnimode);
var
  p: PAni;
begin
  p := self.FControlClass.find(section, Value);
  if p <> nil then
  begin
    self.SetAnimation(nil);
    self.mode := animode;
    self.frameindex := p^.startframe;
    self.Animation := p; // ...all settings set before!! (frameindex,mode...)
    self.animationrun:=true;
  end
  else
  begin
    self.animation := nil;
    raise EControl.Create('No animation section/value!');
  end;
end;

procedure TGL3DControl.show;
begin
     action('show',1,animOnce);
end;

procedure TGL3DControl.hide;
begin
  action('show',0,animOnce);
end;


function TGL3DControl.getDummycontent: TGLDummycube;
var freeform:TGLFreeform;
  v:TAABB;
  obj:TMeshObject;
  i:integer;
begin
  //saját
      freeform := findFreeform(dummy);
      if freeform<>nil then
      begin
        obj:=freeform.MeshObjects.FindMeshByName(MESH_CONTENT); //saját content
        if obj <> nil then
        begin
           obj.GetExtents(v);//sajat coord
           fdummycontent.position.AsAffineVector:=v.min;
           i:=obj.Normals.Count;
        end;
      end;
      result := fdummycontent;
end;

function TGL3DControl.getDummy: TGLDummycube;
begin
  result:=fdummy;
end;

function TGL3DControl.getCanvas: TGLDrawplane;
begin
     result:=nil;
     if assigned(fcanvas) then
        result:=fcanvas.getPlane;
end;


procedure TGL3DControl.process;
begin
  if animation <> nil then
  begin
    animation^.animodel.process(self);
    getDummyContent;
//felettes miatt
    positionrefresh(fposition);
  end;
end;

procedure TGL3DControl.AddCanvas(Planenum: integer; planedistance: double);
begin
  if assigned(fcanvas) then
  begin
       freeandnil(fcanvas);
  end;

  fcanvas:=TGLDrawPlane.create(nil,self.contentsize);
  Dummycontent.AddChild(fcanvas);
  fcanvas.Position.AsAffineVector:=affinevectormake(0.5,0.5,0.5);

end;

function TGL3DControl.materialnames: tstringlist;
begin
  result:=self.Animation^.animodel.materialnames;
end;

procedure TGL3DControl.loadmaterialfromfile(materialname, filename: string);
begin

end;

{ TGL3DControls }

procedure TGL3DControls.SetlistOfControl(AValue: TList);
begin
  if FlistOfControl = AValue then
    Exit;
  FlistOfControl := AValue;
end;

constructor TGL3DControls.Create;
begin
  FlistOfControl := TList.Create;

end;

destructor TGL3DControls.Destroy;
begin
  FlistOfControl.Destroy;
end;

function TGL3DControls.add(control: TGL3DControlClass): integer;
begin
  Result := -1; //error
  if control = nil then
    exit;
  self.listOfControl.Add(control);
  Result := self.listOfControl.Count - 1;
end;

{ TUniverse }


constructor TUniverse.Create(_parent: TMultiverse);
var
  p: TGLSphere;
begin
  parent := _parent;
  dummy := TGLDummyCube(parent.dummy.AddNewChild(TGLDummyCube));
  p := TGLSphere(dummy.AddNewChild(TGLSphere));
  p.Name:='universe_jpg';
  p.NormalDirection := ndInside;
  p.material.Texture.Image.LoadFromFile('universe.jpg');
  p.Material.texture.Disabled := False;
  p.Radius := 50;
  p.Visible:=false;
end;

destructor TUniverse.Destroy;
begin

end;

procedure TUniverse.addSystem;
begin
  parent.addSystem(self);
end;

{ TMultiverse }

procedure TMultiverse.SetlistOfUniverse(AValue: TList);
begin
  if FlistOfUniverse = AValue then
    Exit;
  FlistOfUniverse := AValue;
end;

procedure TMultiverse.SetlistOfSystem(AValue: TList);
begin
  if FlistOfSystem = AValue then
    Exit;
  FlistOfSystem := AValue;
end;

procedure TMultiverse.SetlistOfControlClass(AValue: TList);
begin
  if FlistOfControlClass = AValue then
    Exit;
  FlistOfControlClass := AValue;
end;

procedure TMultiverse.Setanimodels(AValue: TAnimodels);
begin
  if Fanimodels = AValue then
    Exit;
  Fanimodels := AValue;
end;

constructor TMultiverse.Create(_parent: TGLDummyCube);
begin
  FlistOfSystem := TList.Create;
  FlistOfUniverse := TList.Create;
  FlistOfControlClass := TList.Create;
  animodels := Tanimodels.Create;
  dummy := _parent;
end;

destructor TMultiverse.Destroy;
begin
  FlistOfSystem.Destroy;
  FlistOfUniverse.Destroy;
  FlistOfControlClass.Destroy;
  animodels.Destroy;
end;

function TMultiverse.addUniverse: TUniverse;
begin
  Result := TUniverse.Create(self);
  listOfUniverse.Add(Result);
end;

function TMultiverse.addSystem(_parent: TUniverse): TSystem;
begin
  Result := nil;
  if _parent = nil then
  begin
    if listOfUniverse.Count > 0 then
    begin
      _parent := TUniverse(listOfUniverse[0]);
    end;
  end;
  if _parent <> nil then
  begin
    Result := Tsystem.Create(_parent);
    listOfSystem.Add(Result);
  end;
end;

function TMultiverse.addControlClass(parentcontrol: TGL3DControlClass):
TGL3DControlClass;
begin
  Result := TGL3DControlClass.Create(parentcontrol);
  self.listOfControlClass.Add(Result);
end;

function TMultiverse.findControlClass(controlname: string): TGL3DControlClass;
var
  i: integer;
begin
  Result := nil;
  if controlname = '' then
    exit;
  i := findControlClassIndex(controlname);
  if i > -1 then
    Result := TGL3DControlClass(self.listOfControlClass[i]);
end;

function TMultiverse.findControlClassIndex(controlname: string): integer;
var
  i: integer;
begin
  Result := -1;
  if controlname = '' then
    exit;
  controlname := lowercase(controlname);

  for i := 0 to self.listOfControlClass.Count - 1 do
  begin
    if TGL3DControlClass(self.listOfControlClass[i]).Name = controlname then
    begin
      Result := i;
    end;
  end;
end;

function TMultiverse.Universe(index: integer): TUniverse;
begin
  Result := nil;
  if listOfUniverse.Count > index then
    Result := TUniverse(listOfUniverse[index]);
end;

function TMultiverse.System(index: integer): TSystem;
begin
  Result := nil;
  if listOfSystem.Count > index then
    Result := TSystem(listOfSystem[index]);
end;

procedure TMultiverse.loadanimodelsfromscriptfile(filename: string='');
type
    tstat = (stNone,stAniModels,stControlclass);
    tt = array of string;
var f:TStringlist;
    state:tstat;
var n:TGL3DControlClass;

    procedure _AddAnimodel(pname,pvalue:string);
    begin
      animodels.add(Tanimodel.create(pname,pvalue));
    end;

    procedure _addcontrolclass(pname:string);
    begin
      n:=addControlClass(nil);
      n.name:=pname;
    end;
    procedure _addcontrolclassElement(pname,ptheme,pmark,pmarkvalue:string);
    begin
      if assigned(n) then
         n.Add( animodels.animodel(pname,ptheme,pmark,strtointdef(pmarkvalue,0)) )
      else
          raise EScript.create('Error in script Controlclass section!');
    end;

procedure aniprocess;
var i,c:integer;
  sor:string;
  name,value:string;
  t:tt;

          function prepare:string;
          begin
               result:=lowercase(trim(f[i]));
          end;
          function getpart(b:char;psor:string):tt;
          var s:string;
              j:integer;
          begin
               psor:=trim(psor);
               s:='';
               setlength(result,0);
               for j:=1 to length(psor) do
               begin
                    if psor[j]<>',' then
                       s:=s+psor[j]
                    else
                    begin
                       setlength(result,length(result)+1);
                       result[length(result)-1]:=s;
                       s:='';
                    end;
               end;
               if s<>'' then
               begin
                       setlength(result,length(result)+1);
                       result[length(result)-1]:=s;
               end;
          end;

begin
     state:=stNone;
     for i:=0 to f.Count-1 do
     begin
          if f[i]<>'' then
          begin
               sor:=prepare();
               if pos(')',sor)<1 then
                 case state of
                 stNone:
                 begin
                      if ((pos('animodels',sor)>0) and (pos('(',sor)>0)) then
                         state:=stAnimodels;
                      if pos('controlclass',sor)>0 then
                      begin
                         delete(sor,1,length('controlclass'));
                         if pos('(',sor)>0 then
                         begin
                              name:=trim(copy(sor,1,pos('(',sor)-1));
                              state:=stControlClass;
                              _addcontrolclass(name);
                         end;
                      end;
                 end;
                 stAniModels:
                 begin
                      c:=pos('=',sor);
                      if c>0 then
                      begin
                           name:=trim(copy(sor,1,c-1));
                           value:=trim(copy(sor,c+1,99999));
                           if ((name<>'') and (value<>'')) then
                           begin
                                _AddAnimodel(name,value);
                           end;
                      end;
                 end;
                 stControlclass:
                 begin
                   c:=pos('=',sor);
                   if c>0 then
                   begin
                        value:=trim(copy(sor,1,c-1));
                        delete(sor,1,c);
                        t:=getpart(',',sor);
                        if length(t)=3 then
                        begin
                             _addcontrolclassElement(value,t[0],t[1],t[2]);
                        end;
                   end;
                 end;
               end
               else
               begin
                    state:=stNone;
               end;
          end;
     end;
end;

begin
     if filename = '' then
     begin
          filename:='default.gl3dcscript';
          //create default script file
          if not fileexists(filename) then
          begin
            f:=TStringlist.Create;// tfilestream.Create('default.gl3dcscript',fmCreate);
            f.Add('animodels (                                                             ');
            f.add('slider = blend\slider\slider%.gl3dc                                       ');
            f.add('window = blend\window\window%.gl3dc                                          ');
            f.add('knot = blend\knot\knot%.gl3dc                                          ');
            f.add(')                                                                       ');
            f.add('controlclass slider (                                                   ');
            f.add('slider = ,open,1                                               ');
            f.add('slider = ,open,0                                               ');
            f.add('slider = ,show,1                                               ');
            f.add('slider = ,show,0                                               ');
            f.add('...                                                                     ');
            f.add(')                                                                       ');
            f.add('controlclass window (                                                    ');
            f.add('window = ,open,1                                               ');
            f.add('window = ,open,0                                               ');
            f.add('window = ,show,1                                               ');
            f.add('window = ,show,0                                               ');
            f.add(')                                                                       ');
            f.add('controlclass knot (                                                    ');
            f.add('knot = ,open,1                                               ');
            f.add('knot = ,open,0                                               ');
            f.add('knot = ,show,1                                               ');
            f.add('knot = ,show,0                                               ');
            f.add(')                                                                       ');
            filename:='default.gl3dcscript';
            f.SaveToFile('default.gl3dcscript');
            f.destroy;
          end;
     end;
     f:=TStringlist.Create;// tfilestream.Create('default.gl3dcscript',fmCreate);
     f.LoadFromFile(filename);
     aniprocess;
     f.Destroy;
end;

procedure TMultiverse.process;
var
  i: integer;
begin
  for i := 0 to self.listOfSystem.Count - 1 do
  begin
    TSystem(self.listOfSystem[i]).process();
  end;
end;

procedure TSystem.SetlistOfControl(AValue: TList);
begin
  if FlistOfControl = AValue then
    Exit;
  FlistOfControl := AValue;
end;

procedure TSystem.SetlistOfParent(AValue: TList);
begin
  if FlistOfParent = AValue then
    Exit;
  FlistOfParent := AValue;
end;

constructor TSystem.Create(parent: TUniverse);
var
  p: TGLSphere;
begin
  FlistOfControl := TList.Create;
  FlistOfParent := TList.Create;

  if parent = nil then
    raise ESystemCreate.Create('No Parent Universe!');

  listOfParentUniverse.Add(parent);
  dummy := TGLDummyCube(parent.dummy.AddNewChild(TGLDummyCube));
  {
  p:=TGLSphere(dummy.AddNewChild(TGLSphere));
  p.NormalDirection:=ndOutside;
  p.material.Texture.Image.LoadFromFile('system.jpg');
  p.Material.texture.Disabled:=false;
  p.Radius:=10;
   }
end;

destructor TSystem.Destroy;
begin
  FlistOfControl.Destroy;
  FlistOfParent.Destroy;
end;

function TSystem.add(controlname: string): TGL3DControl;
var
  c: TGL3DControlClass;
  i: integer;
begin
  Result := nil;
  c := TUniverse(listOfParentUniverse[0]).parent.findControlClass(controlname);
  if c <> nil then
  begin
    Result := TGL3DControl.Create(c);
    Result.dummy := TGLDummyCube(dummy.AddNewChild(TGLDummyCube));
    Result.parentSystem := self;
    listofControl.Add(Result);
  end;
end;

function TSystem.Universe: TUniverse;
begin
  Result := nil;
  if listOfParentUniverse.Count > 0 then
    Result := TUniverse(listOfParentUniverse[0]);
end;

procedure TSystem.process;
var
  i: integer;
begin
  for i := 0 to self.listOfControl.Count - 1 do
  begin
    TGL3DControl(self.listOfControl[i]).process;
  end;

{     for i:=0 to listOfAnimodels.Count-1 do
     begin
          if assigned(listOfAnimodels[i]) then
             TAniModel(listOfAnimodels[i]).process();
     end;}
end;



function CreateMemoryStream(filename: string): tmemorystream;
begin
  Result := tmemorystream.Create;
  Result.LoadFromFile(filename);
end;

function Voxel(x, y, z: single): Tvoxel;
begin
  Result[0] := x;
  Result[1] := y;
  Result[2] := z;
end;

function split(splitchar: char; s: string; len: integer = -1): Astring;
var
  i, c: integer;
begin
  i := 1;
  c := pos(splitchar, s);
  while c > 0 do
  begin
    setlength(Result, i);
    Result[length(Result) - 1] := copy(s, 1, c - 1);
    Delete(s, 1, c);
    c := pos(splitchar, s);
    Inc(i);
  end;
  if length(s) > 0 then
  begin
    setlength(Result, i);
    Result[length(Result) - 1] := s;
  end;
  if len > -1 then
  begin
    setlength(Result, len);
  end;
end;


{ TAnimodel }
constructor TAnimodel.Create(const _name: string; const modelfiles: string);
var
  i, j, c,c1,c2: integer;
  Info: TSearchRec;
  s: string;
  fname2: string;
  ast1, ast2: AString;

  ini: TInifile;
  section: TStringList;
  obj: TStringList;

  procedure themaselect(mf,sign:string);
  begin
    c1:=pos('_',mf);
    c2:=pos(sign,mf);
    if ((c1>0) and (c1<c2)) then
    begin
         theme:=copy(mf,c1+1,c2-c1-1);
    end;
  end;

begin
  materialnames:=tstringlist.Create;
  Name := _name;
  //  changeparent(_parent);
  files := TStringList.Create;
  if pos('*.', modelfiles) > 0 then //one fielname with asterix
  begin
    themaselect(modelfiles,'*.');
    if findfirst(modelfiles, faAnyFile, info) = 0 then
    begin
      repeat
        s := info.Name;
        setlength(animes, length(animes) + 1);
        animes[length(animes) - 1].anistream := CreateMemoryStream(s);
        animes[length(animes) - 1].filename := changefileext(s, '.3ds');
      until FindNext(info) <> 0;
      FindClose(Info);
    end;
  end
  else
  if pos('%.', modelfiles) > 0 then
    //one fieldname with number  % = 1 2 3 4 .... 9 10 11 ... 99 100 ...
  begin
    themaselect(modelfiles,'%.');
    i := 1;
    fname2 := stringreplace(modelfiles, '%.', '1.', [rfReplaceAll, rfIgnoreCase]);
    while fileexists(fname2) do
    begin
      s := fname2;
      setlength(animes, length(animes) + 1);
      animes[length(animes) - 1].anistream := CreateMemoryStream(s);
      animes[length(animes) - 1].filename := changefileext(s, '.3ds');

      Inc(i);
      fname2 := stringreplace(modelfiles, '%.', IntToStr(i) + '.',
        [rfReplaceAll, rfIgnoreCase]);
    end;
  end
  else
  begin
    files.Delimiter := ',';
    files.DelimitedText := modelfiles;
    setlength(animes, files.Count);
    for i := 0 to files.Count - 1 do
    begin
      s := files[i];
      themaselect(s,'.');
      animes[i].anistream := CreateMemoryStream(s);
      animes[i].filename := changefileext(s, '.3ds');
    end;
  end;

  //load initial file to section
  s := changefileext(modelfiles, '.gl3dcini');
  s := stringreplace(s, '*', '', [rfReplaceAll]);
  s := stringreplace(s, '%', '', [rfReplaceAll]);
  ini := TInifile.Create(s);

  //ANISECTIONS
  section := TStringList.Create;
  ini.ReadSection('Markers', section);
  setlength(anisections, section.Count);

  for i := 0 to section.Count - 1 do
  begin
    anisections[i].ifrom := ini.ReadInteger('Markers', section[i], 1) - 1;
    s := section[i];
    c := pos('_', s);
    if c > 0 then
    begin
      anisections[i].sectionname := lowercase(copy(s, 1, c - 1));
      anisections[i].Value := strtointdef(copy(s, c + 1, 9999), 1);
    end
    else
    begin
      anisections[i].sectionname := lowercase(s);
      anisections[i].Value := 1;
    end;
    if i > 0 then
    begin
      anisections[i - 1].ito := anisections[i].ifrom;
    end;
  end;
  if length(anisections) > 0 then
  begin
    anisections[length(anisections) - 1].ito := anisections[0].ifrom;//length(animes)//
  end;
  section.Destroy;

  //ANIOBJECTS
  obj := TStringList.Create;
  ini.ReadSection('Objects', obj);
  setlength(aniobjects, obj.Count);

  for i := 0 to obj.Count - 1 do
  begin
    aniobjects[i].objname := (obj[i]);

    ast1 := split('/', ini.ReadString('Objects', obj[i], ''));
    aniobjects[i].objtype := lowercase(ast1[0]);

    if length(ast1)>1 then
    begin       //size 3 value
         ast2 := split(',', ast1[1], 3);
         aniobjects[i].objsize := voxel(strtointdef(ast2[0], 640), strtointdef(
              ast2[1], 480), strtointdef(ast2[2], 360));
    end;
  end;
  obj.Destroy;

  ini.Destroy;

end;



destructor TAnimodel.Destroy;
begin
  files.Destroy;
  freeandnil(materialnames);
end;

function TAnimodel.Count: integer;
begin
  Result := length(animes);
end;

procedure TAnimodel.reset(var index: integer);
begin
  index := 1;
end;

function findFreeform(parent: TGLDummyCube): TGLFreeform;
var
  i: integer;
begin
  Result := nil;
  for i := 0 to parent.Count - 1 do
  begin
    if parent.children[i] is TGLFreeform then
      Result := TGLFreeform(parent.children[i]);
  end;
end;

procedure minVector(var v1: TVoxel; vmin: TVoxel);
begin
  v1[0]:=minfloat(v1[0],vmin[0]);
  v1[1]:=minfloat(v1[1],vmin[1]);
  v1[2]:=minfloat(v1[2],vmin[2]);
end;

procedure maxVector(var v1: TVoxel; vmax: TVoxel);
begin
  v1[0]:=maxfloat(v1[0],vmax[0]);
  v1[1]:=maxfloat(v1[1],vmax[1]);
  v1[2]:=maxfloat(v1[2],vmax[2]);
end;



function TAnimodel.Next(Sender: TGL3DControl): boolean;
begin
  Result := False;
  if Sender.frameindex = -1 then
    exit;

  Sender.frameindex := Sender.frameindex + 1;
  if ((Sender.frameindex = Count) ) then
  begin
    Sender.frameindex := Sender.Animation^.startframe;
    Result := True;
  end;
end;

procedure TAnimodel.drawframe(Sender: TGL3DControl);
var
  b: TGLBaseSceneObject;
  freeform: TGLFreeForm;
  i: Integer;
  {$ifdef ANIDELAYED}
  freeformold:TGLFreeForm;
  {$endif}
begin
  if Sender.dummy = nil then
    exit;
  {$ifdef ANIDELAYED}
  freeformold:=nil;
  {$endif}
  freeform := findFreeform(Sender.dummy);
  if assigned(freeform) then
  begin
  {$ifdef ANIDELAYED}
     freeformold:=freeform;
  {$else}
     if assigned(freeform.MaterialLibrary) then
        freeform.MaterialLibrary.Destroy;
     freeform.Destroy;
  {$endif}
  end;
  freeform := TGLFreeform(Sender.dummy.AddNewChild(TGLFreeform));

  freeform.MaterialLibrary:=TGLMaterialLibrary.Create(nil);
  freeform.LoadFromStream(animes[Sender.frameindex].filename,
    animes[Sender.frameindex].anistream);
  freeform.TagObject:=sender;
  materialnames.Clear;
  for  i:=0  to freeform.MaterialLibrary.Materials.Count-1 do
  begin
       materialnames.Add(freeform.MaterialLibrary.Materials.Items[i].displayName);
  end;
  //material
  //bad> freeform.MeshObjects.Items[0].PrepareMaterialLibraryCache();


  {$ifdef ANIDELAYED}
  if assigned(freeformold) then
  begin
    if assigned(freeformold.MaterialLibrary) then
       freeformold.MaterialLibrary.Destroy;
    freeformold.Destroy;
  end;
  {$endif}
  //Next(Sender);
end;

procedure TAnimodel.once(Sender: TGL3DControl);
begin
     drawframe(sender);
     if Sender.frameindex = Sender.Animation^.endframe then
        sender.animationrun:=false;
     if next(sender) then
        sender.animationrun:=false;
{
  if Sender.frameindex <> Sender.Animation^.endframe then
  begin
    drawframe(Sender);
    next(sender);
  end
  else
  begin
    drawframe(sender);
    sender.animationrun:=false;
  end;
}
end;


procedure TAnimodel.process(Sender: TGL3DControl);
//mode: TAnimode;var index:integer;parent:TGLDummyCube;info:PAni);
begin
  if not sender.animationrun then exit;
  case Sender.mode of
    animOnce:
    begin
      once(Sender);
    end;
    AnimFull:
    begin
      drawframe(Sender);
      next(sender);
    end;
    AnimStep:
    begin
      // manual call for drawframe
        drawframe(Sender);
        sender.animationrun:=false;
    end;
  end;
end;

procedure TAnimodel.Setname(AValue: string);
var
  c: integer;
begin
  avalue := lowercase(avalue);


  if Fname = AValue then
    Exit;

  c := pos(avalue, '_');
  if c > 0 then
  begin
    Fname := copy(AValue, 1, c - 1);
    Delete(avalue, 1, c);
    theme := avalue;
  end
  else
    Fname := AValue;
end;


function tanimodel.EOF(Sender: TGL3DControl): boolean;
begin
  Result := False;
  if Sender.frameindex = Sender.Animation^.startframe then
    Result := True;
end;



{ TGL3DControlClass }

procedure TGL3DControlClass.Setname(AValue: string);
begin
  AValue := lowercase(avalue);
  if Fname = AValue then
    Exit;
  Fname := AValue;
end;

constructor TGL3DControlClass.Create(parentcontrol: TGL3DControlClass);
begin
  inherited Create;
  AnicontentList := TList.Create; //TAnicontent
  mode := animstep;
  parent := parentcontrol;
end;

destructor TGL3DControlClass.Destroy;
begin
  clearAnicontentList;
  AnicontentList.Destroy;
  inherited Destroy;
end;

procedure TGL3DControlClass.clearAnicontentList;
var
  i: integer;
begin
  for i := 0 to AnicontentList.Count - 1 do
  begin
    freemem(AnicontentList[i]);
  end;
  anicontentlist.Clear;
end;

function TGL3DControlClass.Add(newsectionname: string; newsectionvalue: integer;
  Voxel: TAffineVector; animodel: PAni): PAni;
begin
  Result := animodel;
  Result^.Control_SectionName := NewSectionName;
  Result^.Control_SectionValue := newSectionValue;
  Result := add(voxel, Result);
end;

function TGL3DControlClass.Add(Voxel: TAffineVector; animodel: PAni): PAni;
begin
  Result := animodel;
  Result^.Control_Voxel := Voxel;
  Result := add(Result);
end;

function TGL3DControlClass.Add(animodel: PAni): PAni;
begin
  Result := animodel;
  if Result^.Control_SectionName = '' then
    Result^.Control_SectionName := Result^.sectionname;
  if Result^.Control_SectionValue = -1 then
    Result^.Control_SectionValue := Result^.sectionvalue;
  AnicontentList.Add(Result);
end;


function TGL3DControlClass.indexOf(Value: integer): PAni;
begin
  Result := nil;
  if Value < AnicontentList.Count then
    Result := AnicontentList.Items[Value];
end;

function TGL3DControlClass.find(sectionname: string; sectionvalue: integer): PAni;
var
  p: PAni;
  i: integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    p := indexof(i);
    if ((p^.Control_SectionName = sectionname) and
      (p^.Control_SectionValue = sectionvalue)) then
    begin
      Result := p;
    end;
  end;
end;

function TGL3DControlClass.Count: integer;
begin
  Result := AnicontentList.Count;
end;


{ TAnimodels }

procedure TAnimodels.SetlistOfAnimodels(AValue: TList);
begin
  if FlistOfAnimodels = AValue then
    Exit;
  FlistOfAnimodels := AValue;
end;

constructor TAnimodels.Create;
begin
  FlistOfAnimodels := TList.Create;
end;

destructor TAnimodels.Destroy;
begin
  clearlist;
  FlistOfAnimodels.Destroy;
end;

procedure TAnimodels.clearlist;
var
  i: integer;
begin
  for i := 0 to listofanimodels.Count - 1 do
  begin
    TAnimodel(listofanimodels.Items[i]).Destroy;
  end;
  listofanimodels.Clear;
end;

procedure TAnimodels.add(Value: TAnimodel);
begin
  listofanimodels.Add(Value);
end;

function TAnimodels.indexOf(index: integer): TAnimodel;
begin
  Result := nil;
  if index < listOfAnimodels.Count then
    Result := TAnimodel(listOfAnimodels[index]);
end;

function TAnimodels.indexOf(Name, theme: string): integer;
begin
  indexof(Name, theme, Result);
end;

function TAnimodels.indexOf(Name, theme: string; var index: integer): TAnimodel;
var
  i: integer;
begin
  Result := nil;
  for i := 0 to listOfAnimodels.Count - 1 do
  begin
    if ((TAnimodel(listOfAnimodels[i]).Name = Name) and
      (TAnimodel(listOfAnimodels[i]).theme = theme)) then
    begin
      index := i;
      Result := TAnimodel(listOfAnimodels[i]);
    end;
  end;
end;

function TAnimodels.indexOfSection(index: integer; sectionname: string;
  sectionvalue: integer): integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to length(TAnimodel(listOfAnimodels[index]).anisections) - 1 do
  begin
    if ((TAnimodel(listOfAnimodels[index]).anisections[i].sectionname =
      lowercase(sectionname)) and (TAnimodel(listOfAnimodels[index]).anisections[i].Value = sectionvalue)) then
      Result := i;
  end;
end;

function TAnimodels.animodel(Name: string; theme: string; sectionname: string;
  sectionvalue: integer): PAni;
var
  p: PAni;
begin
  Result := nil;
  Name := lowercase(Name);
  getmem(p, sizeof(RAni));
  fillbyte(p^, sizeof(RAni), 0);
  setvector(p^.Control_Voxel, 0.0, 0.0, 0.0);

  p^.animodelname := Name;
  p^.theme := theme;
  p^.sectionname := sectionname;
  p^.sectionvalue := sectionvalue;

  //control overwrite that when U want
  p^.Control_SectionName := p^.sectionname;
  p^.Control_SectionValue := p^.sectionvalue;

  p^.animodel := indexof(Name, theme, p^.animodelindex);

  if p^.animodelindex > -1 then
  begin
    p^.sectionindex := indexOfSection(p^.animodelindex, sectionname, sectionvalue);
    if p^.sectionindex <> -1 then
    begin
      p^.startframe := TAnimodel(listOfAnimodels[p^.animodelindex]).anisections[p^.sectionindex].ifrom;
      p^.endframe := TAnimodel(listOfAnimodels[p^.animodelindex]).anisections[p^.sectionindex].ito;
      //p^.frameindex:=p^.startframe;
    end;
  end;
  Result := p;
end;


{ TGLDrawPlane }

procedure TGLDrawPlane.Settext(AValue: string);
begin
  if Ftext=AValue then Exit;
  Ftext:=AValue;
  pic.fillrect(rect(0,0,pic.Bitmap.Width,pic.Bitmap.height),BGRABackground,dmSet);
  pic.TextOut(4,10,ftext,BGRABlue);
  AssignBitmapToTexture;
end;

function TGLDrawPlane.getBitmap: TBGRABitmap; //current
begin
     result:=getbitmap(currentplaneindex);
end;

function TGLDrawPlane.getBitmap(planeindex: integer): TBGRABitmap;
begin
     result:=nil;
     if planeindex<0 then exit;
     if planeindex=0 then
     begin
        result:=pic;
        exit;
     end;
     dec(planeindex);
     if ((planeindex>=0) and (planeindex<self.count)) then
     begin
       result:=TGLDrawPlane(self.Children[planeindex]).getBitmap(0);
     end;
end;

function TGLDrawPlane.getPlane(planeindex: integer): TGLDrawPlane;
begin
  result:=nil;
  if planeindex<0 then exit;
  if planeindex=0 then
  begin
     result:=self;
     exit;
  end;
  dec(planeindex);
  if ((planeindex>=0) and (planeindex<self.count)) then
  begin
    result:=TGLDrawPlane(self.Children[planeindex]);
  end;

end;

function TGLDrawPlane.getPlane: TGLDrawPlane;
begin
     result:=getplane(currentplaneindex);
end;


procedure TGLDrawPlane.refresh;
var
  i: Integer;
begin
  AssignBitmapToTexture;
  for i:=0 to self.Count -1 do
  begin
       TGLDrawPlane(self.Children[i]).refresh;
  end;
end;

procedure TGLDrawPlane.fontChange(Sender: TObject);
begin
  if ffont.color<=$00ffffff then
  begin
       //ffont.color:=ffont.color xor $01ffffff;
  end;
end;

procedure TGLDrawPlane.Setcontentsize(AValue: TVoxel);
begin
  if vectorequals(avalue,fcontentsize) then
     Exit;
  Fcontentsize:=AValue;
  pic.bitmap.Width :=round(avalue[0]);
  pic.bitmap.Height:=round(avalue[1]); //property mode:Normal | copyCanvas
end;

procedure TGLDrawPlane.setcurrentplaneindex(AValue: integer);
begin
  if fcurrentplaneindex=AValue then Exit;
  if getplane(AValue) = nil then exit;
  fcurrentplaneindex:=AValue;
end;

procedure TGLDrawPlane.Setfont(AValue: Tfont);
begin
  if FFont.IsEqual(AValue) then exit;
  FFont.Assign(AValue);
end;

procedure TGLDrawPlane.SetplaneDistance(AValue: single);
begin
  if FplaneDistance=AValue then Exit;
  FplaneDistance:=AValue;
end;

procedure TGLDrawPlane.Setplanesnum(AValue: integer);
var
  i,c: Integer;
  p:TGLDrawPlane;
begin
  if Fplanesnum=AValue then Exit;
  if avalue<0 then avalue:=0;
  Fplanesnum:=AValue;
  self.DeleteChildren;
  for i:=1 to fplanesnum do
  begin
    p:=TGLDrawPlane.Create(nil,Fcontentsize);
    self.AddChild(p);
    with p do
    begin
      Position.z:=-FplaneDistance*i;

    end;
  end;
  c:=fcurrentplaneindex; //try set up the old index
  currentplaneindex:=-1;
  currentplaneindex:=c;
end;


constructor TGLDrawPlane.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  init(AOwner,Point(1000,1000));
end;

constructor TGLDrawPlane.Create(AOwner: TComponent; size: TPoint);
begin
  inherited Create(AOwner);
  init(AOwner,size);
end;

constructor TGLDrawPlane.Create(AOwner: TComponent; size: TVoxel);
begin
  inherited Create(AOwner);
  init(AOwner,point(round(size[0]),round(size[1])));
  self.planesnum:=round(size[2]);
end;

procedure TGLDrawPlane.init(AOwner: TComponent;size: TPoint);
var g:TPicture;
begin
  self.FplaneDistance:=0.02;
  Fplanesnum:=0;
  self.Fcontentsize:=AffineVectorMake(size.x,size.y,0);
  pic:=TBGRABitmap.Create(round(self.Fcontentsize[0]),round(self.Fcontentsize[1]),BGRABackground);
  pic.FontName:='Arial';
  pic.FontAntialias:=true;
  pic.FontHeight:=Math.max(6,round(size.y / 4)); //min 4 row or min 4 pixel
  ftext:='HGPLSoft';

  //pic.DrawLineAntialias(10,10,600,500,BGRAYellow,false);
  pic.TextOut(0,0,ftext,BGRABlue);

  AssignBitmapToTexture;
  with self.Material do
  begin
    frontproperties.Diffuse.Alpha  :=0;
    frontproperties.Emission.Color := clrBlack;
    MaterialOptions                := [moNoLighting];
    BlendingMode                   := bmTransparency;
    Texture.ImageAlpha             := tiaBottomRightPointColorTransparent;
    texture.TextureMode            := tmReplace;
    texture.MinFilter              :=miNearest;
    texture.MagFilter              :=maNearest;
    texture.Disabled               :=false;
  end;
end;

destructor TGLDrawPlane.Destroy;
begin
  inherited Destroy;
  pic.Destroy;
end;

procedure TGLDrawPlane.buildlist(var rci: TRenderContextInfo);
begin
  inherited buildlist(rci);

end;

procedure TGLDrawPlane.StructureChanged;
begin
  inherited StructureChanged;
end;

procedure TGLDrawPlane.AssignBitmapToTexture;
var g:TPicture;
begin
  g:=tPicture.Create;
  g.Assign(pic);
  self.Material.Texture.Image.Assign(g);
  g.Destroy;
end;

function TGLDrawPlane.getcurrentplaneindex: integer;
begin
     result:=fcurrentplaneindex;
end;


procedure TGLDrawPlane.DoProgress(const progressTime: TProgressTimes);
begin
  inherited DoProgress(progressTime);

end;


end.


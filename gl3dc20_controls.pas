unit gl3dc20_controls;

{$mode objfpc}{$H+}
{$DEFINE NO_TEST} //TEST version help to develop
{$DEFINE WARNINGLIGHT} //warninglight
{$DEFINE NO_FULLSCREEN}
interface

uses
  windows,Classes, SysUtils,controls,graphics,forms,
  gl3dc20,math,
  {$IFDEF FULLSCREEN}
  GLFullScreenViewer,
  {$else}
  GLLCLViewer,
  {$endif}
  globjects,glscene,GLCadencer,Vectorgeometry,GLAVIRecorder,glgraphics,
  glcontext,glcolor,vectortypes,glskydome,glmaterial,glRenderContextInfo;

{$IFDEF FULLSCREEN}
{$else}
{$endif}

const
     C_zoomfactor = 1;
     C_CADENCER = 0.01;
     C_MULTIVERSE_LIMIT = 1000;
type

{$IFNDEF FULLSCREEN}
TGLViewer = TGLSceneviewer;
{$else}
TGLViewer = TGLFullScreenviewer;
{$endif}
real = double;

TBEmode = (beFill,beSphereFill,beDrawSphere,beTwoLayer);

{ TForm3d }

TForm3d = class(TComponent)
private
  mx,my:double;

  zoomfactor:real;

  cameraDummy,cameratarget:TGLDummyCube;
  light,warninglight:TGLLightSource;

  fCameraDistance:double;
  FWarning: boolean;

  FViewer: TGLViewer;

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
  fTGLEarthSkyDome:TGLEarthSkyDome;

  avi: TAVIRecorder;
  fAVIAbort: Boolean;


  procedure OnAVIpostEvent(Sender: TObject; frame: TBitmap);
  procedure SetViewer(const Value: TGLViewer);

  procedure SetOnMouseDown(const Value: TMouseEvent);
  procedure SetOnMouseMove(const Value: TMouseMoveEvent);
  procedure SetOnMouseUp(const Value: TMouseEvent);
  procedure SetOnMouseWheel(const Value: TMouseWheelEvent);
  procedure SetWarning(const Value: boolean);

  procedure setcamera(camera:TGLCamera);
  procedure cadencerprogress(Sender: TObject; const deltaTime,newTime: Double);
public
  rootdummy,cameras:TGLDummyCube;
  environment:TGLDummyCube;
  exCadencer:TGLCadencer;
  Multiverse:TMultiverse;

  procedure   Init(AOwner: TComponent;screenw,screenh:integer);
  constructor Create(AOwner: TComponent;screenw,screenh:integer); overload;
  {$IFDEF FULLSCREEN}
  {$else}
  constructor Create(AOwner: TComponent;pleft,ptop,screenw,screenh:integer); overload;
  {$endif}

  destructor  Destroy;override;

  procedure keypress(Sender: TObject; var Key: Char);
  procedure keyup(Sender: TObject; var Key: Word;Shift: TShiftState);
  procedure keydown(Sender: TObject; var Key: Word;Shift: TShiftState);
  procedure mouseup(Sender: TObject; Button: TMouseButton;Shift: TShiftState; X, Y: Integer);
  procedure mousedown(Sender: TObject; Button: TMouseButton;Shift: TShiftState; X, Y: Integer);
  procedure mousemove(Sender: TObject; Shift: TShiftState;X, Y: Integer);
  procedure mousewheel(Sender: TObject; Shift: TShiftState;
               WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);        //AC937D
  procedure BuildEnvironment(
                             mode:TBEmode;
                             basecolor:Tcolor=$00009cff;
                             bgcolor:Tcolor=$00009cff;
                             colordistance:single=0.3;
                             density:integer=188;
                             skydome:boolean=true;
                             envdistance:integer=48);
  function valuez(v:integer):integer;
  function valuez(v:real):real;
  function getpickedcontrol(screenx,screeny:integer):TGL3DControl;
  procedure StartToAVIFileRecording(filename:string;pwidth:word=640;pheight:word=480);
  procedure EndRecording;
published
  property Viewer:TGLViewer read FViewer write SetViewer;
  property OnKeyDown: controls.TKeyEvent read FOnKeyDown write FOnKeyDown;
  property OnKeyPress: TKeyPressEvent read FOnKeyPress write FOnKeyPress;
  property OnKeyUp: controls.TKeyEvent read FOnKeyUp write FOnKeyUp;
  property OnMouseDown : TMouseEvent read FOnMouseDown write SetOnMouseDown;
  property OnMouseUp : TMouseEvent read FOnMouseUp write SetOnMouseUp;
  property OnMouseMove : TMouseMoveEvent read FOnMouseMove write SetOnMouseMove;
  property OnMouseWheel : TMouseWheelEvent read FOnMouseWheel write SetOnMouseWheel;
  property Warning:boolean read FWarning write SetWarning;
end;







function lighter(c:tcolor;volume:integer):tcolor;
function darker(c:tcolor;volume:integer):tcolor;


implementation

function lighter(c:tcolor;volume:integer):tcolor;
type
TRGB = record
  r,g,b,w:byte;
end;

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
type
TRGB = record
  r,g,b,w:byte;
end;
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

{ TForm3d }

function TForm3d.valuez(v:integer):integer;
begin
  result:=round(v*zoomfactor);
end;

function TForm3d.valuez(v: real): real;
begin
     result:=v*zoomfactor;
end;

function TForm3d.getpickedcontrol(screenx, screeny: integer): TGL3DControl;
var obj:TGLBaseSceneObject;
begin
     result:=nil;
     obj:=Viewer.Buffer.GetPickedObject(screenx,screeny);
     if ((assigned(obj)) and (assigned(obj.TagObject)) and (obj.TagObject is TGL3DControl)) then
     begin
          result:=TGL3DControl(obj.TagObject)
     end;
end;

procedure TForm3d.StartToAVIFileRecording(filename: string;pwidth:word=640;pheight:word=480);
var dpi:integer;
   bmp32 : TGLBitmap32;
   bmp : TBitmap;
   d:integer;
begin
     pwidth:=math.max(64,pwidth);
     pheight:=math.max(48,pheight);
     avi:=TAVIRecorder.Create(nil);
     avi.Filename:=filename;
     avi.FPS:=30;
     avi.Compressor:=acShowDialog;
     avi.Width :=pwidth;
     avi.Height:=pheight;
     avi.ImageRetrievalMode:= irmRenderToBitmap;//irmSnapShot;  DPI !!!
     avi.SizeRestriction:=srForceBlock8x8;
     //dpi:=round((96*pwidth)/viewer.Width);
     {$IFDEF FULLSCREEN}
     avi.GLNonVisualViewer:=viewer;
     {$else}
     avi.GLSceneViewer :=viewer;
     {$endif}
//     avi.OnPostProcessEvent:=@OnAVIpostEvent;
     if not avi.CreateAVIFile then Exit;
     fAVIAbort:=false;
     try
          while not fAVIAbort do begin
             bmp:=TBitmap.Create;
             bmp.Width:=pWidth;
             bmp.height:=pHeight;
             viewer.Buffer.RenderingContext.Activate;
             try
{                BitBlt(bmp.Canvas.Handle, 0, 0, bmp.Width, bmp.Height,
                       wglGetCurrentDC, 0, 0, SRCCOPY);
 }
                d:=getdevicecaps(wglGetCurrentDC, BITSPIXEL);
                if d=32 then
                   bmp.PixelFormat:=pf32bit
                else
                   bmp.PixelFormat:=pf24bit;

                StretchBlt(bmp.Canvas.Handle, 0, 0, pWidth, pHeight,
                       wglGetCurrentDC, 0, 0, 8*(viewer.width div 8), 8*(viewer.height div 8), SRCCOPY);

             finally
                viewer.Buffer.RenderingContext.Deactivate;
             end;
             //bmp.canvas.StretchDraw(rect(0,0,pwidth,pheight),bmp);

             avi.AddAVIFrame(bmp);


{
             bmp32:=viewer.Buffer.CreateSnapShot;
             bmp:=bmp32.Create32BitsBitmap;
             bmp.canvas.StretchDraw(rect(0,0,pwidth,pheight),bmp);
             bmp.Width:=pwidth;
             bmp.Height:=pheight;
             avi.AddAVIFrame(bmp);
             bmp32.Free;
}
             bmp.Free;


             Application.ProcessMessages; // so that our app. is not freezed,
                                          // and will accept user abort.
          end;
       finally
          avi.CloseAVIFile(false); // if UserAbort, CloseAVIFile will
                                   // also delete the unfinished file.
          fAVIAbort:=true;
          avi.Destroy;
       end;
end;

procedure TForm3d.EndRecording;
begin
     fAVIAbort:=true;
end;

procedure TForm3D.OnAVIpostEvent(Sender: TObject;
  frame: TBitmap);
var bmp:TBitmap;
begin
   // PostProcess event is used to add a "watermark"
   // that will be in the AVI, but isn't visible on-screen
   bmp:=TBitmap.Create;
   bmp.Width:=640;
   bmp.Height:=480;

   bmp.Canvas.StretchDraw(rect(0,0,viewer.width,viewer.height),frame);
   frame.Width:=640;
   frame.Height:=480;
   frame.Canvas.Draw(0,0,bmp);
   bmp.Destroy;
{   with frame.Canvas do begin
      Font.Color:=clAqua;
      Font.Name:='Courrier New';
      Font.Size:=24;
      Font.Style:=[fsBold];
      Brush.Style:=bsClear;
      TextOut(20, 20, Format('GLScene %.3d', [random(100)]));
   end;
     }
end;
procedure TForm3d.SetViewer(const Value: TGLViewer);
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

procedure TForm3d.SetWarning(const Value: boolean);
begin
  FWarning := Value;

end;

procedure TForm3d.setcamera(camera:TGLCamera);
var i:integer;
begin
    if assigned(camera) then // with parent dummy and with light
    begin
         camera.DepthOfView:=valuez(1000);
         camera.NearPlaneBias:=valuez(0.1);

  //search LightSource
         for i := 0 to camera.count - 1 do
         begin
              if ((light=nil) and (camera.Children[i] is TGLLightSource)) then
              begin
                   light:=TGLLightSource(camera.Children[i]);
              end
              else
                   if ((warninglight=nil) and (camera.Children[i] is TGLLightSource)) then
                   begin
                       warninglight:=TGLLightSource(camera.Children[i]);
                   end;
         end;
         if not assigned(light) then
         begin
              light:=TGlLightSource(camera.AddNewChild(TGlLightSource));
              light.LightStyle:=lsSpot;
         end;
         if assigned(light) then
         begin
              light.position.AsAffineVector:=AffineVectorMake(0,0,1);
              light.Direction.AsAffineVector:=AffineVectorMake(0,1,0);
              light.spotDirection.AsAffineVector:=AffineVectorMake(0,-1,0);
         end;
{$IFDEF WARNINGLIGHT}
         if not assigned(warninglight) then
         begin
              warninglight:=TGlLightSource(camera.AddNewChild(TGlLightSource));
              warninglight.LightStyle:=lsParallel;
              warninglight.Ambient.AsWinColor:=clBlack;
         end;
         if assigned(warninglight) then
         begin
              warninglight.position.AsAffineVector:=AffineVectorMake(0,0,0);
              warninglight.Direction.AsAffineVector:=AffineVectorMake(0,-1,0);
         end;
{$endif}

{  //Search target dummy
         cameratarget:=TGLDummyCube(cameras.findSceneObject('cameratarget'));
         if not assigned(cameratarget) then
         begin
              cameratarget:=TGlDummyCube(cameras.AddNewChild(TGlDummyCube));
              cameratarget.Name:='cameratarget';
         end;
         cameratarget.Position.AsAffineVector:=AffineVectormake(0,0,0);
         camera.TargetObject:=cameratarget;
}
    end;
end;

procedure TForm3d.cadencerprogress(Sender: TObject; const deltaTime,
  newTime: Double);
begin
    if assigned(Multiverse) and assigned(Multiverse.Universe) and assigned(Multiverse.System)then
    begin
         Multiverse.process;
    end;
end;

{$IFDEF FULLSCREEN}
{$else}
constructor TForm3d.Create(AOwner: TComponent;pleft,ptop,screenw,screenh:integer); overload;
begin
  inherited Create (AOwner);
  init(aowner,screenw,screenh);
  viewer.left:=pleft;
  viewer.top:=ptop;
end;
{$endif}

constructor TForm3d.Create(AOwner: TComponent;screenw,screenh:integer);
begin
     inherited Create (AOwner);
     init(aowner,screenw,screenh);
end;

procedure TForm3d.Init(AOwner: TComponent;screenw,screenh:integer);
  var glscene:TGLScene;
      cam:TGLCamera;
  begin

    zoomfactor:=C_zoomfactor;

    light:=nil;
    warninglight:=nil;

{$IFDEF FULLSCREEN}
    tform(aowner).Left:=screenw;
{$endif}
    decimalseparator:='.';
    randomize;

//SCREEN
    Viewer := TGLViewer.Create(tform(aowner));
{$IFDEF FULLSCREEN}
    viewer.Form:=tform(aowner);
    viewer.StayOnTop:=true;
{$else}
    if aowner is twincontrol then
       viewer.Parent:=twincontrol(aowner);
    viewer.Anchors:=[akTop, akLeft, akRight, akBottom];
{$endif}
    viewer.Width:=screenw;
    viewer.Height:=screenh;
    viewer.Buffer.AntiAliasing:=csa16x;
    viewer.buffer.ContextOptions:=[roDoubleBuffer,roOpenGL_ES2_Context];
    viewer.Buffer.BackgroundColor:=$777777;
    viewer.Buffer.ColorDepth:=cd24bits;
  //SCENE, ROOT DUMMY
    glscene:=TGLScene.Create(tform(aowner));
    //glscene.ObjectsSorting:=osNone;
    //glscene.ObjectsSorting:=osRenderNearestFirst;
//    glscene.objects.Direction.AsAffineVector:=AffineVectorMake(0,1,0);
//    glscene.objects.Up.AsAffineVector:=AffineVectorMake(0,0,1);

    rootdummy:=TGLDummyCube(glscene.Objects.AddNewChild(TGLDummyCube));
    rootdummy.Name:='firstdummy';
    rootdummy.ObjectsSorting:=osRenderNearestFirst;
//    rootdummy.Direction.AsAffineVector:=AffineVectorMake(0,1,0);
//    rootdummy.Up.AsAffineVector:=AffineVectorMake(0,0,1);
    cameras:=TGLDummyCube(rootdummy.AddNewChild(TGLDummyCube));
    cameras.Name:='cameras';
//FISRT CAMERA
    cam:=TGLCamera(cameras.AddNewChild(TGLCamera));
    cam.TargetObject:=TGLDummyCube(cameras.AddNewChild(TGLDummyCube));
    cam.TargetObject.Position.AsAffineVector:=affinevectormake(0,0,0);
    setcamera(cam);
    cam.Position.AsAffineVector:=affinevectormake(0,0,6);
    viewer.Camera:=cam;

{$IFDEF TEST}
    cam.TargetObject.ShowAxes:=true;
    with TGLCube(rootdummy.AddNewChild(TGLCube)) do
    begin
         showaxes:=true;
         material.BlendingMode:=bmAlphaTest50;
         material.FrontProperties.Ambient.Alpha:=50;
    end;
{$endif}

//CADENCER GO
    exCadencer:=TGLCadencer.Create(tform(aowner));
    excadencer.OnProgress:=@cadencerprogress;
    with exCadencer do
    begin
        scene:=glscene;
        sleeplength:=-1;
        Timemultiplier:=1;
        mode:=cmASAP;
        fixeddeltatime:=  C_CADENCER ;

        enabled:=true;
    end;

//MULTIVERSE
    Multiverse:=TMultiverse.create(rootdummy);
    Multiverse.addUniverse;
    Multiverse.addSystem(nil);

    {$IFDEF FULLSCREEN}
    viewer.Active:=true;
    {$else}
    {$endif}
end;

destructor TForm3d.Destroy;
begin
  //exCadencer.destroy;
  //viewer.Camera.Scene.destroy;
  //viewer.camera:=nil;
  //viewer.Destroy;

  inherited Destroy;

end;

procedure TForm3d.keypress(Sender: TObject; var Key: Char);
begin
    if assigned(self.FMainKeyPress) then
       fmainkeypress(sender,key);

//...

// self
    if assigned(fOnKeyPress) then
       fonkeypress(sender,key);

end;

procedure TForm3d.keyup(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if assigned(self.FMainKeyUp) then
       fmainkeyup(sender,key,shift);
//...

    if assigned(fOnKeyUp) then
       fonkeyup(sender,key,shift);
end;

procedure TForm3d.keydown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if assigned(self.FMainKeyDown) then
       fmainkeydown(sender,key,shift);
//...

    if assigned(fOnKeyDown) then
       fonkeydown(sender,key,shift);
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

procedure TForm3d.mousedown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
    if assigned(self.FMainMouseDown) then
       fmainMouseDown(sender,button,shift,x,y);


//...
mx:=x;
my:=y;


    if assigned(fOnMouseDown) then
       fonMouseDown(sender,button,shift,x,y);
end;

procedure TForm3d.mousemove(Sender: TObject; Shift: TShiftState; X, Y: Integer
  );
begin
      if assigned(self.FMainMouseMove) then
          fmainMouseMove(sender,shift,x,y);

      if ssRight in shift then
      begin
           self.FViewer.Camera.MoveAroundTarget(-(y-my)/5,-(x-mx)/5);
      end;

  // self
      if assigned(fOnMouseMove) then
          fonMousemove(sender,shift,x,y);

      mx:=x;
      my:=y;
end;

procedure TForm3d.mousewheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
      if assigned(self.FMainMouseWheel) then
         fmainMouseWheel(sender,shift,wheeldelta,mousepos,handled);

// self

      if assigned(fOnMouseWheel) then
         fonMouseWheel(sender,shift,wheeldelta,mousepos,handled);
end;

procedure TForm3d.BuildEnvironment(
                                   mode:TBEmode;
                                   basecolor:Tcolor=$00009cff;
                                   bgcolor:Tcolor=$00009cff;
                                   colordistance:single=0.3;
                                   density:integer=188;
                                   skydome:boolean=true;
                                   envdistance:integer=48);
var scene:TGLScene;
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
     if ((not assigned(viewer.camera)) and ((not assigned(viewer.camera.Scene)))) then exit;

     if assigned(environment) then
        environment.destroy;
     if assigned(fTGLEarthSkyDome) then
        fTGLEarthSkyDome.Destroy;


     scene:=viewer.camera.Scene;
     environment:=TGLDummyCube(rootdummy.AddNewChild(TGLDummyCube));
     viewer.Buffer.BackgroundColor:=bgcolor;

     if skydome then
     begin
       if assigned(rootdummy) then
       begin
         fTGLEarthSkyDome:= TGLEarthSkyDome(scene.Objects.AddNewChildfirst(TGLEarthSkyDome));
         with fTGLEarthSkyDome do
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
         l.division:=10;


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

               //node:=tgllinesnode(l.Nodes.Add);
 {position}
               fenvdistance:=envdistance/10;
               setvector(nodevector,random-0.5,random-0.5,random-0.5);
               normalizevector(nodevector);
               setvector(nodebase,0,0,0);
               combinevector(nodebase,nodevector,fenvdistance);
               l.Nodes.AddNode(nodebase);
               //node.asAffinevector:=nodebase;
               {color}

                             glcolor:=tglcolor.CreateInitialized(self,ConvertWinColor(basecolor));
                             clVector1:=glcolor.color;
                             nearto(clvector1,colordistance);
                             glcolor.Color:=clvector1;
                             TGLLinesNode(l.nodes[l.nodes.Count-1]).Color:=glcolor;

                             glcolor.destroy;

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

end.


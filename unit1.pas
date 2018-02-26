unit unit1;

{$mode objfpc}{$H+}
{$DEFINE NO_FULLSCREEN}    //sznc with gl3dc20_controls
interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, GLScene,
  GLObjects, GLVectorFileObjects,
  GLCadencer, GLSimpleNavigation, GLMaterial, GLMaterialEx,
  GLBitmapFont, GLWindowsFont, GLSound, GLLCLViewer, GLFullScreenViewer,
   glcontext, GLSMBASS, GLSMWaveOut, GLSkydome, GLAVIRecorder,
   VectorGeometry, persistentclasses, AsyncTimer, FPImage,BGRABitmap,
  gl3dc20,  glaviplane, gl3dc_ext1,gl3dc20_controls, BGRABitmapTypes;

type


  { TForm1 }

  TForm1 = class(TForm)
    actions: TComboBox;
    AVIRecorder1: TAVIRecorder;
    b2: TButton;
    b3: TButton;
    Button1: TButton;
    Button10: TButton;
    Button11: TButton;
    Button12: TButton;
    Button13: TButton;
    Button14: TButton;
    Button15: TButton;
    Button16: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    GLMemoryViewer1: TGLMemoryViewer;
    grp: TRadioGroup;
    irany: TRadioGroup;
    Label1: TLabel;
    Label2: TLabel;
    Memo1: TMemo;
    Panel1: TPanel;
    GLCadencer1: TGLCadencer;
    GLCamera1: TGLCamera;
    GLCamera2: TGLCamera;
    avii: TGLDummyCube;
    GLCube1: TGLCube;
    GLCube2: TGLCube;
    GLCube3: TGLCube;
    GLDummyCube1: TGLDummyCube;
    GLEarthSkyDome1: TGLEarthSkyDome;
    GLLines1: TGLLines;
    mm: TGLSMWaveOut;
    Panel2: TPanel;
    sa: TButton;
    sound1: TGLSoundLibrary;
    navi: TGLSimpleNavigation;
    stp: TButton;
    text11: TGLFlatText;
    multi: TGLDummyCube;
    het: TGLDummyCube;
    GLLightSource1: TGLLightSource;
    GLMaterialLibrary1: TGLMaterialLibrary;
    GLMaterialLibraryEx1: TGLMaterialLibraryEx;
    GLScene1: TGLScene;
    villa: TGLSceneViewer;
    procedure AsyncTimer1Timer(Sender: TObject);
    procedure AVIRecorder1PostProcessEvent(Sender: TObject; frame: TBitmap);
    procedure b2Click(Sender: TObject);
    procedure b3Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure Button13Click(Sender: TObject);
    procedure Button14Click(Sender: TObject);
    procedure Button15Click(Sender: TObject);
    procedure Button16Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure saClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6ChangeBounds(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Edit4KeyPress(Sender: TObject; var Key: char);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure GLSceneViewer1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure iranyClick(Sender: TObject);
    procedure stpClick(Sender: TObject);
    procedure visible(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure GLCadencer1Progress(Sender: TObject; const deltaTime,
      newTime: Double);
    procedure villaClick(Sender: TObject);
  private
    { private declarations }
    //a1:boolean;
    ci1,ci2,ci3,ci4:TGL3DControl;
    ci5:TGL3DControl;
    c:array of TGL3DControl;
    bmpfont:tglwindowsbitmapfont;
    //br:integer;
    //AviPlane : TGLAviPlane;
    //sv:tglsceneviewer;
    //newManager :TGLSoundManager;
    //GLSMBASS1: TGLSMBASS;
    t:TGLDrawPlane;

    Multiverse:TMultiverse;

    form3d:tform3d;
//    fre,fre1:TGl3dcontrolEdit;


  public
    { public declarations }
    procedure loadAnimation(const modelfiles:string);
  end;

var
  Form1: TForm1; 

implementation

{$R *.lfm}

{ TForm1 }


procedure TForm1.saClick(Sender: TObject);
begin
     if form3d.Viewer.Width=1280 then
        form3d.StartToAVIFileRecording('rec1.avi',1280,720)
     else
        form3d.StartToAVIFileRecording('rec1.avi');
end;

procedure TForm1.Button10Click(Sender: TObject);
begin
     ci1.action('show',1,animOnce);

end;

procedure TForm1.AsyncTimer1Timer(Sender: TObject);
begin

end;

procedure TForm1.AVIRecorder1PostProcessEvent(Sender: TObject; frame: TBitmap);
begin

end;

procedure TForm1.b2Click(Sender: TObject);
var
  i: Integer;
begin
     setlength(c,10);
     for i:=0 to length(C)-1 DO
     begin
       c[i]:=form3d.Multiverse.System.add('slider');
       c[i].Name:='aut'+inttostr(i);
       if i>0 then
       begin
           c[i].parent:=c[i-1];
           c[i].size       := affinevectormake(200,200,200);   //parent miatt ez a CONTENT területben a 100,50 től tart 200,70-ig
       end
       else
       begin
           c[i].size       := affinevectormake(200,200,10);   //parent miatt ez a CONTENT területben a 100,50 től tart 200,70-ig
           c[i].Dummy.roll(90);
       end;
       c[i].position   := affinevectormake(30,0,100);//in parent contentsize
       c[i].contentsize:= affinevectormake(200,200,conX); //ehhez az elég kicsi területnek a mérete is még apróbb részre van osztva
     end;
     panel2.Enabled:=true;
     tbutton(sender).enabled:=false;
end;

procedure TForm1.b3Click(Sender: TObject);
var
  i: Integer;
begin
     if length(c)=0 then exit;

     for i:=0 to length(C)-1 DO
     begin
          c[i].action(actions.Text,irany.ItemIndex,animOnce);
     end;

end;

procedure TForm1.Button11Click(Sender: TObject);
begin
       ci2.action('show',1,animOnce);
       ci3.action('show',1,animOnce);

end;

procedure TForm1.Button12Click(Sender: TObject);
begin
     form3d.Viewer.Buffer.ContextOptions:=form3d.Viewer.Buffer.ContextOptions+[roStereo];
end;

procedure TForm1.Button13Click(Sender: TObject);
begin
  memo1.Lines.AddStrings(ci2.materialnames);
end;

procedure TForm1.Button14Click(Sender: TObject);
begin
     //form3d.BuildEnvironment(beDrawSphere);
end;

procedure TForm1.Button15Click(Sender: TObject);
begin
     ci4.action('show',1,animOnce);
end;

procedure TForm1.Button16Click(Sender: TObject);
begin

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if tbutton(sender).tag=1 then
  begin
     form3d.Viewer.Height:=1280;
     form3d.viewer.Width:=720;
  end
  else
  begin
     form3d.Viewer.Height:=480;
     form3d.viewer.Width:=640;
  end;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  form3d.EndRecording;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
     if grp.ItemIndex=0 then
        ci1.position:=affinevectormake(strtointdef(edit1.Text,0),strtointdef(edit2.Text,0),strtointdef(edit3.Text,0))
     else
        ci2.position:=affinevectormake(strtointdef(edit1.Text,0),strtointdef(edit2.Text,0),strtointdef(edit3.Text,0))
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
ci2.action('show',0,animOnce);
ci3.action('show',0,animOnce);
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
     ci1.action('show',0,animOnce);
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
       ci1.action('open',1,animOnce);

end;

procedure TForm1.Button6ChangeBounds(Sender: TObject);
begin

end;


procedure TForm1.Button7Click(Sender: TObject);
begin
ci2.action('open',1,animOnce);
ci3.action('open',1,animOnce);
ci4.action('open',1,animOnce);
end;

procedure TForm1.Button8Click(Sender: TObject);
begin
     ci1.action('open',0,animOnce);

end;

procedure TForm1.Button9Click(Sender: TObject);
begin
ci2.action('open',0,AnimOnce);
ci3.action('open',0,AnimOnce);
ci4.action('open',0,AnimOnce);

end;

procedure TForm1.Edit4KeyPress(Sender: TObject; var Key: char);
begin
     t.text:=edit4.text;

end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
     MEMO1.Lines.Add(inttostr(x)+'-'+inttostr(y)+'   '+
       floattostrf(form3d.Viewer.Camera.Position.AsAffineVector[0],ffFixed,15,2)+','+
       floattostrf(form3d.Viewer.Camera.Position.AsAffineVector[1],ffFixed,15,2)+','+
       floattostrf(form3d.Viewer.Camera.Position.AsAffineVector[2],ffFixed,15,2)
       );
end;

procedure TForm1.GLSceneViewer1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var obj:TGLBaseSceneObject;
    cl:TGL3DControl;

begin
     if shift = [ssleft] then
     begin
          cl:=form3d.getpickedcontrol(x,y);
          if ((assigned(cl)) and (cl.animation<>nil)) then begin
             if ((cl.Animation^.Control_SectionName=actions.Text) and (cl.Animation^.Control_SectionValue=1)) then
                cl.action(actions.Text,0,animOnce)
             else
                cl.action(actions.Text,1,animOnce);
          end;
{          obj:=form3d.Viewer.Buffer.GetPickedObject(x,y);

     if ((obj<>nil) and (obj.parent<> nil ) and (obj.parent.parent<>nil) and (obj.parent is tgldummycube))then
     begin
          obj.parent.parent.Turn(22);
     end;
 }
     end;
end;

procedure TForm1.iranyClick(Sender: TObject);
begin

end;

procedure TForm1.stpClick(Sender: TObject);
begin
  form3d.EndRecording;
end;

procedure TForm1.visible(Sender: TObject);
begin

end;


procedure TForm1.GLCadencer1Progress(Sender: TObject; const deltaTime,
  newTime: Double);
begin

     if assigned(Multiverse) and assigned(Multiverse.Universe) and assigned(Multiverse.System)then
     begin
          Multiverse.process;
     end;

end;

procedure TForm1.villaClick(Sender: TObject);
begin
     villa.Camera:=form3d.Viewer.Camera;
end;

procedure TForm1.loadAnimation(const modelfiles: string);
begin

end;


procedure saveCanvas(canvas:TCanvas;r:trect;filename:string);
var i:TJPEGImage;
    b:TPicture;
begin
    b:=TPicture.Create;
    i:=TJPEGImage.Create;
    b.bitmap.Width:=r.Right-r.Left;
    b.bitmap.Height:=r.Bottom-r.Top;

    b.bitmap.Canvas.CopyRect(rect(0,0,r.Right-r.Left,r.Bottom-r.Top),canvas,r);
    i.PixelFormat:=pf24bit;
    i.Assign(b.graphic);
    i.SaveToFile(filename);
    i.Destroy;
    b.Destroy;

end;
procedure TForm1.Button6Click(Sender: TObject);
var c1,c2:TBGRAPixel;
    b:TBGRABitmap;
    p:TGLDrawPlane;
const hh:integer = 100;
begin
  c1:=BGRABlue;
  c1.blue:=255;
  c2:=BGRABlue;
  c2.red:=99;
  c2.green:=99;

  b:=t.getBitmap(1);
  if b<>nil then
  begin
     b.fillrect(1,1,800,hh,bgraBackground,dmSet);
     b.roundrectantialias(2,2,800,hh,15,15,c1,2,[]);
     b.roundrectantialias(4,4,798,hh-2,15,15,c2,2,[]);
     b.roundrectantialias(6,6,796,hh-4,15,15,c1,2,[]);
  end;
{  p:=t.getPlane(2);
  if p<> nil then
  begin
     p.Position.Z:=-0.02;
     b:=t.getBitmap(2);
     b.fillrect(1,1,800,60,bgraBackground,dmSet);
     b.roundrectantialias(1,1,800,60,10,10,c1,3,[]);
     b.roundrectantialias(3,3,798,58,10,10,BGRABlue,3,[]);
     b.roundrectantialias(5,5,796,56,10,10,c1,3,[]);

  end;
}
  t.refresh;
end;

procedure TForm1.FormCreate(Sender: TObject);
var n:TGL3DControlClass;
    s:TGLSoundsample;
    em:TGLBSoundEmitter;

begin
  setlength(c,0);
{$IFDEF FULLSCREEN}
  form3d:=tform3d.create(self,screen.Width,screen.Height);
{$else}
  form3d:=tform3d.create(self,10,10,self.Width-20,self.Height-200);
{$endif}
  form3d.BuildEnvironment(beDrawSphere);

  form3d.OnMouseMove:=@FormMouseMove;
  form3d.Multiverse.loadanimodelsfromscriptfile;
  form3d.OnMouseDown:=@GLSceneViewer1MouseDown;

  ci1:=form3d.Multiverse.System.add('window');
  ci1.name:='comp1';
  ci1.size:= affinevectormake(400,400,400);
  ci1.position:= affinevectormake(0,0,0);
  ci1.contentsize:=affinevectormake(640,640,conX);
  ci1.loadmaterialfromfile('content','material\windowcontent.jpg');


     ci2:=form3d.Multiverse.System.add('slider');
     ci2.name:='comp2';
     ci2.parent:=ci1;
     ci2.size       := affinevectormake(200,100,100);   //parent miatt ez a CONTENT területben a 100,50 től tart 200,70-ig
     ci2.position   := affinevectormake(0,0,100);//in parent contentsize
     ci2.contentsize:= affinevectormake(200,100,conX); //ehhez az elég kicsi területnek a mérete is még apróbb részre van osztva
                                                    //jelentősége akkor lesz ha van alárendelt akinek a PARENT-je
                                                    //akkor annak a pozíciója eszerint alakul
     //ci2.AddCanvas;                               //a contentsize szerinti méretben


     ci3:=form3d.Multiverse.System.add('slider');
     ci3.name:='comp3';
     ci3.parent:=ci2;
     ci3.size       := affinevectormake(100,50,10);   //parent miatt ez a CONTENT területben a 100,50 től tart 200,70-ig
     ci3.position   := affinevectormake(0,0,10);//in parent contentsize
     ci3.contentsize:= affinevectormake(1,1,conX); //ehhez az elég kicsi területnek a mérete is még apróbb részre van osztva

     ci4:=form3d.Multiverse.System.add('knot');
     ci4.name:='comp4';
     ci4.size       := affinevectormake(400,200,200);   //parent miatt ez a CONTENT területben a 100,50 től tart 200,70-ig
     ci4.position   := affinevectormake(100,100,150);//in parent contentsize
     ci4.contentsize:= affinevectormake(1,1,conX); //ehhez az elég kicsi területnek a mérete is még apróbb részre van osztva



     t:=TGLDrawPlane.Create(glscene1);
     form3d.rootdummy.AddChild(t);
     t.Position.Y:=-6;
     t.position.x:=-4;
     t.Scale.AsAffineVector:=Affinevectormake(8,8,8);
//     t.turn(0);
//     t.Pitch(-90);
     t.planeDistance:=-0.02;
     t.planesnum:=1;

//ci2.textoutcontent('Arial',0,0,0,utf8towidestring('őúűöüóéáíÖÜÓŐÚŰÉÁÍ'));
             //1,1,1 méretben csak a 0 pozíció adott (lásd: ci2.contensize)
             //mérete a ci2 maximális méretéig nyúlhat karakterszinten nem lehet több (azaz karaktert nem vág el)


     //ci1.dummy.Turn(20);
     //ci2.dummy.Turn(90);
     //ci2.dummy.pitch(-90);
     bmpfont:=tglwindowsbitmapfont.Create(nil);
     bmpfont.Font.Name:='Arial';
     bmpfont.ranges.Clear;
     bmpfont.Ranges.Add(chr(33),chr($fc));
{     text11.BitmapFont:=bmpfont;
//     bmpfont.ranges.Add(chr($c1),chr($fc));

     text11.Text:=utf8towidestring('őúűöüóéáíÖÜÓŐÚŰÉÁÍ');
}

{
     AviPlane := TGLAviPlane.Create(GLScene1);
     aviplane.Material.MaterialOptions := [moNoLighting];
     avii.AddChild(aviplane);
     aviplane.UserFrameRate := 50;
     aviplane.Quality:=2;
     aviplane.Rendermode:=rmTriStrip;
     aviplane.position.AsAffineVector:=AffineVectormake(0,0,0);
     aviplane.pitch(-90);
     aviplane.turn(90);
     aviplane.Material.BlendingMode:=bmTransparency;
//     aviplane.Filename:='e:\temp\(Unknown) - Clip 033.avi';// 'e:/untitled.avi';//
     aviplane.Filename:='c:\munka\blender\0001-2600.avi';// 'e:/untitled.avi';//
}
{
     t:=TGLDrawPlane.Create(self);
     ci1.Dummycontent.AddChild(t);

     //t.Scale.AsAffineVector:=affinevectormake(8,8,8);
     t.Position.AsAffineVector:=affinevectormake(0.5,0.5,0.5);
     t.planeDistance:=-0.02;
     t.planesnum:=1;
}
exit;

     //GLSMBASS1:=TGLSMBASS.Create(self);


    // vvv.Buffer.AntiAliasing:=aaNone;

     //sound1.Samples.AddFile('sound/chimes.wav');
//     s.Data.LoadFromFile('sound/pling.mp3');
//     s.Name:='pling';

{     newManager :=TGLSoundManager.Create(self);
     newmanager.Active:=true;
     newmanager.Cadencer:=glcadencer1;
     newmanager.Listener:=glcamera1;
}

    {
     em:=TGLBSoundEmitter.Create(glcube1.Behaviours);
     em.Source.SoundLibrary:=sound1;
     em.Source.SoundName:='pling.mp3';
     em.Source.NbLoops:=1000;
     }
     //full.Form:=form1;
{     sv:=tglsceneviewer.Create(self);
     sv.Top:=0;
     sv.Left:=0;
     sv.Width:=self.width;
     sv.height:=panel1.Top;
     sv.Camera:=glcamera1;
     sv.parent:=self;
     sv.Buffer.AntiAliasing:=aa16x;
     navi.GLSceneViewer:=sv;}

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
     if assigned(bmpfont) then
        bmpfont.ranges.clear;
     if assigned(text11.bitmapfont) then
     begin
          text11.BitmapFont.Destroy;
          text11.BitmapFont:=nil;
     end;
     //form3d.Destroy;
end;

end.


/// deprecated Already
{
     //Create World Instance
     Multiverse:=TMultiverse.create(multi);
     Multiverse.addUniverse;
     Multiverse.addSystem(nil);
     //pre init animations
     Multiverse.animodels.add(Tanimodel.create('slider','ani\slider\slider%.gl3dc'));
     Multiverse.animodels.add(Tanimodel.create('plane','ani\plane\plane%.gl3dc'));

     //Make ControlClasses
     n:=Multiverse.addControlClass(nil);
     n.name:='Window';
     n.Add( multiverse.animodels.animodel('slider','','open',1) );
     n.Add( multiverse.animodels.animodel('slider','','open',0) );
     n.Add( multiverse.animodels.animodel('slider','','show',1) );
     n.Add( multiverse.animodels.animodel('slider','','show',0) );
     n.Add( multiverse.animodels.animodel('slider','','turn',1) );
     n.Add( multiverse.animodels.animodel('slider','','turn',0) );
     n:=Multiverse.addControlClass(nil);
     n.name:='Plane';
     n.Add( multiverse.animodels.animodel('plane','','show',1) );
     n.Add( multiverse.animodels.animodel('plane','','show',0) );
}


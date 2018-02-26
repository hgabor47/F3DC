unit gl3dc_ext1;

{$mode objfpc}{$H+}

interface

uses
  GLScene,Baseclasses,graphics,
   VectorGeometry,OPENGLTokens,
   OpenGL1x, glcolor,glmaterial,
   GLRenderContextinfo,
   GLTexture,globjects,
   glsvfw,
   windows,BGRABitmapTypes,BGRABitmap,
   classes,gl3dc20;

const
  BGRARed: TBGRAPixel = (blue: 0; green: 0; red: 255; alpha: 255);
  BGRAGreen: TBGRAPixel = (blue: 0; green: 255; red: 0; alpha: 255);
  BGRAYellow: TBGRAPixel = (blue: 0; green: 255; red: 255; alpha: 255);
  BGRABlue: TBGRAPixel = (blue: 255; green: 0; red: 0; alpha: 255);
  BGRABackground:TBGRAPixel = (blue: 1; green: 1; red: 1; alpha: 0);
type

  { TGLTextPlane }

  TGLDrawPlane = class(TGLPlane)
  private
    Fcontentsize: TVoxel;
    Ffont: Tfont;
    FplaneDistance: single;
    Fplanesnum: integer;
    Fposition: TVoxel;
    Fsize: TVoxel;
    Ftext: string;
    pic:TBGRABitmap;


    procedure AssignBitmapToTexture;
    procedure Setcontentsize(AValue: TVoxel);
    procedure Setfont(AValue: Tfont);
    procedure SetplaneDistance(AValue: single);
    procedure Setplanesnum(AValue: integer);
    procedure Settext(AValue: string);
    procedure fontChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure buildlist(var rci: TRenderContextInfo); override;
    procedure StructureChanged; override;
    procedure DoProgress(const progressTime: TProgressTimes); override;
    function  getBitmap(planeindex:integer):TBGRABitmap;
    function  getPlane(planeindex:integer):TGLDrawPlane;
    procedure refresh;

    property text : string read Ftext write Settext;
    property contentsize: TVoxel read Fcontentsize write Setcontentsize;
    property font:Tfont read Ffont write Setfont;

    property planesnum:integer read Fplanesnum write Setplanesnum;
    property planeDistance:single read FplaneDistance write SetplaneDistance;

  end;



implementation

{ TGLDrawPlane }

procedure TGLDrawPlane.Settext(AValue: string);
begin
  if Ftext=AValue then Exit;
  Ftext:=AValue;
  pic.fillrect(rect(0,0,pic.Bitmap.Width,pic.Bitmap.height),BGRABackground,dmSet);
  pic.TextOut(4,10,ftext,BGRABlue);
  AssignBitmapToTexture;
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
  i: Integer;
begin
  if Fplanesnum=AValue then Exit;
  Fplanesnum:=AValue;
  self.DeleteChildren;
  for i:=1 to fplanesnum do
  begin
    with self.AddNewChild(TGLDrawPlane) do
    begin
      Position.z:=-FplaneDistance*i;

    end;
  end;
end;


constructor TGLDrawPlane.Create(AOwner: TComponent);
var g:TPicture;
begin
  inherited Create(AOwner);
  self.FplaneDistance:=0.002;
  Fplanesnum:=0;
  self.Fcontentsize:=AffineVectorMake(1000,1000,0);
  pic:=TBGRABitmap.Create(round(self.Fcontentsize[0]),round(self.Fcontentsize[1]),BGRABackground);
  pic.FontName:='Arial';
  pic.FontAntialias:=true;
  pic.FontHeight:=80;
  ftext:='HGPLSoft';
  //pic.DrawLineAntialias(10,10,600,500,BGRAYellow,false);
  pic.TextOut(4,10,ftext,BGRABlue);

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


procedure TGLDrawPlane.DoProgress(const progressTime: TProgressTimes);
begin
  inherited DoProgress(progressTime);

end;

end.


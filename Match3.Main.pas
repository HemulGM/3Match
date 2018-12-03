unit Match3.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Direct2D, D2D1, Vcl.ExtCtrls, Vcl.StdCtrls, System.Generics.Collections;


const
  FWidth = 9;
  FHeight = 9;
  FSize = 64;

type
  TDirect = (tdNone, tdLeft, tdRight, tdUp, tdDown);

  TExtPoint = record
   private
    function GetX: Integer;
    function GetY: Integer;
   public
    X, Y:Single;
    property iX:Integer read GetX;
    property iY:Integer read GetY;
    class function Create(X, Y:Single):TExtPoint; static;
    class operator Equal(const Lhs, Rhs : TExtPoint) : Boolean;
    class operator NotEqual(const Lhs, Rhs : TExtPoint): Boolean;
  end;

  TCellKind = 1..5;

  TCell = record
   private
    Color:TColor;
    Speed:Single;
    Position, NeedPos:TExtPoint;
    Kind:TCellKind;
    ArrayPos:TPoint;
    Empty:Boolean;
    Hole:Boolean;
    function GetNoMatch: Boolean;
    function GetNormal: Boolean;
   public
    property NoMatch:Boolean read GetNoMatch;
    property Normal:Boolean read GetNormal;
    procedure UpdatePos(Pos:TPoint);
    procedure RandomKind;
    function Step:Boolean;
  end;

  TGameCur = record
   Down:Boolean;
   OutOf:Boolean;
   Cell:TCell;
   FLastPos:TPoint;
  end;

  TField = array[1..FHeight, 1..FWidth] of TCell;

  TCalcCell = record
   Size:Integer;
   Value:Integer;
   function Inc:Integer;
  end;

  TCalcField = array[1..FHeight, 1..FWidth] of TCalcCell;

  TDirect2DCanvasHelper = class helper for TDirect2DCanvas
   procedure FillRect(const Rect: TRect; Opacity:Single); overload;
  end;

  TFormMain = class(TForm)
    TimerFPS: TTimer;
    TimerRepaint: TTimer;
    PanelCtrl: TPanel;
    Button1: TButton;
    Button2: TButton;
    TimerAnimate: TTimer;
    procedure TimerFPSTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Button2Click(Sender: TObject);
    procedure TimerAnimateTimer(Sender: TObject);
   private
    FCanvas:TDirect2DCanvas;
    FPSCounter:Integer;
    FFPS:Integer;
    FBorders:TRect;
    FScore:Integer;
    FField:TField;
    FCalcField:TCalcField;
    FBGAng:Integer;
    FGameCur:TGameCur;
    FSelCell:TCell;
    Moving:Boolean;
    procedure DrawField;
    function MoveCell(CellPos:TPoint; Direct:TDirect; var NewPos:TPoint):Boolean;
    procedure DrawBG;
    procedure Wait;
    function GetCell(X, Y: Integer): TCell;
    procedure SetCell(X, Y: Integer; const Value: TCell);
    function GetCalcCell(X, Y: Integer): TCalcCell;
    procedure SetCalcCell(X, Y: Integer; const Value: TCalcCell);
   protected
    procedure CreateWnd; override;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
   public
    procedure DoDraw;
    procedure CreateField;
    procedure NewGame;
    procedure CheckField;
    property Canvas:TDirect2DCanvas read FCanvas;
    property Field[X, Y:Integer]:TCell read GetCell write SetCell;
    property CalcField[X, Y:Integer]:TCalcCell read GetCalcCell write SetCalcCell;
  end;

const
  KindColor:array[TCellKind] of TColor = ($004EBF81, $002EB7D9, $002A62D9, $00D98549, $00D9509E);
  MinMatch = 3;

var
  FormMain: TFormMain;
  FreeCell:TCell;

implementation

{$R *.dfm}

procedure TFormMain.Button1Click(Sender: TObject);
begin
 NewGame;
end;

procedure TFormMain.Button2Click(Sender: TObject);
begin
 CheckField;
end;

procedure TFormMain.Wait;
begin
 //Sleep(20);
 //Application.ProcessMessages;
end;

procedure TFormMain.CheckField;
type TMatch = TList<TPoint>;
var Y, X:Integer;
    LastKind:TCellKind;
    LastCnt:Integer;
    Start:Boolean;
    Match:TMatch;
    CCell:TCalcCell;

procedure IncMatch(FCount:Integer);
var i:Integer;
begin
 for i:= 0 to Match.Count-1 do
  begin
   CCell:=CalcField[Match[i].X, Match[i].Y];
   CCell.Inc;
   CCell.Size:=FCount;
   CalcField[Match[i].X, Match[i].Y]:=CCell;
  end;
end;

function MatchField:Boolean;
var Y, X:Integer;
    FEmpty:Boolean;
    FEmptyPos:Integer;
    FMoved:Boolean;
begin
 Result:=False;
 for X:=1 to FHeight do
  for Y:=1 to FWidth do
   begin
    if CalcField[X, Y].Value > 0 then
     begin
      Field[X, Y]:=FreeCell;
      Result:=True;
      //Wait;
     end;
   end;
 repeat
  FMoved:=False;
  for X:= 1 to FWidth do
   for Y:= FHeight-1 downto 1 do
    begin
     if Field[X, Y].NoMatch then Continue;
     if Field[X, Y+1].Empty then
      begin
       FMoved:=True;
       Field[X, Y+1]:=Field[X, Y];
       Field[X, Y]:=FreeCell;
      end;
    end;
  Wait;
 until not FMoved;

end;

begin
 Match:=TMatch.Create;
 CCell.Value:=0;
 for Y:=1 to FHeight do
  for X:=1 to FWidth do
   begin
    CalcField[X, Y]:=CCell;
   end;

 for Y:=1 to FHeight do
  begin
   Match.Clear;
   LastKind:=Field[1, Y].Kind;
   Match.Add(Point(1, Y));
   LastCnt:=1;
   for X:=2 to FWidth do
    begin
     if Field[X, Y].NoMatch then
      begin
       if LastCnt >= MinMatch then IncMatch(LastCnt);
       Match.Clear;
       LastCnt:=1;
       Continue;
      end;
     if Field[X, Y].Kind = LastKind then Inc(LastCnt);
     if (Field[X, Y].Kind = LastKind) and (X = FWidth) then Match.Add(Point(X, Y));
     if (Field[X, Y].Kind <> LastKind) or (X = FWidth) then
      begin
       if LastCnt >= MinMatch then IncMatch(LastCnt);
       Match.Clear;
       LastCnt:=1;
      end;
     LastKind:=Field[X, Y].Kind;
     Match.Add(Point(X, Y));
    end;
  end;

 for X:=1 to FWidth do
  begin
   Match.Clear;
   LastKind:=Field[X, 1].Kind;
   Match.Add(Point(X, 1));
   LastCnt:=1;
   for Y:=2 to FHeight do
    begin
     if Field[X, Y].NoMatch then
      begin
       if LastCnt >= MinMatch then IncMatch(LastCnt);
       Match.Clear;
       LastCnt:=1;
       Continue;
      end;
     if Field[X, Y].Kind = LastKind then Inc(LastCnt);
     if (Field[X, Y].Kind = LastKind) and (Y = FHeight) then Match.Add(Point(X, Y));
     if (Field[X, Y].Kind <> LastKind) or (Y = FHeight) then
      begin
       if LastCnt >= MinMatch then IncMatch(LastCnt);
       Match.Clear;
       LastCnt:=1;
      end;
     LastKind:=Field[X, Y].Kind;
     Match.Add(Point(X, Y));
    end;
  end;

 Match.Free;
 MatchField;
end;

function RandomCell:TCell;
begin
 Result.Speed:=1;
 Result.RandomKind;
 Result.Color:=KindColor[Result.Kind];
 Result.Empty:=False;
 Result.Hole:=False;
 Result.ArrayPos:=Point(0, 0);
end;

procedure TFormMain.CreateField;
var Y, X: Integer;
    Cell:TCell;
begin
 for X:=1 to FWidth do
  for Y:=1 to FHeight do
   begin
    Cell:=RandomCell;
    Cell.UpdatePos(Point(X, Y));
    Field[X, Y]:=Cell;
   end;
 CheckField;
end;

procedure TFormMain.CreateWnd;
begin
 inherited;
 FCanvas:=TDirect2DCanvas.Create(Handle);
end;

procedure TFormMain.DrawField;
var X, Y:Integer;
    FRect:TRect;
    Str:string;
begin
 with Canvas do
  begin
   for X:= 0 to FWidth-1 do
    for Y:= 0 to FHeight-1 do
     begin
      if Field[X+1, Y+1].Hole then Continue;

      //Сетка
      Brush.Style:=bsSolid;
      Brush.Color:=clGray;//+100*(w xor h);

      FRect:=Rect(0, 0, FSize, FSize);
      FRect.SetLocation(X*FSize, Y*FSize);
      FRect.Offset(FBorders.Left, FBorders.Top);

      //FRect.Inflate(-1, -1);
      if (not FGameCur.OutOf) and (FGameCur.Cell.ArrayPos = Point(X+1, Y+1)) then
       begin
        FillRect(FRect, 0.1);
       end
      else
       begin
        FillRect(FRect, 0.1);
       end;

      //Элементы
      if not Field[X+1, Y+1].Empty then
       begin
        Brush.Color:=Field[X+1, Y+1].Color;
        FRect:=Rect(0, 0, FSize, FSize);
        FRect.SetLocation(Field[X+1, Y+1].Position.iX, Field[X+1, Y+1].Position.iY);
        FRect.Offset(FBorders.Left, FBorders.Top);

        FRect.Inflate(-2, -2);
        FillRect(FRect, 0.9);
       end;

      Str:=IntToStr((CalcField[X+1, Y+1].Value));
      TextRect(FRect, Str, [tfVerticalCenter, tfSingleLine, tfCenter]);
     end;
  end;
end;

procedure TFormMain.DrawBG;
var Rec:TRect;
begin
 with Canvas do
  begin
   FBGAng:=FBGAng+1;
   if FBGAng >= 360 then FBGAng:=0;

   Rec:=Rect(0, 0, 500, 500);
   Brush.Color:=clMaroon;
   Rec.Offset(30, 90);
   RenderTarget.SetTransform(TD2DMatrix3x2F.Rotation(30+FBGAng, Rec.CenterPoint));
   FillRect(Rec, 0.1);

   Rec:=Rect(0, 0, 100, 100);
   Brush.Color:=clGreen;
   Rec.Offset(90, 300);
   RenderTarget.SetTransform(TD2DMatrix3x2F.Rotation(10-FBGAng, Rec.CenterPoint));
   FillRect(Rec, 0.1);

   Rec:=Rect(0, 0, 200, 200);
   Brush.Color:=clYellow;
   Rec.Offset(200, 100);
   RenderTarget.SetTransform(TD2DMatrix3x2F.Rotation(100+FBGAng, Rec.CenterPoint));
   FillRect(Rec, 0.1);

   Rec:=Rect(0, 0, 100, 100);
   Brush.Color:=clBlue;
   Rec.Offset(120, 20);
   RenderTarget.SetTransform(TD2DMatrix3x2F.Rotation(50-FBGAng, Rec.CenterPoint));
   FillRect(Rec, 0.1);

   RenderTarget.SetTransform(TD2DMatrix3x2F.Identity());
  end;
end;

procedure TFormMain.DoDraw;
begin
 DrawBG;
 DrawField;
end;

procedure TFormMain.FormCreate(Sender: TObject);
var Y, X: Integer;
    Cell:TCell;
begin
 for X:=1 to FWidth do
  for Y:=1 to FHeight do
   begin
    FField[Y, X]:=FreeCell;
    FField[Y, X].Hole:=True;
   end;
 FFPS:=0;
 FPSCounter:=0;
 FreeCell.Speed:=1;
 FreeCell.ArrayPos:=Point(0, 0);
 FreeCell.UpdatePos(Point(0, 0));
 FreeCell.Empty:=True;
 FreeCell.Hole:=False;
 TimerRepaint.Enabled:=True;
 FBorders:=Rect(30, 30, 30, 30+PanelCtrl.Height);
 ClientWidth:=FBorders.Left+FBorders.Right+FWidth*FSize;
 ClientHeight:=FBorders.Top+FBorders.Bottom+FHeight*FSize;
end;

procedure TFormMain.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if not FGameCur.OutOf then
  begin
   FGameCur.Down:=True;
   FSelCell:=FGameCur.Cell;
   Exit;
  end;
end;

function GetDirect(SPos, EPos:TPoint):TDirect;
var XD, YD:TDirect;
begin
 Result:=tdNone;
 if SPos = EPos then Exit;
 if SPos.X > EPos.X then XD:=tdLeft else XD:=tdRight;
 if SPos.Y > EPos.Y then YD:=tdUp else YD:=tdDown;
 if Abs(SPos.X - EPos.X) > Abs(SPos.Y - EPos.Y) then Result:=XD else Result:=YD;
end;

procedure TFormMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var NP:TPoint;
begin
 if (X-FBorders.Left < 0) or (Y-FBorders.Left < 0) or ((X-FBorders.Left) div FSize + 1 > FWidth) or ((Y-FBorders.Left) div FSize + 1 > FHeight) then
  begin
   FGameCur.OutOf:=True;
   FGameCur.Cell:=FreeCell;
  end
 else
  begin
   FGameCur.OutOf:=False;
   FGameCur.Cell:=Field[(X-FBorders.Left) div FSize + 1, (Y-FBorders.Left) div FSize + 1];
   if FGameCur.Down and (FGameCur.Cell.ArrayPos <> FSelCell.ArrayPos) then
    begin
     FGameCur.Down:=False;
     if MoveCell(FSelCell.ArrayPos, GetDirect(FGameCur.FLastPos, Point(X, Y)), NP) then
      begin
       FSelCell:=Field[NP.X, NP.Y];
      end;
    end;
  end;
 FGameCur.FLastPos:=Point(X, Y);
end;

procedure TFormMain.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if not FGameCur.OutOf then
  begin
   if FGameCur.Down then
    begin
     FGameCur.Down:=False;
    end;
  end;
end;

procedure TFormMain.FormPaint(Sender: TObject);
var Stamp:Cardinal;
begin
 with Canvas do
  begin
   Stamp:=GetTickCount;
   RenderTarget.BeginDraw;
   RenderTarget.SetTransform(TD2DMatrix3x2F.Identity());
   Brush.Color:=$00FFFAD9;
   Brush.Style:=bsSolid;
   FillRect(ClientRect);
   DoDraw;
   Brush.Style:=bsClear;
   Stamp:=GetTickCount-Stamp;
   TextOut(2, 2, IntToStr(FFPS)+' fps'+#13#10'Задержка '+IntToStr(Stamp)+' мс');
   RenderTarget.EndDraw;
  end;
 FPSCounter:=FPSCounter + 1;
end;

function TFormMain.GetCalcCell(X, Y: Integer): TCalcCell;
begin
 Result:=FCalcField[Y, X];
end;

function TFormMain.GetCell(X, Y: Integer):TCell;
begin
 Result:=FField[Y, X];
end;

function TFormMain.MoveCell(CellPos:TPoint; Direct:TDirect; var NewPos:TPoint):Boolean;
var Buf:TCell;
begin
 Result:=False;
 NewPos:=CellPos;
 case Direct of
  tdNone: Exit;
  tdLeft:
   begin
    if CellPos.X-1 < 1 then Exit;
    NewPos:=Point(CellPos.X-1, CellPos.Y);
   end;
  tdRight:
   begin
    if CellPos.X+1 > FWidth then Exit;
    NewPos:=Point(CellPos.X+1, CellPos.Y);
   end;
  tdUp:
   begin
    if CellPos.Y-1 < 1 then Exit;
    NewPos:=Point(CellPos.X, CellPos.Y-1);
   end;
  tdDown:
   begin
    if CellPos.Y+1 > FHeight then Exit;
    NewPos:=Point(CellPos.X, CellPos.Y+1);
   end;
 end;
 if Field[NewPos.X, NewPos.Y].NoMatch then
  begin
   NewPos:=CellPos;
   Exit;
  end;
 Buf:=Field[NewPos.X, NewPos.Y];
 Field[NewPos.X, NewPos.Y]:=Field[CellPos.X, CellPos.Y];
 Field[CellPos.X, CellPos.Y]:=Buf;
 Result:=True;
end;

procedure TFormMain.NewGame;
begin
 Application.ProcessMessages;
 FScore:=0;
 Moving:=False;
 CreateField;
end;

procedure TFormMain.SetCalcCell(X, Y: Integer; const Value: TCalcCell);
begin
 FCalcField[Y, X]:=Value;
end;

procedure TFormMain.SetCell(X, Y: Integer; const Value: TCell);
begin
 FField[Y, X]:=Value;
 FField[Y, X].UpdatePos(Point(X, Y));
end;

procedure TFormMain.TimerAnimateTimer(Sender: TObject);
var X, Y:Integer;
    AllNot:Boolean;
begin
 AllNot:=True;
 for X:= 1 to FWidth do
  for Y:= 1 to FHeight do
   begin
    if FField[Y, X].Step then AllNot:=False;
   end;
 if Moving and (AllNot) then
  begin
   CheckField;
  end;
 if AllNot then Moving:=False else Moving:=True;
end;

procedure TFormMain.TimerFPSTimer(Sender: TObject);
begin
 FFPS:=FPSCounter;
 FPSCounter:=0;
end;

procedure TFormMain.WMSize(var Message: TWMSize);
var D2Size:D2D_SIZE_U;
begin
 D2Size:=D2D1SizeU(ClientWidth, ClientHeight);
 if Assigned(FCanvas) then ID2D1HwndRenderTarget(FCanvas.RenderTarget).Resize(D2Size);
 inherited;
end;

{ TDirect2DCanvasHelper }

procedure TDirect2DCanvasHelper.FillRect(const Rect:TRect; Opacity:Single);
var RT:D2D_RECT_F;
    BR:ID2D1Brush;

function ImplicitRect(AValue:TRect):D2D_RECT_F;
begin
 Result.top := AValue.Top;
 Result.left := AValue.Left;
 Result.bottom := AValue.Bottom;
 Result.right := AValue.Right;
end;

begin
 RT:=ImplicitRect(Rect);
 BR:=CreateBrush(Brush.Color);
 BR.SetOpacity(Opacity);
 RenderTarget.FillRectangle(RT, BR);
end;

{ TExtPoint }

class function TExtPoint.Create(X, Y: Single): TExtPoint;
begin
 Result.X:=X;
 Result.Y:=Y;
end;

class operator TExtPoint.Equal(const Lhs, Rhs: TExtPoint): Boolean;
begin
  Result := (Lhs.X = Rhs.X) and (Lhs.Y = Rhs.Y);
end;

class operator TExtPoint.NotEqual(const Lhs, Rhs: TExtPoint): Boolean;
begin
  Result := (Lhs.X <> Rhs.X) or (Lhs.Y <> Rhs.Y);
end;

function TExtPoint.GetX: Integer;
begin
 Result:=Round(X);
end;

function TExtPoint.GetY: Integer;
begin
 Result:=Round(Y);
end;

{ TCell }

function TCell.GetNoMatch: Boolean;
begin
 Result:=Empty or Hole;
end;

function TCell.GetNormal: Boolean;
begin
 Result:=not Empty and not Hole;
end;

procedure TCell.RandomKind;
begin
 Kind:=Random((High(TCellKind)+1)-Low(TCellKind))+Low(TCellKind);
end;

function TCell.Step:Boolean;
const SSize = 5;
begin
 Result:=False;
 if Position = NeedPos then Exit;
 Speed:=Speed+1;
 if Position.X < NeedPos.X then Position.X:=Position.X + Speed;
 if Position.X > NeedPos.X then Position.X:=Position.X - Speed;
 if Abs(Position.X - NeedPos.X) < Speed then Position.X:=NeedPos.X;

 if Position.Y < NeedPos.Y then Position.Y:=Position.Y + Speed;
 if Position.Y > NeedPos.Y then Position.Y:=Position.Y - Speed;
 if Abs(Position.Y - NeedPos.Y) < Speed then Position.Y:=NeedPos.Y;

 if Position = NeedPos then Speed:=1;
 Result:=True;
end;

procedure TCell.UpdatePos;
var St:Boolean;
begin
 St:=ArrayPos = Point(0, 0);
 ArrayPos:=Point(Pos.X, Pos.Y);
 //Position:=TExtPoint.Create((Pos.X-1)*FSize, (Pos.Y-1)*FSize);
 NeedPos:=TExtPoint.Create((Pos.X-1)*FSize, (Pos.Y-1)*FSize);
 if St then Position:=NeedPos;
 Step;
end;

{ TCalcCell }

function TCalcCell.Inc: Integer;
begin
 Value:=Value+1;
 Result:=Value;
end;

end.

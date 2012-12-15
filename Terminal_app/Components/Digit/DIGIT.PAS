unit Digit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls;
type
  Tdigit = class(Timage)
  private
    { Private declarations }
    FThinc:integer;
    Fwidth:integer;
    Foutstr:string;
    Fdigcount:integer;
    FBkcolor:Tcolor;
    FLcolor:Tcolor;
    FDcolor:Tcolor;
    Fusevalue:boolean;
    Procedure SetUseValue(V:boolean);
    Procedure SetCaption(V:string);
    Procedure Setwidth(V:integer);
    Procedure Setcount(V:integer);
    Procedure SetBkcolor(V:Tcolor);
    Procedure SetLcolor(V:Tcolor);
    Procedure SetDcolor(V:Tcolor);
    Procedure Setvalue(V:longint);
    Function Getvalue:longint;
    {Procedure Setwidthi(V:integer);}
  protected
    { Protected declarations }
    Procedure Repaint;virtual;
    {Procedure Resize(var Message: TMessage); message WM_Paint;}
  public
    { Public declarations }
    Constructor Create(AOwner: TComponent);override;
  published
    { Published declarations }
    Property Caption:string read FOutstr write SetCaption;
    Property UseValue:boolean read Fusevalue write SetUseValue;
    Property DigWidth:integer read Fwidth write Setwidth;
    Property DigCount:integer read Fdigcount write Setcount;
    Property Backcolor:Tcolor read Fbkcolor write SetBkcolor;
    Property Lightcolor:Tcolor read FLcolor write SetLcolor;
    Property Darkcolor:Tcolor read FDcolor write SetDcolor;
    Property Value:Longint read getvalue write SetValue;
    {Property width:integer read Fwidthi write SetWidthi;
    Property Height:integer read FHeight write SetHeight;}
  end;

procedure Register;

implementation
const digitimage:array[0..28] of byte = ($3F,$06,$5B,$4F,$66,$6D,$7D,$07,
                                         $7F,$6F,$77,$7C,$39,$5E,$79,$71,
                                         64 ,118, 46, 84, 92,115,120, 28,
                                         110, 73, 48, 55, 80);
{0123456789ABCDEF-HLnoPtuY#|^r}
Function isbit(V,Nbit:byte):boolean;
 begin isbit:=(V and (1 shl Nbit))<>0;end;
Function Digitconv(ch:Char):integer;
 begin
  Digitconv:=-1;
  Case Upcase(Ch) of
   '0'..'9':Digitconv:=ord(Ch)- 48;
   'A'..'F':Digitconv:=ord(Upcase(Ch))- 55;
   '-':Digitconv:=16;
   'H':Digitconv:=17;
   'L':Digitconv:=18;
   'N':Digitconv:=19;
   'O':Digitconv:=20;
   'P':Digitconv:=21;
   'T':Digitconv:=22;
   'U':Digitconv:=23;
   'Y':Digitconv:=24;
   '#':Digitconv:=25;
   '|':Digitconv:=26;
   '^':Digitconv:=27;
   'R':Digitconv:=28;
  end;
 end;
procedure Register;
begin
  RegisterComponents('Digit', [Tdigit]);
end;
Procedure Tdigit.repaint;
 {Foutstr:='1234';
  Fdigcount:=4;
  Fwidth:=45;
  FThinc:=Fwidth div 5;}
 Var i,ii:byte;Ti:integer;St:string;
 begin
  with canvas do
   begin
    brush.color:=Fbkcolor;
    fillrect(rect(0,0,width,Height));
   end;
  fillchar(St,Sizeof(St),0);
  St:=Foutstr;
  for i:=0 to Fdigcount-1 do
  with canvas do
    begin
     if st[i+1]='.' then delete(st,i,1);
     Ti:=digitconv(st[i+1]);
     if Ti>=0 then ii:=digitimage[Ti]
              else ii:=0;
     if st[i+2]='.' then ii:=ii or 128;
     if st[i+1]=' ' then ii:=0;
     if st[i+1]=':' then
     with canvas do
      begin
       brush.color:=FLcolor;
       ellipse(i*(5*FThinc+Fwidth)+(-FThinc+Fwidth) div 2,(-FThinc+Fwidth) div 2
              ,i*(5*FThinc+Fwidth)+FThinc+(FThinc+Fwidth) div 2,(3*FThinc+Fwidth) div 2);
       ellipse(i*(5*FThinc+Fwidth)+(-FThinc+Fwidth) div 2,(FThinc+3*Fwidth) div 2
              ,i*(5*FThinc+Fwidth)+FThinc+(FThinc+Fwidth) div 2,(5*FThinc+3*Fwidth) div 2);
       Continue;
      end;
         {        x               y        x2                 y2}
     if isbit(ii,0) then brush.color:=FLcolor else brush.color:=FDcolor;
    {A}  fillrect(rect(FThinc+i*(5*FThinc+Fwidth)  ,0
          ,FThinc+Fwidth+i*(5*FThinc+Fwidth)  ,FThinc      ));

     if isbit(ii,6) then brush.color:=FLcolor else brush.color:=FDcolor;
    {G}  fillrect(rect(FThinc+i*(5*FThinc+Fwidth),FThinc+Fwidth
          ,FThinc+Fwidth+i*(5*FThinc+Fwidth)  ,2*FThinc+Fwidth  ));

     if isbit(ii,3) then brush.color:=FLcolor else brush.color:=FDcolor;
    {D}  fillrect(rect(FThinc+i*(5*FThinc+Fwidth),2*(FThinc+Fwidth)
          ,FThinc+Fwidth+i*(5*FThinc+Fwidth)  ,3*FThinc+2*Fwidth));

     if isbit(ii,5) then brush.color:=FLcolor else brush.color:=FDcolor;
    {F}  fillrect(rect( i*(5*FThinc+Fwidth)   ,FThinc
          ,FThinc+i*(5*FThinc+Fwidth)    ,FThinc+Fwidth    ));

     if isbit(ii,4) then brush.color:=FLcolor else brush.color:=FDcolor;
    {E}  fillrect(rect( i*(5*FThinc+Fwidth)   ,2*FThinc+Fwidth
          ,FThinc+i*(5*FThinc+Fwidth)    ,2*(FThinc+Fwidth)));

     if isbit(ii,1) then brush.color:=FLcolor else brush.color:=FDcolor;
    {B}  fillrect(rect(FThinc+Fwidth+i*(5*FThinc+Fwidth),FThinc
          ,2*FThinc+Fwidth+i*(5*FThinc+Fwidth),FThinc+Fwidth    ));

     if isbit(ii,2) then brush.color:=FLcolor else brush.color:=FDcolor;
    {C}  fillrect(rect(FThinc+Fwidth+i*(5*FThinc+Fwidth),2*FThinc+Fwidth
          ,2*FThinc+Fwidth+i*(5*FThinc+Fwidth),2*(FThinc+Fwidth)));

     if isbit(ii,7) then brush.color:=FLcolor else brush.color:=FDcolor;
    {H}
    fillrect(rect(3*FThinc+Fwidth+i*(5*FThinc+Fwidth),FThinc+2*Fwidth
          ,4*FThinc+Fwidth+i*(5*FThinc+Fwidth),3*FThinc+2*Fwidth));
    end;
 end;
Constructor Tdigit.Create(AOwner: TComponent);
 begin
  inherited Create(AOwner);
   Fusevalue:=False;
   Foutstr:='00:00';
   Fdigcount:=5;
   Fwidth:=20;
   FThinc:=Fwidth div 6;
   FBkColor:=Clbtnface;
   FLcolor:=$000FFF0F;{Light Green}
   FDcolor:=Clbtnface;
   width:=Fdigcount*(Fwidth+5*FThinc);
   Height:=2*Fwidth+3*FThinc;
   Center:=true;
{========================================}
   repaint;
try
   picture.Graphic.width:=Fdigcount*(Fwidth+5*FThinc);
   picture.Graphic.Height:=2*Fwidth+3*FThinc+1;
{========================================}
except
 Showmessage('Exception 1');
 Raise;
 end;
 end;
Procedure Tdigit.SetCaption(V:string);
 begin
  if V='' then Foutstr:=' ' else
  Foutstr:=V;
  repaint;
 end;
Procedure Tdigit.Setwidth(V:integer);
 begin
  Fwidth:=V;
  FThinc:=Fwidth div 5;
  repaint;
  picture.Graphic.width:=Fdigcount*(Fwidth+5*FThinc);
  picture.Graphic.Height:=2*Fwidth+3*FThinc+1;
 end;
Procedure Tdigit.setusevalue(V:boolean);
 begin
  Fusevalue:=v;
 end;
Procedure Tdigit.Setcount(V:integer);
 begin
  if (V>0) and (v<100) then FDigcount:=V;
  picture.Graphic.width:=Fdigcount*(Fwidth+5*FThinc);
  picture.Graphic.Height:=2*Fwidth+3*FThinc+1;
  repaint;
 end;
Procedure Tdigit.SetBkcolor(V:Tcolor);
 begin
  Fbkcolor:=v;
  repaint;
 end;
Procedure Tdigit.SetLcolor(V:Tcolor);
 begin
  Flcolor:=v;
  repaint;
 end;
Procedure Tdigit.SetDcolor(V:Tcolor);
 begin
  FDcolor:=v;
  repaint;
 end;
Function Tdigit.Getvalue:longint;
var v:longint;e:integer;
 begin
  val(Foutstr,V,e);
  Getvalue:=v;
 end;
Procedure Tdigit.Setvalue(V:longint);
 begin
 if Fusevalue then
  begin
    Str(V:Fdigcount,Foutstr);
    Repaint;
  end;
 end;
 {width:=Fdigcount*(Fwidth+3*FThinc);
  Height:=2*Fwidth+3*FThinc;}
{Procedure Tdigit.Setwidthi(V:integer);
 begin
  Fwidth:=round(V/(Fdigcount*(1+3/5)));
  {3 - Учёт толщин сегментов с точкой (1)}
  {5 - коэфициент толщины сегмента (1/5 от толщины)}
{  Fthinc:=Fwidth div 5;
  Fwidthi:=FDigcount*(Fwidth+3*FThinc);
  FHeight:=2*Fwidth+3*FThinc;
  inherited Height:=Fheight;
  inherited Width:=Fwidthi;
 end;}
end.

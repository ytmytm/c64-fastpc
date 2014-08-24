
program WinFastPC;

uses WinCrt, WinTypes, WinProcs, OWindows, ODialogs;

const
  id_ST0 = 100;
  id_ST1 = 101;
  id_ST2 = 102;
  id_STtrans  = 200;
  id_STstatus = 201;
  id_STaction = 202;

const
  REUSize = 32;

var
   ST0,ST1,ST2       :PStatic;
   Rozkaz            :byte;
   TransSize         :array [0..1] of word;
   Packets,RestByte  :byte;
   raz:byte;
   dwa:longint;
   REU               :file;
   buff              :array[0..255] of byte;
   stream            :byte;

type

  WFPCApplication = object(TApplication)
    procedure InitMainWindow; virtual;
    function IdleAction:boolean; virtual;
  end;

  PWFPCWindow = ^WFPCWindow;
  WFPCWindow = object(TWindow)
    constructor Init(AParent: PWindowsObject; ATitle: PChar);
    procedure WMLButtonDown(var Msg: TMessage);
      virtual wm_First + wm_LButtonDown;
  end;

{----------------------------}
{ FastPC implementation      }
{----------------------------}

var Connect:boolean;

procedure LostCarrier;
begin
  Connect:=false;
  ST0^.SetText('Waiting for sync...');
end;

function MakeWord(lo,hi:byte) :word;
var val:word;
begin asm
  mov al, lo
  mov ah, hi
  mov val,ax
  end;
  MakeWord:=val;
end; {MakeWord}

procedure SendStrobe;
var a,b:byte;
begin
  a:=Port[$37a];
  a:=a and $fe;
  b:=a or 1;
  Port[$37a]:=b;
  Port[$37a]:=a;
end;

procedure SendByte(val:byte);
var a:byte;
begin
  a:=val;
  port[$37a]:=0;
  repeat until ((port[$379] and $40)=0);
  port[$378]:=a;
  SendStrobe;
  repeat until ((port[$379] and $40)=$40);
  SendStrobe;
end;

function GetByte :byte;
var a:byte;
begin
  port[$37a]:=$20;
  repeat until ((port[$379] and $40)=0);
  a:=port[$378];
  SendStrobe;
  repeat until ((port[$379] and $40)=$40);
  GetByte:=a;
  SendStrobe;
end;

procedure Wait4Start;
var a:byte;
begin
  port[$37a]:=$20;
  repeat until ((port[$378]=$0f) and ((port[$379] and $40)=0));
  SendStrobe;
  repeat until ((port[$379] and $40)=$40);
  SendStrobe;
end;

procedure HandleWait; assembler;  { Waits for Wait4Start, answers and sets Connection}
asm
  mov Connect, 0
  mov dx, 37ah          { Data port as input, disable IRQ7, /STROBE high}
  mov al, 00100000b
  out (dx),al
  dec dx
  dec dx

  in  al, (dx)          { Wait until /ACK=LOW        }
  mov ah, al            { and DATA=$0f               }
  inc dx
  in  al, (dx)
  dec dx
  and al, 01000000b
  or  ah, al
  cmp ah, 00001111b
  jne @NotYet

  call SendStrobe       { Confirm it                 }
  dec dx
@loop2:
  in  al, (dx)          { Wait until confirmation is }
  and al, 01000000b     { confirmed by /ACK set HIGH }
  jz  @loop2
  call SendStrobe       { Final confirmation         }
  inc Connect           { Set indicator              }

@NotYet:
end;

procedure ReceivePacket;
var i:byte;
begin
  for i:=0 to Stream do buff[i]:=GetByte;
end;

procedure SendPacket;
var i:byte;
begin
  for i:=0 to Stream do SendByte(buff[i]);
end;


function ProcessPacket :boolean;
var by:integer;
begin
    if Packets=0 then Stream:=RestByte else Stream:=255;
    case Rozkaz of
    144: begin ReceivePacket; BlockWrite(REU,buff,Stream+1); end;
    145: begin BlockRead(REU,buff,Stream+1,by); SendPacket; end;
    147: begin BlockRead(REU,buff,Stream+1,by); SendPacket; end;
    160: begin ReceivePacket; BlockWrite(REU,buff,Stream+1); end;
    161: begin SendPacket; end;
    end;
    dec(Packets);
    if Packets=255 then ProcessPacket:=true else ProcessPacket:=false;
end;

procedure TestHandle;
begin
  Seek(REU,0);
  Packets:=2; RestByte:=255;
end;

procedure HandleREU;

procedure HandleStash;
begin
  ST2^.SetText('Stashing...');
end;

procedure HandleFetch;
begin
  ST2^.SetText('Fetching...');
end;

procedure HandleSwap;
begin
  ST2^.SetText('Swapping...');
end;

var L,H:byte; temp:word;
    REULen:word; REUAddy:longint;
    stt:array [0..39] of char;
begin
  L:=GetByte; H:=GetByte;
  temp:=MakeWord(L,H);            {REU address word}

  L:=GetByte; H:=GetByte;
  REULen:=MakeWord(L,H);          {REU length word}
  if REULen=0 then begin ST1^.SetText('B³¹d - zerowa d³ugoœæ'); LostCarrier; exit; end;
  dec(REULen);
  TransSize[0]:=hi(REULen); TransSize[1]:=lo(REULen);
  Packets:=hi(REULen); RestByte:=lo(REULen);
  L:=GetByte;
  REUAddy:=L;
   if REUAddy>REUSize then begin ST1^.SetText('B³¹d - bank nie istnieje'); LostCarrier; exit; end;
  REUAddy:=(REUAddy shl 16)+temp;     {REU address + #bank * 64K}
  Seek(REU,REUAddy);             {Set REU address in file}
  WVSPrintF(stt,'REU: %i pakietów i %i bajtów',TransSize);
  ST1^.SetText(stt);

  case (Rozkaz and 7) of
           0: HandleStash;
           1: HandleFetch;
           2: HandleSwap;
           3: HandleFetch;
  end;
end;

{--------------------------------------------------}
{ Window's method implementations:                 }
{--------------------------------------------------}

constructor WFPCWindow.Init(AParent: PWindowsObject; ATitle: PChar);

begin
  inherited Init(AParent, ATitle);
  ST0 := New(PStatic, Init(@Self, id_ST0, 'Transfer:', 20, 20, 150, 24, 0));
  ST0 := New(PStatic, Init(@Self, id_STtrans, 'Waiting for sync', 90, 20, 200, 24, 0));
  ST1 := New(PStatic, Init(@Self, id_ST1, 'Status:', 20, 50, 150, 24, 0));
  ST1 := New(PStatic, Init(@Self, id_STstatus, 'OK', 90, 50, 250, 24, 0));
  ST2 := New(PStatic, Init(@Self, id_ST2, 'Action:', 20, 80, 150, 24, 0));
  ST2 := New(PStatic, Init(@Self, id_STaction, 'Waiting', 90, 80, 200, 24, 0));
  LostCarrier;
end;

procedure WFPCWindow.WMLButtonDown(var Msg: TMessage);
begin
  ST2^.SetText('DupaMaryni');
end;


{--------------------------------------------------}
{ Application's method implementations:            }
{--------------------------------------------------}

procedure WFPCApplication.InitMainWindow;
var TimeProc:TFarProc;
begin
  MainWindow := New(PWFPCWindow, Init(nil, 'WinFastPC'));
end;

function WFPCApplication.IdleAction:boolean;

begin
  IdleAction:=true;
  if not Connect then begin
     HandleWait;
     if Connect then begin
        Rozkaz:=GetByte;
        ST0^.SetText('Got carrier signal');
        if (Rozkaz and 128)=128 then {bit 7=1 - order}
          case (Rozkaz and 120) of
            {8: DoDriveEmu   {bit 3=1}
            16: HandleREU;{DoReu;       {bit 4=1}
            32: TestHandle;{DoTransDisk; {bit 5=1}
            64: inc(dwa);{DoTransFile; {bit 6=1}
          end else LostCarrier;
        {LostCarrier; {don't process data}
     end;
  end else begin
      if ProcessPacket then begin LostCarrier; ST2^.SetText('Waiting'); ST1^.SetText('OK'); end;
      end;
end;
{--------------------------------------------------}
{ Main program:                                    }
{--------------------------------------------------}

var
  WFPCApp : WFPCApplication;
  i:longint; a,q:byte;
begin
  {$I-}
  assign(REU,'REU.c64');
  reset(REU,1);
  {$I+}
  if IOResult <> 0 then
         begin rewrite(REU,1); close(REU); assign(REU,'REU.c64'); reset(REU,1);
         seek(REU,((REUSize * 256 * 256)-1)); BlockWrite(REU,buff,1); reset(REU,1);
         end;
  WFPCApp.Init('WinFastPC');
  WFPCApp.Run;
  WFPCApp.Done;
  close(REU);
end.
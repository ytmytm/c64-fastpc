
{FastPC server by Maciej 'YTM/Alliance' Witkowiak}


{Structure of the order byte:
 bit 7=1 - an order is sent
      =0 - quit/not an order yet/for future use
           (kind of one-way terminal for messages from C64/128)
     6=1 - file activity
     5=1 - disk activity
     4=1 - REU  activity
     3=1 - drive emulator activity
   2,1,0 - type of activity (read/write/swap)
           file:0 0-send to C64, 1-receive
                1 0-C64/128 mode, 1-CP/M mode }

{To do:
 - CP/M file sending
 - ACE file sending (w/ dir)
 - REU emulation
 - truncated dynamic memory allocation for large CP/M files (send/receive)
}

{ACE (UNIX) U: device:
 #230, length:word, [data]
 if lenght=0 -> end-of-file
 }

{REU emulation
 - use dynamic variables
 - count lo/hi addres (14/6 bits)
 - check transmission}

uses Dos;

{$IFDEF REU}
const REUSize=32;        { Number of REU banks - x64K: 8-512K; 32-2048K}
{$ENDIF}

const
  version       = '0.9';

  err_ESC       = 0;
  err_dskRc     = 1;
  err_ACERc     = 2;
  err_REULg     = 3;
  err_REUBk     = 4;

type buff=array[1..62000] of byte;
     half=array[0..32768] of byte;

var Rozkaz,test:byte;
    {$IFDEF REU}
    REU                 :file of byte;
    REUTab              :array[0..REUSize*2] of ^half;
    {$ENDIF}

procedure DoError(errcode:byte);
begin
  case errcode of
  err_ESC:   begin writeln ('Aborted by user.'); halt(err_ESC); end;
  err_dskRc: begin writeln (#13#10,'Error - track number is different than expected.'); halt(err_dskRc); end;
  err_ACERc: begin writeln ('Error - ACE transfer [w/o EOF]'); halt(err_ACERc); end;
  err_REULg: begin writeln ('Error - REU transfer length =0'); halt(err_REULg); end;
  err_REUBk: begin writeln ('Error - REU bank number too big'); halt(err_REUBk); end;
  end;
end;

procedure ClrScr;assembler;
asm
  mov ah,7
  mov al,0
  mov bh,7
  mov ch,0
  mov cl,0
  mov dh,24
  mov dl,79
  int $10
  mov ah,2
  mov bh,0
  mov dl,0
  mov dh,0
  int $10
end;

procedure ShowDirectory;
begin
      ClrScr;
      SwapVectors;
      Exec(GetEnv('COMSPEC'), '/C dir /w/og');
      SwapVectors;
      if DosError <> 0 then
        WriteLn('Could not execute COMMAND.COM');
      WriteLn;
end;

function MakeWord(lo,hi:byte) :word; assembler;
asm
  mov al, lo
  mov ah, hi
end; {MakeWord}


{************************************************************************}
{Interrupt handling procedures                                           }
{                                                                        }

var OldVec      :procedure;
    OldVect     :pointer;

procedure GetIntVec(IntNo: Byte; var Vector: Pointer); assembler;
asm
  mov   al,IntNo
  mov	ah,35h
  int	21h
  mov	ax,es
  les	di,Vector
  cld
  xchg	ax,bx
  stosw
  xchg	ax,bx
  stosw
end;

procedure SetIntVec(IntNo: Byte; Vector: Pointer); assembler;
asm
  push	ds
  lds	dx,Vector
  mov	al,IntNo
  mov	ah,25h
  int	21h
  pop	ds
end;

procedure DisableInt(Interr : byte; var Save_Vec : pointer);
var
  Data : byte;
begin
  if Interr<8 then begin
    SetIntVec(Interr+8,Save_Vec);
    Data:=port[$21];
    port[$21]:=Data or (1 shl Interr);
    end
  else begin
    SetIntVec(Interr+$68,Save_Vec);
    Data:=port[$A1];
    port[$A1]:=Data or (1 shl (Interr-8));
       end;
end; {DisableInt}

procedure EnableInt(Interr : byte; IRQHandler : pointer;var Save_Vec : pointer);
var
  Data : byte;
begin
  GetIntVec(Interr+8,Save_Vec);
  SetIntVec(Interr+8,IRQHandler);
  Data:=port[$21];
  port[$21]:=Data and ($FF xor (1 shl Interr));
end; {EnableInt}

{$F+}
procedure IntProc; interrupt; assembler;
asm mov test, 1
    mov al, 20h
    out (20h),al
end;
{$F-}

procedure InitInterrupts;
begin
  GetIntVec(7+8,@OldVec);
  EnableInt(7,@IntProc,OldVect);
end;

procedure DoneInterrupts;
begin
  DisableInt(7,OldVect);
end;

{************************************************************************}

{************************************************************************}
{FastPC I/O procedures                                                   }
{if test=$ff => ESC was pressed                                          }
{                                                                        }

var val :byte;

procedure InitFPC; assembler;
asm
  mov dx, 37ah          { Get ControlPort addy   }
  mov al, 00110000b     { Enable input&irq7      }
  out (dx), al
  mov al, 20h           { confirm interrupt -    }
  out (20h),al          { just in case           }
  mov test, 0           { init this too          }
end; {InitFPC}

procedure SendStrobe; assembler;
asm
  mov dx, 37ah          { Get ControlPort addy   }
  in  al,(dx)           { Read current           }
  and al,11111110b      { Preserve all but /STRB }
  mov bl,al             { Preserve inactive      }
  or  al,00000001b      { Set /STROBE to active  }
  out (dx),al           { Send out               }
  mov al,bl             { Restore inactive       }
  out (dx),al           { Send out               }
end; {SendStrobe}

function IOGetByte:byte; assembler;
asm
  mov dx, 37ah          { Get ControlPort addy   }
  mov al, 00110000b     { Set as input&enable IRQ}
  out (dx), al
@Loop:
  in  al, 60h           { ESC?                   }
  dec al
  jz  @ESC
  cmp test, 1           { Is there anything on   }
  jne @Loop             { wires?                 }
  mov dx, 378h          { Get Data               }
  in  al,(dx)
  mov ah, al
  mov test, 0           { Everything done        }
  call SendStrobe       { Confirm receiving      }
  mov al, ah            { Return value           }
  jmp @Fin
@ESC:
  mov test, 0ffh        { Marker - ESC occured   }
@Fin:
end; {IOGetByte}

procedure IOSendByte(by:byte); assembler;
asm
  mov dx, 37ah          { Get ControlPort addy   }
  mov al, 00010000b     { Set as output&enble IRQ}
  out (dx), al
  mov dx, 378h          { Sendout data           }
  mov al, by
  out (dx), al
  mov test, 0           { Clear the marker       }
  call SendStrobe       { Data is ready - inform }
@Loop:
  in  al, 60h           { ESC? }
  dec al
  jz  @ESC
  cmp test, 1           { Receiving confirmed?   }
  je @Fin
  jmp @Loop
@ESC:
  mov test, 0ffh        { Marker - ESC occured   }
@Fin:
end; {IOSendByte}

function FPCGetByte:byte; begin FPCGetByte:=IOGetByte;
if test=$ff then begin DoneInterrupts; DoError(err_ESC); end; end;

procedure FPCSendByte(by:byte); begin IOSendByte(by);
if test=$ff then begin DoneInterrupts; DoError(err_ESC); end; end;

{************************************************************************}

{************************************************************************}
{Disk XFer - now receiver only                                           }
{                                                                        }

procedure DoTransDisk;

type dsk=array[0..5632] of byte;

var track,trnum,sec,secnum :byte;
    a,namel                :byte;
    point                  :word;
    disk                   :array[1..35] of ^dsk;
    scnum                  :array[1..35] of byte;
    dysk                   :file;
    dname                  :string;

begin
  trnum:=1;
  namel:=FPCGetByte;
  dname:='';
  for a:=1 to namel do dname:=dname+chr(FPCGetByte);
  writeln('Receiving disk: ',dname);
  write('Waiting for track #',trnum:2);
  repeat
    point:=0;
    repeat track:=FPCGetByte until (track<>255) and (track<>0);
    write (#8#8,track:2);
    if track<>trnum then DoError(err_dskRc);
    secnum:=FPCGetByte;
    scnum[track]:=secnum;
    GetMem(disk[track],scnum[track]*$0100);
    for sec:=1 to secnum do begin
      for a:=0 to 255 do begin
        disk[track]^[point]:=FPCGetByte;
        inc(point)
      end;
    end;
    inc(trnum);
  until trnum=36;
  writeln;
  assign (dysk, dname);
  rewrite (dysk,256);
  for track:=1 to 35 do begin
    BlockWrite(dysk,disk[track]^,scnum[track]);
    FreeMem(disk[track],scnum[track]*$0100);
    end;
  close (dysk);
end;
{************************************************************************}

{************************************************************************}
{File Xfer                                                               }
{C64/128 mode & CP/M                                                     }


procedure DoTransFile;
var plik                   :file of byte;
    plik2                  :file;
    pname                  :string;
    size                   :longint;
    ch                     :char;
    by                     :byte;
    cpm                    :boolean;
    buf                    :^buff;

procedure DoSendFile;
var a,by                   :byte;
    result                 :word;
    b                      :longint;
    buff                   :array[1..128] of byte;

begin
  ShowDirectory;
  repeat
    repeat
      write('Enter source filename in 8.3 convention:'); readln(pname);
      {$I-} assign(plik,pname); reset(plik); {$I+} a:=IOResult;
      if a <> 0 then writeln ('File not found');
    until a=0;
    for b:=1 to 12 do begin
      if b<=Length(pname) then ch:=pname[b] else ch:=' ';
      FPCSendByte(ord(ch));
      end;
    size:=FileSize(plik);
  until size<>0;
  close(plik);

  if cpm then size:=(size-1) shr 7;
  FPCSendByte(Lo(size)); FPCSendByte(Hi(size));

  if cpm then begin
                assign(plik2,pname); reset(plik2);
                for b:= 0 to size do begin
                  BlockRead(plik2,buff,1,result);
                  write('...');
                  repeat a:=FPCGetByte; until a=230; write('Transmitting next record ');
                  for a:= 1 to 128 do FPCSendByte(buff[a]);
                  write('...');
                  repeat a:=FPCGetByte; until a=233; writeln(' OK!');
                end;
                close(plik2);
              end
         else begin
                assign(plik2,pname); reset(plik2,1);
                GetMem(buf,size+1);
                BlockRead(plik2,buf^,size); close(plik2);
                for b:=1 to size do FPCSendByte(buf^[b]);
                FreeMem(buf,size+1);
              end;
end; {DoSendFile}


procedure DoReceiveFile;
var namel                  :byte;
    b                      :longint;
begin
  write('Receiving file:');
  size:=MakeWord(FPCGetByte,FPCGetByte);
  if cpm then size:=size shl 7;
  namel:=FPCGetByte;
  pname:='';
  for b:=1 to namel do pname:=pname+chr(FPCGetByte);
  writeln(pname);
  if cpm then begin
                assign(plik,pname); rewrite(plik);
                for b:=1 to size do begin
                  by:=FPCGetByte;
                  write(plik,by);
                end;
                close(plik);
              end
         else begin
                GetMem(buf,size+1);
                for b:=1 to size do buf^[b]:=FPCGetByte;
                assign(plik2,pname); rewrite(plik2,1);
                BlockWrite(plik2,buf^,size);
                close(plik2);
                FreeMem(buf,size+1);
              end;
end; {DoReceiveFile}

begin
  if (Rozkaz and 2) = 2 then cpm:=true else cpm:=false;
  case (Rozkaz and 1) of
    0: DoSendFile;
    1: DoReceiveFile;
  end;
end; {DoTransFile}

{************************************************************************}

procedure DoACEReceive;
var plik        :file;
    pname       :string;
    paknum      :word;
    size,b      :word;
    buf         :^buff;


begin
  writeln('ACE requested file transfer, receiving');
  write('Enter destination filename:');
  readln(pname);
  assign(plik,pname); rewrite(plik,1);
  size:=MakeWord(FPCGetByte, FPCGetByte); if size=0 then exit;
  GetMem(buf,size+1);
  paknum:=0;
  write('Received data packets:     ');
  repeat
    for b:=1 to size do buf^[b]:=FPCGetByte;
    BlockWrite(plik,buf^,size);
    inc(paknum);
    write(#8#8#8#8#8,paknum:5);
    b:=FPCGetByte; if b<>230 then DoError(err_ACERc);
    size:=MakeWord(FPCGetByte, FPCGetByte);
  until size=0;
  writeln(', done.');
  close(plik);
  FreeMem(buf,size+1);
end; {DoACEReceive}

{$IFDEF REU}
procedure DoREU;
var REULen              :word;
    REUAddy             :longint;
    REUAdHi,REUAdLo     :word;

procedure GetAddresses;
var Lo,Hi:byte; temp:word;
begin
  writeln('Rozkaz to:',Rozkaz);
  repeat until FPCGetByte = $bd;
  Lo:=FPCGetByte; Hi:=FPCGetByte;
  writeln('Bajty adresu REU:',Lo,' ',Hi);
  temp:=MakeWord(Lo,Hi);            {REU address word}
  writeln('Adres REU to: ',temp);
  Lo:=FPCGetByte; Hi:=FPCGetByte;
  writeln('Bajty dˆugo˜ci:',Lo,' ',Hi);
  REULen:=MakeWord(Lo,Hi);           {Length of transmission}
  writeln('Dlugo˜† to  : ',REULen);
  if REULen=0 then DoError(err_REULg);
  dec(REULen);
  REUAddy:=FPCGetByte;
   if REUAddy>REUSize then DoError(err_REUBk);
  writeln('Bank:',REUAddy);
  REUAddy:=(REUAddy shl 16)+temp;     {REU address + #bank * 64K}
  writeln('Ostateczny adres: ',REUAddy);
  REUAdHi:=REUAddy shr 14;
  REUAdLo:=REUAddy-(REUAdHi*32768);
  writeln('Mlodszy adres tabeli: ',REUAdLo);
  writeln('Starszy adres tabeli: ',REUAdHi);
  {Seek(REU,REUAddy);             {Set REU address in file}
end; {GetAddresses}

procedure REUDoStash;
var by:byte;
     a:word;
begin
  write('Stashing   ');
  for a:= 0 to REULen do
   begin
     by:=FPCGetByte;
     write(REU,by);
     {write(by,' ',a,' ');}
   end;
  reset(REU);
  writeln('ok');
end; {REUDoStash}

procedure REUDoFetch;
var by:byte;
     a:word;
begin
  write('Fetching   ');
  for a:= 0 to REULen do
   begin
     read(REU,by);
     FPCSendByte(by);
     {write(by,' ',a,' ');}
   end;
  writeln('ok');
end; {REUDoFetch}


begin
         GetAddresses;
         case (Rozkaz and 7) of
           0: REUDoStash;
           1: REUDoFetch;
         { 2: REUDoSwap;  }
           3: REUDoFetch;
         end;

end; {DoReu}

procedure InitReu;
var a:byte;
begin
  for a:=0 to (REUSize*2) do
  GetMem(REUTab[a],32768);
end;
{$ENDIF}

{************************************************************************}

{********}
{* MAIN *}
{********}

begin
  writeln;
  writeln('FastPC server v',version);
  writeln('by Maciej ''YTM/Alliance'' Witkowiak');
  writeln('Supports:');
  writeln('- file handling (C64/128, CP/M, ACE)');
  writeln('- disk transfer');
  {$IFDEF REU} writeln('- REU emulation'); {$ENDIF}
  writeln('Waiting for request...');
  InitFPC;
  InitInterrupts;
  {$IFDEF REU}
  {$I-}
  {assign(REU,'REU.c64');
  reset(REU);
  {$I+}
  {if IOResult = 0 then writeln ('REU exists')
    else begin rewrite(REU); close(REU); assign(REU,'REU.c64'); reset(REU);
         seek(REU,REUSize * 65536); write(REU,test); reset(REU);
         end;}
  {$ENDIF}
  {$IFDEF REU} InitREU; {$ENDIF}

  repeat
    repeat Rozkaz:=FPCGetByte until (Rozkaz<>255) and (Rozkaz<>0);
      if (Rozkaz and 128)=128 then {bit 7=1 - order}
        case (Rozkaz and 120) of
               {8: DoDriveEmu;  {bit 3=1}
{$IFDEF REU}   16: DoReu;       {bit 4=1} {$ENDIF}
               32: DoTransDisk; {bit 5=1}
               64: DoTransFile; {bit 6=1}
               96: if Rozkaz=230 then DoACEReceive;
        end
      else begin writeln('Unsupported command: ',Rozkaz); exit; end;
  until 1=0;
  DoneInterrupts;
{$IFDEF REU} close(REU); {$ENDIF}
end.

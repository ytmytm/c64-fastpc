
{uses Crt;}

{$IFDEF WINDOWS}
uses WinCrt;
{$ENDIF}

{Start sign: /ACK = LOW & data = $0f
             send /FLAG2
             set /ACK to HIGH
             send /FLAG2 again}

{Structure of the order byte:
 bit 7=1 - an order is sent
      =0 - quit/not an order yet/for future use
     6=1 - file activity
     5=1 - disk activity
     4=1 - REU  activity
     3=1 - drive emulator activity
   2,1,0 - type of activity (read/write/swap)}

const REUSize=32;        { Number of REU banks - x64K: 8-512K; 32-2048K}

var Rozkaz,Param,test   :byte;
    REULen              :word;
    REUAddy             :longint;
    REU                 :file of byte;

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
end;

procedure Wait4Start; assembler;
asm
  mov dx, 37ah          { Data port as input, disable IRQ7, /STROBE high}
  mov al, 00100000b
  out (dx),al
  dec dx
  dec dx
@loop1:
  in  al, 60h           { ESC? }
  dec al
  jz  @ESC
  in  al, (dx)          { Wait until /ACK=LOW        }
  mov ah, al            { and DATA=$0f               }
  inc dx
  in  al, (dx)
  dec dx
  and al, 01000000b
  or  ah, al
  cmp ah, 00001111b
  jne @loop1
  call SendStrobe       { Confirm it                 }
  dec dx
@loop2:
  in  al, (dx)          { Wait until confirmation is }
  and al, 01000000b     { confirmed by /ACK set HIGH }
  jz  @loop2
  call SendStrobe       { Final confirmation         }
  jp @Finish            { Ready to receive orders    }
@ESC:
  inc test
@Finish:
end; {Wait4Start}

procedure SendByte (lo:byte); assembler;
asm
  mov dx, 37ah
  mov al, 00000000b
  out (dx),al
  dec dx
  cli
@loop1:
  in  al,(dx)           { Wait until /ACK is LOW }
  and al,01000000b      { - ReadyToReceive       }
  jnz @loop1
  mov al,lo             { Data to AL             }
  dec dx                { Get DataPort addy      }
  out (dx),al           { Write data             }
  call SendStrobe       { Confirm receiving      }
  dec dx
@loop2:
  in  al,(dx)           { Wait until /ACK is HIGH}
  and al,01000000b      { - DataReceived         }
  jz @loop2
  sti
end;

function GetByte :byte;
var lo:byte;
begin asm
  mov dx, 37ah
  mov al,00100000b
  out (dx),al
  dec dx
  cli
@loop1:
  in  al,(dx)           { Wait until /ACK is LOW }
  and al,01000000b
  jnz @loop1
  dec dx                { Get DataPort addy      }
  in  al,(dx)           { Read data              }
  mov lo,al             { LO - as output         }
  call SendStrobe       { Confirm                }
  dec dx
@loop2:                 { Wait until /ACK will be}
  in  al,(dx)           { unactive again (/STRB) }
  and al,01000000b      { received and confirmed)}
  jz @loop2
  sti
end;
  GetByte:=lo;
end; {GetByte}

function MakeWord(lo,hi:byte) :word;
var val:word;
begin asm
  mov al, lo
  mov ah, hi
  mov val,ax
  end;
  MakeWord:=val;
end; {MakeWord}

procedure DoREU;

procedure GetAddresses;
var Lo,Hi:byte; temp:word;
begin
  Lo:=GetByte; Hi:=GetByte;
  {writeln('Bajty adresu REU:',Lo,' ',Hi);}
  temp:=MakeWord(Lo,Hi);            {REU address word}
  {writeln('Adres REU to: ',temp);}
  Lo:=GetByte; Hi:=GetByte;
  {writeln('Bajty d�ugo�ci:',Lo,' ',Hi);}
  REULen:=MakeWord(Lo,Hi);           {Length of transmission}
  {writeln('Dlugo�� to  : ',REULen);}
  if REULen=0 then begin writeln ('B��d transmisji!!!'); halt(0); end;
  dec(REULen);
  REUAddy:=GetByte;
   if REUAddy>REUSize then begin writeln('B��d transmisji!!!'); halt(0); end;
  {writeln('Bank:',REUAddy);}
  REUAddy:=(REUAddy shl 16)+temp;     {REU address + #bank * 64K}
  {writeln('Ostateczny adres: ',REUAddy);}
  Seek(REU,REUAddy);             {Set REU address in file}
end; {GetAddresses}

procedure REUDoFetch;
var by:byte;
     a:word;
begin
  for a:= 0 to REULen do
   begin
     read(REU,by);
     SendByte(by);
   end;
end; {REUDoFetch}

procedure REUDoStash;
var by:byte;
     a:word;
begin
  for a:= 0 to REULen do
   begin
     by:=GetByte;
     write(REU,by);
   end;
  reset(REU);
end; {REUDoStash}

procedure REUDoSwap;
var by:byte;
     a:word;
     f:file of byte;
begin
  writeln('Swapping...');
  assign(f,'reubuff.c64');
  rewrite(f);
  for a:= 0 to REULen do
   begin
   by:=GetByte;
   write(f,by);
   end;
  close(f);
  writeln('Received...');
  for a:= 0 to REULen do
   begin
    read(REU,by);
    SendByte(by);
   end;
  writeln('Send...');
  Seek(REU,REUAddy);
  assign(f,'reubuff.c64');
  reset(f);
  for a:= 0 to REULen do
   begin
   read(f,by);
   write(REU,by);
   end;
  close(f);
  erase(f);
  writeln('Swapped...');
  reset(REU);
end; {REUDoSwap}

begin
         GetAddresses;
         case (Rozkaz and 7) of
           0: REUDoStash;
           1: REUDoFetch;
           2: REUDoSwap;
           3: REUDoFetch;
         end;

end; {DoReu}

begin
  writeln;
  {$I-}
  assign(REU,'REU.c64');
  reset(REU);
  {$I+}
  if IOResult = 0 then writeln ('REU exists')
    else begin rewrite (REU); close(REU); assign(REU,'REU.c64'); reset(REU);
         end;
  writeln('Working as a server..., ESC should let you exit');
  repeat
    Wait4Start; if test=1 then
                   begin writeln('Program terminated.'); halt(0); end;
    { Waiting for order }
    Rozkaz:=GetByte;
    if (Rozkaz and 128)=128 then {bit 7=1 - order}
       case (Rozkaz and 120) of
          16: DoReu; {bit 4=1}
       end
    else halt(0);
  until 1=0;
end. {Main}
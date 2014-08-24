
uses Crt;

var test:byte;
var a,b,c,rozkaz:byte;

{*************************************}
{Interrupt handling procedures        }
{                                     }

var OldVec      :procedure;
    OldVect     :pointer;

procedure GetIntVec(IntNo: Byte; var Vector: Pointer); assembler;
asm
	  MOV	AL,IntNo
	  MOV	AH,35H
	  INT	21H
	  MOV	AX,ES
	  LES	DI,Vector
	  CLD
	  XCHG	AX,BX
	  STOSW
	  XCHG	AX,BX
	  STOSW
end;

procedure SetIntVec(IntNo: Byte; Vector: Pointer); assembler;
asm
	  PUSH	DS
	  LDS	DX,Vector
	  MOV	AL,IntNo
	  MOV	AH,25H
	  INT	21H
	  POP	DS
end;

procedure DisableInt(Interr : byte; var Save_Vec : pointer);
  var
     Data : byte;
  begin
       if Interr<8 then
        begin
         SetIntVec(Interr+8,Save_Vec);
         Data:=port[$21];
         port[$21]:=Data or (1 shl Interr);
        end
       else
        begin
         SetIntVec(Interr+$68,Save_Vec);
         Data:=port[$A1];
         port[$A1]:=Data or (1 shl (Interr-8));
        end;
  end;

procedure EnableInt(Interr : byte; IRQHandler : pointer;var Save_Vec : pointer);
  var
     Data : byte;
  begin
         GetIntVec(Interr+8,Save_Vec);
         SetIntVec(Interr+8,IRQHandler);
         Data:=port[$21];
         port[$21]:=Data and ($FF xor (1 shl Interr));
  end;


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


{$F+}
procedure IntProc; interrupt;
var val:byte;
begin
asm mov test, 1
    mov al, 20h
    out (20h),al
    end;
{write(' ',val);}
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

{*************************************}

{*************************************}
{FastPC I/O procedures                }
{if test=$ff => ESC was pressed       }
{                                     }

var val :byte;

procedure InitFPC; assembler;
asm
  mov dx, 37ah          { Get ControlPort addy   }
  mov al, 00110000b     { Enable input&irq7      }
  out (dx), al
  mov al, 20h           { confirm interrupt -    }
  out (20h),al          { just in case           }
  mov test, 0           { init this too          }
end;

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
end;

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
end;

function FPCGetByte:byte; begin FPCGetByte:=IOGetByte; if test=$ff then halt(0); end;
procedure FPCSendByte(by:byte); begin IOSendByte(by); if test=$ff then halt(0); end;

function MakeWord(lo,hi:byte) :word; assembler;
asm
  mov al, lo
  mov ah, hi
end; {MakeWord}


{**************************************}

const REUSize=32;

procedure DoREU;
var REULen              :word;
    REUAddy             :longint;

procedure GetAddresses;
var Lo,Hi:byte; temp:word;
begin
  Lo:=FPCGetByte; Hi:=FPCGetByte;
  writeln('Bajty adresu REU:',Lo,' ',Hi);
  temp:=MakeWord(Lo,Hi);            {REU address word}
  writeln('Adres REU to: ',temp);
  Lo:=FPCGetByte; Hi:=FPCGetByte;
  writeln('Bajty dˆugo˜ci:',Lo,' ',Hi);
  REULen:=MakeWord(Lo,Hi);           {Length of transmission}
  writeln('Dlugo˜† to  : ',REULen);
  if REULen=0 then begin writeln ('Bˆ¥d transmisji!!!'); halt(0); end;
  dec(REULen);
  REUAddy:=FPCGetByte;
   if REUAddy>REUSize then begin writeln('Bˆ¥d transmisji!!!'); halt(0); end;
  writeln('Bank:',REUAddy);
  REUAddy:=(REUAddy shl 16)+temp;     {REU address + #bank * 64K}
  writeln('Ostateczny adres: ',REUAddy);
  {Seek(REU,REUAddy);             {Set REU address in file}
end; {GetAddresses}

procedure REUDoStash;
var by:byte;
     a:word;
begin
  writeln('Stashing');
  for a:= 0 to REULen do
   begin
     by:=FPCGetByte;
     write(by,' ',a,' ');
   end;
end; {REUDoStash}

procedure REUDoFetch;
var by:byte;
     a:word;
begin
  for a:= 0 to REULen do
   begin
     by:= a and 255;
     FPCSendByte(by);
     write(by,' ',a,' ');
   end;
end; {REUDoFetch}


begin
         GetAddresses;
         case (Rozkaz and 7) of
           0: REUDoStash;
           1: REUDoFetch;
          { 2: REUDoSwap;
           3: REUDoFetch; }
         end;

end; {DoReu}


begin
  writeln;
  InitFPC;
  InitInterrupts;
  repeat a:=FPCGetByte; write(' ',a) until a=0;
  writeln('Rozkaz: ',a);
  FPCSendByte(233); FPCSendByte(3);
  end.
        {
  Rozkaz:=a; DoReu;

  end.

{  for a:=0 to 255 do
   for b:=0 to 255 do
    for c:=1 to 10 do FPCSendByte(c);
}
 {
  writeln(FPCGetByte);
  a:=8;
  FPCSendByte(8);
  DoneInterrupts; halt;
  FPCSendByte(3);
  writeln('OK!');

  DoneInterrupts;
end.


{ D64toPC - disk receiver by Maciej Witkowiak 1998 }
{$IFDEF WINDOWS}
uses WinCrt;
{$ENDIF}

var a,track,trnum,sec,secnum,test :byte;
    point                         :word;
    total                         :longint;
    disk                          :array[0..5632] of byte;
    dysk                          :file of byte;
    dname                         :string;

procedure InitIO; assembler;
asm
  mov dx,378h           { Set /ACK to inactive        }
  mov al,1
  out (dx),al
  mov dx,37ah           { Bidirectional Port as Input }
  mov al,4
  out (dx),al
end; {InitIO}

procedure Wait4Start; assembler;
asm
  mov dx, 379h
  mov al,0
  mov test,al
@loop1:
  in  al, 60h
  dec al
  jz  @ESC
  in  al, (dx)          { Wait until higher nybble    }
  and al, 11111000b     { and /ACK line are all LOW   }
  xor al, 10000000b
  cmp al, 00000000b
  jne @loop1
  dec dx
  mov al, 0             { Confirm by sending /FLAG2   }
  out (dx), al          { tick                        }
  inc al
  out (dx), al
  inc dx
@loop2:
  in  al, (dx)          { Wait until confirmation is  }
  and al, 00001000b     { confirmed by /ACK set HIGH  }
  cmp al, 00001000b
  jne @loop2
  je  @Finish
@ESC:
  inc test
@Finish:
end; {Wait4Start}

function GetByte :byte;
var lo:byte;
begin asm
  mov dx,379h           { Set StatusPort addy }
  cli                   { disable interrupts  }
@loop1:
  in  al,(dx)           { Get Status          }
  and al,00001000b      { Is /STROBE LOW?     }
  jnz @loop1
  inc dx                { Get ControlPort addy}
  in  al,(dx)           { Get lower nibble    }
  mov bl,al             { store in BL         }
  dec dx                { Get StatusPort addy }
  in  al,(dx)           { Get higher nibble   }
  mov bh,al             { temporary in BH     }
  dec dx                { Get DataBus addy    }
  mov al,0              { sent /ACK tick      }
  out (dx),al
  inc al                { /ACK line back to   }
  out (dx),al           { inactive            }
  mov al,bh             { restore temporary   }
  and al,11110000b      { calculate nibbles   }
  xor al,10000000b
  and bl,00001111b
  xor bl,00001011b
  or  al,bl             { put nibbles together in AL }
  mov lo,al             { LO - as output             }
  inc dx                { Get StatusReg addy         }
@loop2:
  in  al,(dx)           { is /STROBE unactive again? }
  and al,00001000b
  jz  @loop2
  sti                   { enable interrupts          }
  end;
  GetByte:=lo;
end; {GetByte}

begin
  InitIO;
  trnum:=1;
  total:=0;
  test:=0;
  write (#13#10'D64toPC parallel cable *.d64 disk images receiver'#13#10+
  'Written by Maciej YTM/Alliance Witkowiak, September 1998'#13#10);
  write (#13#10'Enter *.d64 filename (with extension): '); readln(dname);
  assign (dysk, dname);
  rewrite (dysk);

  repeat
    point:=0;
    writeln (#13#10'Waiting for the start of transmission');
    Wait4Start;
      if test=1 then begin writeln('Program terminated'); close (dysk); halt(0); end;
    track:=GetByte;
    writeln ('Receiving track: ',track);
    if track<>trnum then begin
      writeln ('Error - track number is different than expected'); close(dysk); halt(0); end;
    secnum:=GetByte;
    for sec:=1 to secnum do begin
      for a:=0 to 255 do begin
        disk[point]:=GetByte;
        inc(point)
      end;
    end;
    write ('Track ',track,' received.  ');
    point:=0;
    for sec:= 1 to secnum do begin
      for a:=0 to 255 do begin
        write (dysk, disk[point]);
        inc(point);
        inc(total);
      end;
    end;
    writeln (total,' bytes stored...');
    inc(trnum);
  until trnum=36;
  close (dysk);

end. {Main}

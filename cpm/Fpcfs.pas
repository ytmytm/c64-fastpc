program FastPC;
{ FastPC - filesender }

{07.11.1998  by Maciej 'YTM' Witkowiak}
{11.02.1999 - version for modified FastPC cable}
{14.02.1999 - assembly version}

const buffsize=128; recsize=128;

var source     :file;
    sihi,silo  :byte;
    naml,by    :byte;
    size,a     :integer;
    sname      :string[12];
    RecsToProc,RecsRead:integer;
    buffer     :array[1..buffsize,1..recsize] of byte;
    odp        :char;

procedure Init;
begin
  inline($01/$dd0d/          {ld bc, 0dd0dh}
         $3e/$10/            {ld a,  010h  }
         $ed/$79);           {out (c),a    }
end;

procedure Init4Read;
begin
  inline($01/$dd03/          {ld bc, 0dd03h}
         $3e/$00/            {ld a,  00h   }
         $ed/$79);           {out (c),a    }
end;

procedure Init4Write;
begin
  inline($01/$dd03/          {ld bc, 0dd03h}
         $3e/$ff/            {ld a,  ffh   }
         $ed/$79);           {out (c),a    }
end;

procedure SendByte(value:byte);
begin
  inline($3a/value/          {ld  a, (value)}
         $01/$dd01/          {ld bc, 0dd01h}
         $ed/$79/            {out (c),a    }
         $01/$dd0d/          {ld bc, 0dd0dh}
         $ed/$78/      {Wait: in a,(c)     }
         $fe/$10/            {cp 010h      }
         $20/$fa);           {jr Wait      }
end;

function GetByte:byte;
var value:byte;
begin
  inline($01/$dd0d/          {ld bc, 0dd0dh}
         $ed/$78/      {Wait: in a,(c)     }
         $fe/$10/            {cp 010h      }
         $20/$fa/            {jr Wait      }
         $01/$dd01/          {ld bc, 0dd01h}
         $ed/$78/            {in a,(c)     }
         $32/value);         {ld (value),a }
  GetByte:=value;
end;

procedure SendBuffer;
begin
  inline($21/buffer/         {ld hl, buffer }
         $3a/RecsRead/       {ld a, (RecsRead)}
         $57/                {ld d, a       }
         $1e/$00/            {ld e, 000h    }
         $cb/$3a/            {srl d         }
         $cb/$1b/            {rr  e  ; DE:=256*a/2=128*a}
         $7e/          {Loop: ld  a, (hl)   }
         $01/$dd01/          {ld bc, 0dd01h}
         $ed/$79/            {out (c),a    }
         $01/$dd0d/          {ld bc, 0dd0dh}
         $ed/$78/      {Wait: in a,(c)     }
         $fe/$10/            {cp 010h      }
         $20/$fa/            {jr nz, Wait  }
         $23/                {inc hl       }
         $1b/                {dec de       }
         $7a/                {ld  a, d     }
         $b3/                {or  e        }
         $20/$eb);           {jr nz, Loop  }
end;

begin
  repeat
  writeln('FastPC FileXfer by Maciej Witkowiak; 1998/99');
  write('Source file:'); readln(sname);
  bdos($0d);
  assign(source,sname); {$I-}
  reset(source);        {$I+}
  if IOResult <> 0 then halt;
  Init; Init4Write;
  SendByte($c3);
  RecsToProc:=filesize(source);
  size:=RecsToProc;
  sihi:=hi(size); silo:=lo(size);
  SendByte(silo); writeln('# of records:',size);
  SendByte(sihi);
  naml:=length(sname);
  SendByte(naml);
  for a:=1 to naml do  SendByte(ord(sname[a]));
  writeln('Transmitting file...');
  writeln(RecsToProc:3,' records left');
  while RecsToProc>0
  do begin
       BlockRead(source,buffer,buffsize,recsread);
       SendBuffer;
       RecsToProc:=RecsToProc-RecsRead;
       writeln(RecsToProc:3,' records left');
     end;
  close(source);
  writeln; writeln;
  write('Another transfer (Y/N)?'); readln(odp);
  writeln;
  until odp='n';
end.

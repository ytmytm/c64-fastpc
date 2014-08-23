{ This is a 90%-assembly version of FastPC cable driver
  by Maciej 'YTM/Alliance' Witkowiak
  14.02.1999 }

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

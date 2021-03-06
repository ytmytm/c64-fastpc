
D64toPC - ulitmately fast *.D64 (1541 disk image file) transfer kit...
=======================================================================

by Maciej 'YTM' Witkowiak, September 1998

The main reason for constructing this interface and writting programs was the
slowness of serial (RS232) transfer procedures on C64/128. I had to transfer
about 30 disks (60 disksides) to PC for use under C64S emulator and I wanted to
do it as fast as possible.
(In fact I was to lazy to make a RS232 interface).

Long time ago the Burst for 1541 was invented (parallel connection)...
Now, I've invented FastPC - parallel data transfer from C64/128 to PC via USER
and LPT ports. This one is named FastPC-OD (one direction) - for use with those
PCs which do not have bidirectional LPT port. If your PC supports bidirectional
LPT port then do not bother with this stuff and get FastPC-BD package. You will
find some new features there.
The speed is VERY good - about 15kB/sec on 1MHz C64 and about 29kB/sec on 2Mhz
C128. Total time of reading disk and transferring it to PC is about 50 seconds.
I have PII/266 but it shouldn't matter as I wrote receiving procedures in
assemble code so they are as efficient as possible.

##What do you need:
- one C64/C128 with 1541/1571 disk drive
  (C128 in 64 mode and 1571 in 1541 mode - default when you reset to 64 mode)
- one PC-clone, probably 286+ (not tested)
- one parallel FastPC-OD cable

##System requirements:
You should check your BIOS settings concerning LPT port mode. To work with this
version on cable you have to have it on 'NORMAL' state. It will not work if LPT
mode is set to 'BIDIRECTIONAL' - you need a bit different cable.

##FastPC-OD cable:
What do you need:
- one DB25 male connector (to LPT port)
- one USER PORT connector
- 11 wires (wirewrap preferred)
- some soldering skill

It is very hard to get USER PORT connector these days so I propose you to
change your USER PORT to standard DB25 (female) connector. Use 24 short wires
and solder all pins of old connector to the new one. Then make a hole in
C64/128 suitcase and place it.

At start some pinouts:

```
USER PORT (view from rear of C64/128)

                  1 1 1
1 2 3 4 5 6 7 8 9 0 1 2
A B C D E F H J K L M N

PC LPT PORT (DB 25 male from rear or DB 25 female from front)

\ 13 12 11 10 09 08 07 06 05 04 03 02 01 /
 \ 25 24 23 22 21 20 19 18 17 16 15 14 /
```

Here's the connection list:

```
C64USER		PC-LPT
   A		18..25 (it means - one pin from 18 to 25 and not 'all pins from 18 to 25')
   B		  2
   C		  1
   D		  14
   E		  16
   F		  17
   H		  13
   J		  12
   K		  10
   L		  11
   M		  15
   N		18..25  (nah, not needed at all)
```

As you see this is easy (and even elegant on the side of C64/128 ;).
Oh, one note - the cable shouldn't be longer than 2m. (Hmm my cable has 2,5m
and it works well...)

##How to use:
Just transfer D64toPC.PRG to your commy (it is your problem how, I suggest you
RS232 or X1541). To transfer the disk execute D64toPC.EXE and enter the
receiving disk image filename. Then execute D64toPC.PRG on your commy.
It is recommended that you first execute *.EXE (receiver) and then *.PRG
(sender) program. My procedures are tough as steel but... nah, nevermind...
Anyway, if the first transfer is bad - receiver reports bad track number then
reset C64, use "SYS2061" and start again - everything should be just fine.
(Guess what - PC is making sometimes 'first transfer error')
If the errors are coming again and again - check your cable.

##What then:
I've transferred all whatever I could run under C64S emulator during programming
this software, so don't count on newer versions of D64toPC.

The next goal is to utilitize a bidirectional cable for:
- disk sending (like D64toPC)
- file transfer (like X1541 but MUCH MORE faster)
- under GEOS for emulating VBD (Very Big Disk) - for GEOS 128 (for sure) and
  GEOS 64 (maybe) and REU/RamCart (needed)
- under GEOS for emulating REU (256/512/1024/2048kB) - should work with both
  GEOS versions
- under GEOS for emulating both VBD and REU and/or whatever ;-)

I hope to write handler for FastPC-BD as fast as this one...

btw: the assembler portions of D64toPC.EXE are my first 80'86 assembler
     procedures and I'm really proud of them
     readtrack procedure in D64toPC.PRG was written by Mr.Wegi, I should rewrite
     it to have even better performance on C64 but I really don't want to

Filelist:
D64toPC.ASM - C64 assembly file for TurboAssembler/TurboAssemblerMacro in
	      SEQ format (in editor: <- & E + filename)
D64toPC.SRC - C64 tokenized file for TurboAssemblerMacro only
	      (in editor: <- & L + filename)
D64toPC.PRG - C64 executable file for sending disks - just move it to commy
	      and RUN
D64toPC.PAS - PC  Pascal source file for D64toPC.EXE
D64toPC.EXE - PC  executable file for receiving disks
D64toPC.TXT - this file

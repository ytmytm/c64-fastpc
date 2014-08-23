FastPC - transfer files and disk images over parallel cable between C64/128 and PC with LPT port
================================================================================================

This was superseded by 64net/2 which proved to be much more powerful way of utilizing parallel cable for file transfer and disk emulation.

Back on 1999-02-20...

Maciej 'YTM/Alliance' Witkowiak, 20.02.1999

I am releasing this software in an emergency state (I've just burned CIA#2) so do not treat this as the 'finished' version. Programs included are working just fine and I wanted to upgrade the user interface only.

FastPC is an alternate connection of C64/128 to PC. It is a parallel cable so the speed of transmission is very high - about 15-18K/sec.
To use it you must make a cable, so here goes the scheme:

```
C64/128		PC
USER PORT	LPT
A		18..25
B		1
C		2
D		3
E		4
F		5
H		6
J		7
K		8
L		9
8		10
```

The best way is to use a 16-wirewrap. You can also use the rest of the wires to mount a RS-232 interface.

Then you have to setup your system. FastPC assumes that LPT port has base address $0378 and the IRQ 7 (15) is free. You have also to change in BIOS LPT settings to BIDIRECTIONAL.

FastPC is a server-client network. You have one server program on PC and a batch of clients on C64.

Here goes description:
FPCSERVR.EXE - PC server, just execute it; to stop in any moment use ESC; if the server would encounter an error it will show a message and exit - you have then to execute again the server and the client and start again

Now C64/128 proggies:
FPCDXFER.PRG - it will send disk images (*.d64) from C64 to PC; in case of disk-error it will hang up - you have to stop the server on PC (ESC) and start everything again.

FPCFSNDR.PRG - this one sends files from C64 to PC

In both programs you can type in full path by replacing \ by the pound sign.

FPCFRECV.PRG - for receiving files from PC - when you start it you have to type in the filename on PC, you can use 8.3 filenames only - files only from current directory

FPCFRUN.PRG - start by SYS$0334 - it works like FPCFRECV but after receiving it immediately executes the file; it is smart enough to distinguish BASIC from ML programs - BASIC RUN or jump to the first byte of received file

Now C128 section:
FPCFS.COM - this one is dedicated for C128 CP/M system - it works like FPCFSNDR.PRG; source included

FPC.INC - include file for Turbo Pascal 3.0 with everything needed to write programs with FastPC cable

FastPC cable is also compatible with the device U: from ACE (UNIX for C64/128). You can redirect output of programs to U: e.g.
cat file.txt >u:
ls >u:
or just copy something there:
cp file.txt u:

You have to type in the received filename on PC (it is not transmitted with data).

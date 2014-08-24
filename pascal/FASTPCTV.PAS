{***************************************}
{ FastPC - onedirectional cable service }
{ PC LPT <-> CBM64/128 USER PORT        }
{        main reason - disk receiving   }
{        need to add file xfer          }
{***************************************}

program FastPC;

uses App, Objects, Menus, Drivers, Views, MsgBox, StdDlg, Dialogs;

const
  cmReceive = 251;
  cmAbout   = 261;

type
  PRecDialog = ^TRecDialog;
  TRecDialog = object (TDialog)
    constructor Init;
  end;

  FastPCApp = object(TApplication)
    procedure DoAboutBox;
    procedure DoReceive;
    procedure HandleEvent(var Event:TEvent); virtual;
    procedure InitMenuBar; virtual;
  end;

constructor TRecDialog.Init;
var
  R:TRect;
begin
  R.Assign(0, 0, 40, 12);
  inherited Init(R, 'Transmission in progress');
  Options:= Options or ofCentered;
  R.Assign(15, 9, 25, 11);
  Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
  SelectNext(False);
  R.Assign(2,5,18,6);
  Insert(New(PLabel, Init(R, 'Received bytes:',nil)));
  R.Assign(24,5,39,6);
  Insert(New(PLabel, Init(R, 'xxxxxx',nil)));

end;

procedure FastPCApp.InitMenuBar;
var
  R:TRect;
begin
  GetExtent(R);
  R.B.Y:=R.A.Y+1;
  MenuBar:= New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~F~ile', hcNoContext, NewMenu(
      NewItem('~R~eceive','F3', kbF3, cmReceive, hcNoContext,
      NewLine(
      NewItem('E~x~it','Alt+X',kbAltX, cmQuit, hcNoContext,
      nil)))),
    NewSubMenu('~H~elp', hcNoContext, NewMenu(
      NewItem('~A~bout', '', kbNoKey, cmAbout, hcNoContext,
      nil)),
      nil)))));
end;

procedure FastPCApp.DoAboutBox;
begin
  MessageBox(#3'FastPC disk and file xfer'#13+
  #3'by Maciej "YTM/Alliance" Witkowiak'#13#3'September 1998',
  nil, mfInformation or mfOKButton);
end;

procedure FastPCApp.DoReceive;
var
  R:TRect;
  FileDialog:PFileDialog;
  TheFile:FNameStr;
const
  FDOptions: word = fdOKButton;
begin
  TheFile:= 'received.d64';
  New(FileDialog, Init(TheFile, 'Open file', '~F~ile name',
      FDOptions, 1));
  if ExecuteDialog(FileDialog, @TheFile) <> cmCancel then
  begin
    ExecuteDialog(New(PRecDialog, Init), nil);
  end;
end;

procedure FastPCApp.HandleEvent(var Event:TEvent);
var
  R:TRect;
begin
  inherited HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
    cmAbout:
      begin
        DoAboutBox;
        ClearEvent(Event);
      end;
    cmReceive:
      begin
        DoReceive;
        ClearEvent(Event);
      end;
    end;
  end;
end;

var
  FPCApp: FastPCApp;

begin
  FPCApp.Init;
  FPCApp.Run;
  FPCApp.Done;
end.

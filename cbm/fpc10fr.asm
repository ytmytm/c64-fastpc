;�AST����.PRG;�ECEIVES A FILE VIA �AST��-�� CABLE;1-3.11.1998;2.2.98;27.5.99 - BACK TO LINE VERSION, MINOR;          BUG IN CONVASCII REMOVED;;�ACIEJ '���/�LLIANCE' �ITKOWIAK;�AST�AVE BY �XPLORER;FALSE    = 0TRUE     = 1USE2MHZ  = TRUEINLINE   = TRUENAME     = $0334BUFFER   = $0D00DD00     = $02STORX    = $03STORY    = $04MB       = $FASB       = $FBLL       = $FCLH       = $FDLGL      = $FELGH      = $FFPRINT    .MACRO         LDA #<\1         LDY #>\1         JSR $AB1E         .ENDM         *= $0801         .WORD $080B,1999         .BYTE $9E         .TEXT "2061"         .BYTE 0,0,0START    LDA #0         STA $D020         STA $D021         STA $D015         LDA #$17         STA $D018         #PRINT STATXT         JSR WAIT4START         LDA #0         JSR PCSEND         LDA #%11000000         JSR PCSEND         JSR PCRINIT         LDX #0NAMELP   JSR PCGET         JSR CONVASCII         STA NAME,X         INX         CPX #8+3+1         BNE NAMELP         JSR PCGET         STA LGL         JSR PCGET         STA LGH         LDA LGL         ORA LGH         BNE OK1         JMP ENDTHISOK1      LDA #<BUFFER         LDX #>BUFFER         STA MB         STX SB         LDY #0         STY LL         STY LH         SEI         LDX #0         STX $D011         STX $D020         .IF USE2MHZ         INX         STX $D030         .ENDIFMAINLP   LDX #$35         STX $01         JSR PCGET         LDX #$30         STX $01         STA (MB),Y         INC LL         BNE *+4         INC LH         INC MB         BNE *+4         INC SB         LDA LH         CMP LGH         BNE MAINLP         LDA LL         CMP LGL         BNE MAINLP         LDA #$37         STA $01         .IF USE2MHZ         LDA #0         STA $D030         .ENDIF         LDA #$1B         STA $D011         CLISV�MAIN  #PRINT SAVTXT         LDX #0NMLP     LDA NAME,X         JSR $FFD2         INX         CPX #8+3+1         BNE NMLP         LDA #13         JSR $FFD2         LDA #<BUFFER+2   ;END ADDY         CLC         ADC LGL         STA $AE         LDA #>BUFFER+2         ADC LGH         STA $AF         LDA #8+3+1         LDX #<NAME         LDY #>NAME         JSR $FFBD      ;SET PARAM.         LDA #<BUFFER+2   ;START ADDY         LDX #>BUFFER+2         STA $AC         STX $AD         LDA BUFFER       ;LOAD ADDY         LDX BUFFER+1         STA $FE         STX $FF         JSR SAVE       ;����         BCS FILEXIST   ;ERRORS         BCC ENDTHISFILEXIST INC $D020         #PRINT ERRTXT         LDY #120         LDX #$FFFE       DEX         BNE *-1         DEY         BNE FE         DEC $D020         JSR $FFE4         BEQ *-3         CMP #"Y"         BEQ SV�MAINENDTHIS  #PRINT ENDTXT         JSR $FFE4         BEQ *-3         CMP #" "         BNE FINITO         JMP STARTFINITO   RTSCONVASCII         CMP #$60         BMI CAOK         CMP #$7B         BPL CAOK         AND #$DFCAOK     RTS;---------------------------------------WAIT4START         JSR PCSINIT         LDA DD00         STA $DD00         LDA #$0F         STA $DD01         .IFEQ INLINE         JSR FLAG2         LDA $DD00         ORA #4         STA $DD00         JSR FLAG2         .ENDIF         .IFNE INLINE         LDA $DD0D         AND #$10         BEQ *-5         LDA $DD00         ORA #4         STA $DD00         LDA $DD0D         AND #$10         BEQ *-5         .ENDIF         RTS         .IFEQ INLINEFLAG2    LDA $DD0D         AND #$10         BEQ FLAG2         RTS         .ENDIFPCRINIT  LDA #$00         BEQ PCINITPCSINIT  LDA #$FFPCINIT   STA $DD03         LDY #0         STY $DD01         LDA $DD02         ORA #4         STA $DD02         LDA #$10         STA $DD0D         LDA $DD00         AND #$FB         STA DD00         RTSPCGET    STX STORX         STY STORY         LDA DD00         TAX         ORA #4         TAY         STX $DD00         .IFEQ INLINE         JSR FLAG2         LDX $DD01         STY $DD00         JSR FLAG2         .ENDIF         .IFNE INLINE         LDA $DD0D         AND #$10         BEQ *-5         LDX $DD01         STY $DD00         LDA $DD0D         AND #$10         BEQ *-5         .ENDIF         TXA         LDY STORY         LDX STORX         RTSPCSEND   STA $DD01         STX STORX         STY STORY         LDA DD00         TAX         ORA #4         TAY         STX $DD00         .IFEQ INLINE         JSR FLAG2         STY $DD00         JSR FLAG2         .ENDIF         .IFNE INLINE         LDA $DD0D         AND #$10         BEQ *-5         STY $DD00         LDA $DD0D         AND #$10         BEQ *-5         .ENDIF         LDY STORY         LDX STORX         RTS;---------------------------------------STATXT   .BYTE 147,155         .TEXT "�AST�� �ILE �ECEIVER"         .BYTE 13         .TEXT "BY �ACIEJ '���' �ITKOWI"         .TEXT "AK"         .BYTE 13         .TEXT "�AST�AVE BY �XPLORER"         .BYTE 13,13,5         .TEXT "�NSERT A DISK AND SELEC"         .TEXT "T A FILE"         .BYTE 13         .TEXT "ON YOUR ��."         .BYTE 13,0SAVTXT   .BYTE 13,13,155         .NULL "�OW SAVING:"ERRTXT   .BYTE 13,13,5         .TEXT "�RROR HAPPENED..."         .BYTE 13         .TEXT "�RY AGAIN? (Y/N)"         .BYTE 13,0ENDTXT   .BYTE 147,155,13,13         .TEXT "�RESS "         .BYTE 5         .TEXT " ����� "         .BYTE 155         .TEXT "FOR NEXT TRANSFER, OR"         .BYTE 13         .TEXT "ANYTHING ELSE TO EXIT"         .BYTE ".",0;---------------------------------------;���Ԥ���Ť�����        /17.10.95/$023�/;(�)1995 BY �DAM'��������'�AZMIERSKI/���;�������;---------------------------------------SAVE     LDA #$61         STA $B9         JSR $F3D5         LDA $BA         JSR $ED09         LDA #$6F         JSR $EDC7         JSR $EE13         PHA         JSR $EDFETEST     PLA         CMP #$30         BEQ INIT         RTSINIT     LDA #<BUFF     ;������� ����.         LDX #>BUFF         STA LOOP1+1         STX LOOP1+2         LDA #5         LDX #0         STA FROM         STX FROM+1         STX $FCGO       JSR ON1         LDX #6         LDA COM1-1,X         JSR $EDDD         DEX         BNE *-7LOOP1    LDA BUFF,X         JSR $EDDD         INX         CPX #$20         BNE *-9         JSR $EDFE         LDA LOOP1+1         CLC         ADC #$20         STA LOOP1+1         BCC *+5         INC LOOP1+2         LDA FROM+1         CLC         ADC #$20         STA FROM+1         BNE GO         JSR ON1         LDX #5         LDA COM2-1,X         JSR $EDDD         DEX         BNE *-7         JSR $EDFE         SEI         BIT $DD00         BMI *-3         JSR PROC1�         LDA $FE        ;#<         JSR LP1         DEC $FD         LDA $FF        ;#>         JSR LP1         BNE LP2LP4      JSR PROC1LP3      LDY #0         INC $01        ;(!)���         LDA ($AC),Y         DEC $01        ;(!)���         JSR LP1         INC $AC         BNE LP2         INC $ADLP2      DEC $FD         BNE LP3         LDA $FC         BEQ LP4         CLI         BIT $DD00         BMI ERROR         CLC         RTSERROR    SEC         RTS;�����������PROC1�   SEC         LDA $AE         SBC $AC         STA $FD         TAX         LDA $AF         SBC $AD         BNE LP5         CPX #$FF         BEQ LP5         INX         INX         INX         TXA         INC $FD         INC $FD         DEC $FC         BNE LP1PROC1    SEC         LDA $AE         SBC $AC         STA $FD         TAX         LDA $AF         SBC $AD         BNE LP5         CPX #$FF         BEQ LP5         INX         TXA         DEC $FC         BNE LP1LP5      LDA #$FE         STA $FD         LDA #0LP1      PHA         BIT $DD00         BPL *-3         LSR A         LSR A         LSR A         LSR A         TAX         SECLB2      LDA $D012         SBC #$32         BCC LB1         AND #7         BEQ LB2LB1      LDA #$10         EOR $DD00         STA $DD00         LDA TABV,X         STA $DD00         LSR A         LSR A         AND #$F7         STA $DD00         PLA         AND #$0F         TAX         LDA TABV,X         STA $DD00         LSR A         LSR A         AND #$F7         STA $DD00         NOP         NOP         LDA #7         STA $DD00         RTS;�����������TABV     .WORD $8707         .WORD $A727         .WORD $C747         .WORD $E767         .WORD $9717         .WORD $B737         .WORD $D757         .WORD $F777;�����������ON1      LDA $BA        ;DEVICE NUMBER         JSR $ED0C         LDA #$6F         JMP $EDB9COM1     .BYTE $20FROM     .WORD $05         .TEXT "W-M"COM2     .WORD $5D05         .TEXT "E-M";�����������BUFF     = *         *= $0500         .OFFS BUFF-*         LDA $14         TAX         LSR A         ADC #3         STA $31         TXA         ADC #6         STA $32LOP5     JSR TAKEB         BEQ LOP1         STA $81         TAX         INX         STX $1F         LDA #0         STA $80         BEQ LOP2LOP1     LDA $02FA         ORA $02FC         BNE LOP3         LDA #$72         JMP $F969;�����������LOP3     JSR $F11ELOP2     LDA $80         STA ($30),Y         INY         LDA $81         STA ($30),Y         LDY #2LOP4     JSR TAKEB         STA ($30),Y         INY         CPY $1F         BNE LOP4         JSR $0150         INC $B6         BNE NORM         INC $BCNORM     LDX $14         LDA $81         STA $07,X         LDA $80         CMP $0A         BEQ LOP5         STA $06,X         JMP $F418;�����������PRGGO    LDA #$C8         LDX #8         ;����������         LDY #$10       ;����� ����         STA $64         STX $69         STY $1C07         LDX #$64LOP8     LDA $F574,X         STA $014F,X         DEX         BNE LOP8         STX $1F         LDA #$60         STA $01B4         INX         LDA #$40         STA $02F9         STX $82         STX $83         JSR $DF93         STA $15         ASL A         STA $14         TAX         JSR IOLOP11    LDA $06,X         BEQ CLOSE         STA $0A         LDA #$E0         STA $02         LDA $02         BMI *-2         CMP #2         BCC LOP11         CMP #$72         BNE ERROR�         JMP $E645ERROR�   JMP $D63FCLOSE    JMP $DB23;�����������TAKEB    LDA #1         STA $1800         LDA #$FFLOP6     BIT $1800         BEQ LOP6         .WORD $EA3A         LDA $1800         ASL A         .WORD $EA08         ORA $1800         ASL A         ASL A         ASL A         ASL A         STA $85         LDA $1800         ASL A         PLP         ORA $1800         AND #$0F         ORA $85IO       PHA         LDA #2         STA $1800         .WORD $6068
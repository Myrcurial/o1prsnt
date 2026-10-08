100 REM TICKCAL.BAS -- tick calibration tool for O1PRSNT countdown timers
110 REM Run it, listen to the bell, watch the block flash, and nudge DL%
120 REM until the tick matches a real seconds hand. Then set DL% in
130 REM O1PRSNT.BAS line 155 to the value shown.
140 REM
150 REM Keys:  n = faster by 1     N = faster by 10
160 REM        b = slower by 1     B = slower by 10
170 REM        q = quit
180 REM
200 DL% = 95 : REM current guess (MAME osborne1 BIOS 1.44; real hardware is closer to 60)
210 TK% = 0 : REM ticks since start
220 FL% = 0 : REM flash state
230 PRINT CHR$(26); : REM clear screen
240 PRINT "           O1PRSNT TICK CALIBRATION"
250 PRINT
260 PRINT "Ticks: 0"
270 PRINT "DL%  : 95"
280 PRINT
290 PRINT "n/N faster -1/-10   b/B slower +1/+10   q quit"
300 PRINT
310 PRINT "Adjust until the bell matches a real seconds hand,"
320 PRINT "then set DL% in O1PRSNT.BAS line 155."
400 REM --- one tick ---
410 TK% = TK% + 1
420 S$ = MID$(STR$(TK%), 2) + "   " : R% = 3 : C% = 8 : GOSUB 5000
430 PRINT CHR$(7);
440 POKE 11266, PEEK(11266) OR 32 : REM beeper on
450 FOR D% = 1 TO 6 : NEXT D% : REM short click
460 POKE 11266, PEEK(11266) AND 223 : REM beeper off
470 FL% = 1 - FL% : S$ = " " : IF FL% = 1 THEN S$ = "#"
480 R% = 3 : C% = 20 : GOSUB 5000 : REM flashing block
490 REM --- delay loop: MUST match the per-iteration work of the countdown
495 REM --- loop in O1PRSNT.BAS (INKEY$ + ACIA PEEK) or DL% will not transfer ---
500 K$ = ""
510 FOR D% = 1 TO DL% : K$ = INKEY$ : RS% = PEEK(10752) : IF K$ <> "" THEN D% = DL%
520 NEXT D%
530 IF K$ = "" THEN GOTO 400
540 IF K$ = "n" THEN DL% = DL% - 1
550 IF K$ = "N" THEN DL% = DL% - 10
560 IF K$ = "b" THEN DL% = DL% + 1
570 IF K$ = "B" THEN DL% = DL% + 10
580 IF DL% < 1 THEN DL% = 1
590 IF K$ = "q" OR K$ = "Q" THEN GOTO 700
600 S$ = MID$(STR$(DL%), 2) + "  " : R% = 4 : C% = 8 : GOSUB 5000
610 GOTO 400
700 PRINT CHR$(26);
710 PRINT "Calibrated DL% ="; DL%
720 PRINT "Set DL% in O1PRSNT.BAS line 155 to this value."
730 END
5000 REM --- write S$ at row R%, column C% (1-based) straight into VRAM ---
5010 FOR I% = 1 TO LEN(S$)
5020   POKE 61440 + (R% - 1) * 128 + (C% - 1) + (I% - 1), ASC(MID$(S$, I%, 1))
5030 NEXT I%
5040 RETURN
9999 END

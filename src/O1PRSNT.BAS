100 REM /////////////
101 REM O1PRSNT - Osborne 1 Presentation Software
102 REM Loads slides from formatted CONTENT.TXT
103 REM
104 REM >> Because of course, you need to be able to run
105 REM    presentations from the Osborne 1
106 REM
107 REM /////////////
108 REM
120 REM Set up the variables and arrays for later use
121 REM =====================
122 CLEAR 10000 : REM Allocate 10KB for string manipulations
123 DIM FSL$(22) : REM The "Formatted Slide" Cache
124 DIM CS% : REM CURRENTLSLIDE
126 DIM I% : REM Just an Index number
128 DIM J% : REM another Index number
130 DIM K% : REM another another Index number
132 DIM KEY$ : REM input handler
134 DIM TITLE$ : REM The title of the Presentation loaded from CONTENT.TXT
136 DIM A$ : REM Used to handle disk input
138 DIM TS% : REM Total Slide count loaded from CONTENT.TXT
140 DIM STLN% : REM The start line for the slide content
142 REM We can't dimension the Slide array until we have input from CONTENT.TXT see 1050 DIM SL$(TS%,22)
144 DIM TM% : REM Countdown timer total seconds on current slide (0 = no timer)
145 DIM TMR% : REM Screen row (1-22) where the countdown is displayed
146 DIM TR% : REM Countdown seconds remaining
147 DIM DL% : REM Delay-loop calibration count for a ~1 second tick
148 DIM CA% : REM 1 = update countdown in place (ESC=), 0 = repaint whole slide
150 REM Set up the hardware now 
152 POKE 10752, 3 : REM Master Reset the ACIA
154 POKE 10752, 17 : REM Set 8-N-1 and divide-by-16 clock
155 DL% = 95 : REM ~1 second tick, calibrated on MAME osborne1 (BIOS 1.44) - fine-tune per docs/using-o1prsnt.md
157 CA% = 1 : REM Set to 0 if the countdown lands on the wrong row on your display
199 REM
200 REM Initialize slides and initiate main counter
201 REM =====================
210 CS% = 1 : REM Current Slide number
215 LS% = 0 : REM The last slide that was formatted and is sitting in the FSL$ array, begins NULL
220 GOSUB 1000:REM index the slide start positions from CONTENT.TXT
299 REM 
300 REM Opening Screen
301 REM =====================
302 REM
303 REM ASCII Art from https://patorjk.com/software/taag/#p=display&f=Slant&t=Osborne%0APresenter&x=none&v=4&h=4&w=52&we=true
310 PRINT CHR$(26);:REM Clear the screen
311 PRINT " "
312 PRINT " "
313 PRINT " "
314 PRINT "    ____       __"
315 PRINT "   / __ \_____/ /_  ____  _________  ___"
316 PRINT "  / / / / ___/ __ \/ __ \/ ___/ __ \/ _ \"
317 PRINT " / /_/ (__  ) /_/ / /_/ / /  / / / /  __/"
318 PRINT " \____/____/_.___/\____/_/  /_/ /_/\___/"
319 PRINT "    / __ \________  ________  ____  / /____  _____"
320 PRINT "   / /_/ / ___/ _ \/ ___/ _ \/ __ \/ __/ _ \/ ___/"
321 PRINT "  / ____/ /  /  __(__  )  __/ / / / /_/  __/ /"
322 PRINT " /_/   /_/   \___/____/\___/_/ /_/\__/\___/_/"
323 PRINT " "
324 PRINT "             We do what we do..."
325 PRINT "                    ...because we must."
326 PRINT "               Trust your technolust."
327 PRINT " "
328 PRINT "        https://github.com/Myrcurial/o1prsnt"
329 PRINT " "
330 PRINT "    Thanks Lee, 45 years later, I did the work,"
331 PRINT "                      but you were the inspiration."
332 PRINT " "
333 PRINT "               Press any key to start presentation";
334 PRINT " "
335 KEY$ = INPUT$(1)
396 REM
397 REM Main Presentation Loop
398 REM =====================
399 REM
400 REM >> RETURN FROM GOTO
405 REM >> This is the main screen formatting, 24 lines available, 2 consumed with footer
410 IF CS% = LS% THEN GOTO 420 : REM Skip formatting if slide hasn't changed
415 GOSUB 1500 : LS% = CS% : REM Retrieve the slide data from diskette Format and update "Last Slide" tracker
420 PRINT CHR$(26);
425 REM
430 REM Loop to display slide content
435 FOR I% = 1 TO 22 : REM - Change this to 21 when using a composite to HDMI adapter
440   PRINT FSL$(I%) : REM - Now lightning fast as it formats an entire slide at once rather than the whole presentation
450 NEXT I%
455 REM
460 REM These two or three lines are the footer - see line 471
465 PRINT "______________________________________________________________"
470 PRINT TITLE$; CS%; "/"; TS%;
471 PRINT " " : REM - Remove this line if you're using a composite to HDMI adapter with overscan issues.
475 REM
480 REM --- DCD/CTS Switch Polling ---
481 KEY$ = INKEY$ : IF KEY$ <> "" THEN GOTO 600 : REM Keyboard backup
482 IF TM% > 0 THEN GOSUB 4000 : GOTO 600 : REM Countdown timer slide - the timer polls input
483 RS% = PEEK(10752)
484 IF (RS% AND 4) = 4 THEN KEY$ = "N" : GOTO 500 : REM Bit 2 (DCD) is High
485 IF (RS% AND 8) = 8 THEN KEY$ = "P" : GOTO 500 : REM Bit 3 (CTS) is High
486 GOTO 481
490 REM
500 REM --- Debounce: Wait for switch release ---
501 RS% = PEEK(10752)
502 IF (RS% AND 12) <> 0 THEN GOTO 501 : REM Wait until both bits are 0 again
503 GOTO 600 : REM Proceed to slide change
504 REM
600 REM Process navigation input
610 IF KEY$ = "N" OR KEY$ = "n" OR KEY$ = " " OR KEY$ = CHR$(13) THEN GOSUB 2200:REM Next slide (cr also works)
630 IF KEY$ = "B" OR KEY$ = "b" THEN GOSUB 2300:REM Go back one slide but not past slide 1
650 IF KEY$ = "R" OR KEY$ = "r" THEN GOSUB 2500:REM Restart with currentslide=1
670 IF KEY$ = "Q" OR KEY$ = "q" THEN GOSUB 2700:REM Quit directly
680 IF KEY$ >= "0" AND KEY$ <= "9" THEN GOSUB 2800 : REM Handle "jump to slide"
900 IF CS% = TS% AND KEY$ <> "" THEN GOSUB 2900:REM You're at the end of the deck, start over or exit?
920 GOTO 400: You've hit any other key so we redisplay the current slide and wait for input.
995 REM 
996 REM End of main loop, the GOTO on line 920 causes the loop
998 REM END before GOSUB numbering starts - just to be sure.
999 END
1000 REM Slide data loading subroutine from CONTENT.TXT
1001 REM =====================
1002 REM
1010 REM Open the content file and load slides
1011 REM
1020 OPEN "I", #1, "CONTENT.TXT"
1022 REM
1024 REM Skip header lines (first 11 lines are header)
1026 FOR I% = 1 TO 11
1028   LINE INPUT #1, A$
1030 NEXT I%
1032 REM
1034 REM Read title of presentation from line 12, limit to leftmost 40 characters, padding with spaces
1036 LINE INPUT #1, A$
1037 TITLE$ = LEFT$(A$ + SPACE$(40),40)
1038 CLOSE #1
1039 OPEN "I", #1, "CONTENT.TXT"
1040 FOR K% = 1 TO 10000
1041   LINE INPUT #1, A$
1042 IF EOF(1) THEN GOTO 1046
1043 IF A$ = "---" THEN T1%=T1%+1
1044 NEXT K%:REM Fast forward
1046 TS%=T1%/2
1049 REM Set up the Start Line variable
1050 DIM ST%(TS%+1)
1052 REM Set up the Slide Line variable
1054 DIM SL$(23) 
1056 REM
1200 REM --- Index the file (Run once at boot) ---
1205 REM close the file first so we can open it at line 0
1210 CLOSE #1
1215 OPEN "I", #1, "CONTENT.TXT"
1220 LC% = 0 : S% = 1
1230 IF EOF(1) THEN CLOSE #1 : RETURN
1240 LINE INPUT #1, A$ : LC% = LC% + 1
1250 IF A$ <> "---" THEN GOTO 1230
1260 REM Found a separator; next line is content
1270 LINE INPUT #1, A$ : LC% = LC% + 1
1280 ST%(S%) = LC%-1 : S% = S% + 1 : REM I think this is where the loading bug is...
1290 REM Skip until next '---' to find the next slide
1300 LINE INPUT #1, A$ : LC% = LC% + 1
1310 IF A$ <> "---" THEN GOTO 1300
1320 GOTO 1230
1330 REM No Return here as we want to return from EOF(1)in 1230
1500 REM --- Fetch Slide CS% into RAM ---
1510 OPEN "I", #1, "CONTENT.TXT"
1512 FOR K% = 1 TO ST%(CS%) : LINE INPUT #1, A$ : NEXT K%:REM Fast forward through to the current start line 
1514 FOR K% = 1 TO 22 : SL$(K%)="": NEXT K% : REM clear the previous slides' worth of content
1515 TM% = 0 : TMR% = 0 : REM Reset countdown state whenever a slide is loaded
1516 LINE INPUT #1, A$
1518 FL%=VAL(A$)
1520 K%=FL%
1522 WHILE K% <= 22
1530   LINE INPUT #1, A$
1540   IF A$ = "---" THEN SL$(K%) = "" : K% = 23 : GOTO 1580
1550   SL$(K%) = A$
1560   K% = K% + 1
1570 WEND
1580 CLOSE #1
1585 IF FRE(0) < 1500 THEN X = FRE(0)
1590 REM --- SUB: Format Current Slide into Cache ---
1600 FOR K% = 1 TO 22
1620   GOSUB 3000 : REM Your existing formatter
1630   FSL$(K%) = B$ : REM Store the 52-char result
1640 NEXT K%
1650 RETURN
2000 REM
2010 REM Line 2000- is the logic to handle slide navigation
2020 REM 
2200 REM Change to next slide
2210 IF CS% < TS% THEN CS% = CS% + 1:GOTO 400 ELSE RETURN
2220 REM
2300 REM Change to previous slide
2310 IF CS% = 1 THEN GOTO 400:REM You're at the beginning, you can't go back!
2320 IF CS% > 1 THEN CS% = CS% - 1:GOTO 400 ELSE RETURN
2330 REM
2500 REM Restart the presentation
2510 CS% = 1:GOTO 400 ELSE RETURN
2520 REM
2700 REM End the Presentation due to quitting
2710 PRINT CHR$(26)
2720 PRINT "Presentation Complete."
2730 PRINT "Be sure to thank your audience!"
2740 END
2800 REM --- Interactive Jump to Slide ---
2802 PRINT CHR$(26):PRINT " ":PRINT " ":PRINT " ":PRINT " ":PRINT " "
2805 PRINT "Jump to Slide: "; KEY$; : Z0$ = KEY$ : REM Start the accumulator with the first digit
2810 K2$ = INPUT$(1)
2815 IF K2$ = CHR$(13) THEN GOTO 2850 : REM Enter pressed, proceed to VAL
2820 IF K2$ < "0" OR K2$ > "9" THEN GOTO 2810 : REM Ignore non-numeric
2825 Z0$ = Z0$ + K2$ : PRINT K2$; : REM Append digit and echo to screen
2830 IF LEN(Z0$) < 3 THEN GOTO 2810 : REM Up to 3 digits; CR ends entry early
2850 Z1% = VAL(Z0$)
2855 IF Z1% < 1 THEN Z1% = 1
2860 IF Z1% > TS% THEN Z1% = TS%
2865 CS% = Z1% : LS% = 0 : REM Clear LS% to force a re-render of the new slide
2870 PRINT " ":PRINT "Jumping to new slide location"; CS%
2880 KEY$ = "" : RETURN : REM Clear KEY$ so a jump to the last slide is just a slide
2900 PRINT CHR$(26)
2910 PRINT "Presentation Complete."
2920 PRINT "Press R to restart or any key to end"
2930 KEY$ = INPUT$(1)
2940 IF KEY$ = "R" OR KEY$ = "r" THEN CS% = 1:GOTO 400 ELSE GOTO 2700
2998 REM
2999 REM
3000 REM Line formatting subroutine - processes formatting codes
3001 REM =====================
3002 REM Input: SL$(K%) contains the line with formatting code
3003 REM Output: B$ contains the formatted line (52 chars)
3004 REM
3015 IF LEN(SL$(K%)) < 2 THEN B$ = " ":RETURN
3020 REM
3025 F$ = LEFT$(SL$(K%), 1):REM Get formatting code
3030 T$ = MID$(SL$(K%), 3):REM Get text content by skipping formatting code and space 
3035 REM
3040 IF F$ = "C" THEN GOSUB 3100:REM Center
3045 IF F$ = "L" THEN GOSUB 3200:REM Left justify
3050 IF F$ = "R" THEN GOSUB 3300:REM Right justify
3055 IF F$ = "I" THEN GOSUB 3400:REM Indent
3060 IF F$ = "B" THEN GOSUB 3500:REM Bullet
3062 IF F$ = "T" THEN GOSUB 3600:REM Countdown timer
3065 RETURN
3100 REM Center text
3105 P% = (52 - LEN(T$)) / 2
3110 IF P% < 0 THEN P% = 0
3115 B$ = LEFT$(SPACE$(P%) + T$,52)
3125 RETURN
3200 REM Left justify
3205 B$ = LEFT$(T$, 52)
3210 RETURN
3300 REM Right justify
3305 B$ = RIGHT$(SPACE$(52) + T$, 52)
3310 RETURN
3400 REM Indent (4 spaces)
3405 B$ = LEFT$("    " + T$, 52)
3410 RETURN
3500 REM Bullet (substitute "  - " for first character)
3505 B$ = LEFT$("  - " + T$, 52)
3510 RETURN
3600 REM --- Parse countdown timer line "T MM:SS" ---
3601 REM T$ holds MM:SS (or bare minutes), K% is this line's screen row
3605 C1% = INSTR(T$, ":")
3610 IF C1% > 0 THEN TM% = VAL(LEFT$(T$, C1% - 1)) * 60 + VAL(MID$(T$, C1% + 1)) ELSE TM% = VAL(T$) * 60
3620 TMR% = K% : TR% = TM%
3630 GOSUB 3700 : REM B$ = centred initial time, caller stores it in FSL$(K%)
3640 RETURN
3700 REM --- Format TR% seconds as centred M:SS into B$ ---
3710 M2% = TR% \ 60 : S2% = TR% MOD 60
3720 T2$ = MID$(STR$(M2%), 2) + ":"
3730 IF S2% < 10 THEN T2$ = T2$ + "0"
3740 T2$ = T2$ + MID$(STR$(S2%), 2)
3750 P2% = (52 - LEN(T2$)) / 2
3760 B$ = LEFT$(SPACE$(P2%) + T2$, 52)
3770 RETURN
4000 REM --- Countdown timer: runs while TM% > 0 on the current slide ---
4001 REM In: TR% seconds remaining, TMR% display row. Out: KEY$ for dispatch at 600
4010 GOSUB 4100 : REM Show the current time remaining
4020 IF TR% <= 0 THEN GOTO 4200 : REM Time is up
4030 FOR D% = 1 TO DL% : REM One second tick (calibrate DL%)
4040   KEY$ = INKEY$ : RS% = PEEK(10752)
4050   IF KEY$ <> "" THEN D% = DL%
4060   IF (RS% AND 12) <> 0 THEN D% = DL%
4080 NEXT D%
4085 IF KEY$ = "" AND (RS% AND 4) = 4 THEN KEY$ = "N"
4086 IF KEY$ = "" AND (RS% AND 8) = 8 THEN KEY$ = "P"
4087 IF (RS% AND 12) <> 0 THEN GOSUB 4300 : REM Debounce the foot switch
4090 IF KEY$ <> "" THEN RETURN : REM Presenter input wins
4092 TR% = TR% - 1
4094 IF CA% = 0 THEN KEY$ = "" : RETURN : REM Repaint mode - main loop redraws
4096 GOTO 4010
4100 REM --- Update the countdown display ---
4110 GOSUB 3700 : REM B$ = centred time string
4120 FSL$(TMR%) = B$ : REM Keep the slide cache in sync for repaints
4130 IF CA% = 0 THEN RETURN : REM Cache only - the main loop repaints
4140 PRINT CHR$(27); "="; CHR$(30 + TMR%); CHR$(51); : REM Position cursor at the countdown row
4145 PRINT MID$(B$, 20, 14); : REM Fixed 14-char centred window - never reaches column 52
4150 RETURN
4200 REM --- Time is up: beep, hold, then auto-advance ---
4210 PRINT CHR$(7); : REM Console bell, if the BIOS supports it
4220 POKE 11266, PEEK(11266) OR 32 : REM Beeper on - video PIA port B bit 5 (&H2C02)
4230 FOR D% = 1 TO DL% \ 2 : NEXT D% : REM Beep duration ~0.5 second
4240 POKE 11266, PEEK(11266) AND 223 : REM Beeper off, preserving the scroll bits
4250 FOR D% = 1 TO DL% : NEXT D% : REM Dwell so 0:00 is seen before advancing
4260 KEY$ = "N" : RETURN : REM Advance just like the N key
4300 REM --- Serial debounce: wait for switch release ---
4310 RS% = PEEK(10752) : IF (RS% AND 12) <> 0 THEN GOTO 4310
4320 RETURN
9999 REM Reminder that line numbers are limited to 4 digits and file must be CRLF and have a blank line without a line number at the end!

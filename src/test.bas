10 ' Self test: prints a dot per check, the name of any failure, then a total.
20 ' Ends with CALL 0 so the test runner knows it has finished. CALL 0 restarts the
25 ' CPC and sets mode 1 before the screenshot, so this program must stay in mode 1.
30 MEMORY &9FFF:LOAD"RSX.BIN",&A000:CALL &A000
40 MODE 1:INK 0,1:INK 1,24:BORDER 1:good=0:bad=0
50 ON ERROR GOTO 2000
100 ' --- goto ------------------------------------------------------------------
110 x=1:|GOTO,"fwd":x=2
120 x=3
130 |LABEL,"fwd"
140 name$="forward":ok=(x=1):GOSUB 1900
150 n=0
160 |LABEL,"back":n=n+1:IF n<3 THEN |GOTO,"back"
170 name$="backward, label mid-line":ok=(n=3):GOSUB 1900
180 x=0:|GOTO,"MixedCase":x=1
190 |LABEL,"mIXEDcASE":name$="case ignored":ok=(x=0):GOSUB 1900
200 l$="comp"+"uted":x=0:|GOTO,l$:x=1
210 |LABEL,"computed":name$="label in a variable":ok=(x=0):GOSUB 1900
215 x=0:|GOTO,"comp"+"uted2":x=1
216 |LABEL,"computed2":name$="label from an expression":ok=(x=0):GOSUB 1900
220 x=0:|GOTO,"pre":x=1
230 |LABEL,"prefix":x=2
240 |LABEL,"pre":name$="label that is a prefix of another":ok=(x=0):GOSUB 1900
300 ' --- things the scanner must not be fooled by --------------------------------
310 x=0:|GOTO,"decoy":x=1
320 PRINT"|LABEL,""decoy"":x=2"
330 REM |LABEL,"decoy":x=3
340 ' |LABEL,"decoy":x=4
350 DATA |LABEL,"decoy",5
360 y=124:z=&7C7C:w=31868:v=124.124:a124=124
370 |LABEL ,  "decoy"  :name$="decoys, and spaces in label":ok=(x=0):GOSUB 1900
400 ' --- gosub -----------------------------------------------------------------
410 x=0:|GOSUB,"inc":x=x+10:|GOSUB,"inc"
420 name$="gosub returns mid-line":ok=(x=12):GOSUB 1900
430 x=0:|GOSUB,"nest":name$="nested gosub":ok=(x=3):GOSUB 1900
440 x=0:GOSUB 1850:name$="native GOSUB calling |GOSUB":ok=(x=1):GOSUB 1900
450 x=0:FOR i=1 TO 5:|GOSUB,"inc":NEXT:name$="gosub inside FOR":ok=(x=5):GOSUB 1900
460 x=0:i=0:WHILE i<3:|GOSUB,"inc":i=i+1:WEND:name$="gosub inside WHILE":ok=(x=3):GOSUB 1900
470 d=0:|GOSUB,"deep":name$="recursion 30 deep":ok=(d=30):GOSUB 1900
500 ' --- if --------------------------------------------------------------------
510 x=0
520 |IF,1=1:|THEN
530   x=1
540 |ELSE
550   x=2
560 |ENDIF
570 name$="true, many lines":ok=(x=1):GOSUB 1900
580 x=0
590 |IF,1=2:|THEN
600   x=1
610 |ELSE
620   x=2
630 |ENDIF
640 name$="false, many lines":ok=(x=2):GOSUB 1900
650 x=0
660 |IF,1=2:|THEN
670   x=1
680 |ENDIF
690 name$="false, no else":ok=(x=0):GOSUB 1900
700 x=0:|IF,1:x=1:|ELSE:x=2:|ENDIF:y=x
710 name$="one line, without |THEN":ok=(y=1):GOSUB 1900
720 x=0:|IF,0:|THEN:x=1:|ELSE:x=2:|ENDIF:y=x
730 name$="one line, false":ok=(y=2):GOSUB 1900
740 x=0
750 |IF,0:|THEN
760   |IF,1:|THEN
770     x=1
780   |ELSE
790     x=2
800   |ENDIF
810   x=3
820 |ELSE
830   |IF,0:|THEN
840     x=4
850   |ELSE
860     x=5
870   |ENDIF
880 |ENDIF
890 name$="nested":ok=(x=5):GOSUB 1900
900 x=0
910 |IF,0:|THEN
920   PRINT"|ELSE":REM |ELSE
930   ' |ENDIF
940   DATA |ELSE
950   y=124:z=&7C7C
960   x=1
970 |ELSE
980   x=2
990 |ENDIF
1000 name$="skip ignores decoys":ok=(x=2):GOSUB 1900
1010 x=0:FOR i=1 TO 4
1020   |IF,i MOD 2=0:|THEN
1030     x=x+i
1040   |ENDIF
1050 NEXT
1060 name$="if inside FOR":ok=(x=6):GOSUB 1900
1070 x=0
1080 |IF,1:|THEN
1090   |GOTO,"outside"
1100 |ENDIF
1110 x=1
1120 |LABEL,"outside":name$="goto out of a block":ok=(x=0):GOSUB 1900
1200 ' --- errors go through ON ERROR GOTO ------------------------------------------
1210 e=0:el=0:|GOTO,"nowhere"
1220 name$="unknown label: ERR 8":ok=(e=8 AND el=1210):GOSUB 1900
1230 e=0:|GOSUB,"nowhere"
1240 name$="unknown gosub: ERR 8":ok=(e=8):GOSUB 1900
1250 e=0:|GOTO
1260 name$="no argument: ERR 5":ok=(e=5):GOSUB 1900
1270 e=0:|ENDIF,1
1280 name$="extra argument: ERR 5":ok=(e=5):GOSUB 1900
1290 e=0:RETURN
1300 name$="RETURN still checked: ERR 3":ok=(e=3):GOSUB 1900
1310 e=0:|GOSUB,"unmatched"
1320 name$="|IF without |ENDIF: ERR 2":ok=(e=2):GOSUB 1900
1330 e=0:|GOTO,"a","b"
1340 name$="two labels: ERR 5":ok=(e=5):GOSUB 1900
1800 ' --- speed and results --------------------------------------------------------
1810 t=TIME:FOR i=1 TO 100:|GOTO,"zz":|LABEL,"zz":NEXT:t=(TIME-t)/300
1820 PRINT:PRINT:PRINT"100 |GOTO, far label:";ROUND(t,2);"s"
1830 PRINT:PRINT"PASSED";good;"  FAILED";bad
1840 CALL &BD19:CALL 0
1850 |GOSUB,"inc":RETURN
1900 IF ok THEN PRINT".";:good=good+1 ELSE PRINT:PRINT"FAIL ";name$:bad=bad+1
1920 RETURN
2000 e=ERR:el=ERL:RESUME NEXT
3000 |LABEL,"inc":x=x+1:RETURN
3010 |LABEL,"nest":x=x+1:|GOSUB,"nest2":x=x+1:RETURN
3020 |LABEL,"nest2":x=x+1:RETURN
3030 |LABEL,"deep":d=d+1:IF d<30 THEN |GOSUB,"deep"
3040 RETURN
3050 ' Must stay the last line: no ENDIF command may follow this one
3060 |LABEL,"unmatched":|IF,0:RETURN

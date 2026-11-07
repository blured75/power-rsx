10 ' GOSUB command: named subroutines. The ordinary RETURN comes back from them.
20 MEMORY &9FFF:LOAD"RSX.BIN",&A000:CALL &A000
30 MODE 1:INK 0,1:INK 1,24:INK 2,20:INK 3,6:BORDER 1
40 LOCATE 11,1:PRINT"Named subroutines"
50 DEG
60 FOR i=0 TO 2
70   cx=120+i*200:cy=270:size=60:c=i+1
80   |GOSUB,"star"
90   cy=110
100  |GOSUB,"circle"
110 NEXT
120 LOCATE 1,24:PRINT"Press a key";:CALL &BB18:RUN"DISC"
130 '
140 |LABEL,"star"
150 MOVE cx,cy+size
160 FOR a=144 TO 720 STEP 144
170   DRAW cx+size*SIN(a),cy+size*COS(a),c
180 NEXT
190 RETURN
200 '
210 |LABEL,"circle"
220 MOVE cx,cy+size
230 FOR a=15 TO 360 STEP 15
240   DRAW cx+size*SIN(a),cy+size*COS(a),c
250 NEXT
260 |GOSUB,"dot"
270 RETURN
280 '
290 |LABEL,"dot":PLOT cx,cy,c:RETURN

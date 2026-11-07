10 ' LABEL and GOTO commands: a traffic light written as a state machine.
20 ' The next state is a string, so the jump target is chosen at run time.
30 MEMORY &9FFF:LOAD"RSX.BIN",&A000:CALL &A000
40 MODE 1:INK 0,1:INK 1,24:INK 2,6:INK 3,18:BORDER 1
50 LOCATE 8,2:PRINT"Traffic light state machine"
60 state$="red":cycle=0
70 |GOTO,state$
80 '
90 |LABEL,"red"
100 PEN 2:PRINT:PRINT"  RED     stop":state$="green"
110 |GOTO,"next"
120 '
130 |LABEL,"green"
140 PEN 3:PRINT"  GREEN   go":state$="amber"
150 |GOTO,"next"
160 '
170 |LABEL,"amber"
180 PEN 1:PRINT"  AMBER   slow down":state$="red":cycle=cycle+1
190 |GOTO,"next"
200 '
210 |LABEL,"next"
220 FOR t=1 TO 150:NEXT
230 IF cycle<3 THEN |GOTO,state$
240 '
250 PEN 1:PRINT:PRINT"Three cycles done."
260 PRINT"Named jumps are safe from RENUM."
270 PRINT:PRINT"Press a key":CALL &BB18:RUN"DISC"

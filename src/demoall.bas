10 ' All the commands together, and no line number used as a jump target.
20 ' The CPC hunts for a hidden number by halving the range.
30 MEMORY &9FFF:LOAD"RSX.BIN",&A000:CALL &A000
40 MODE 1:INK 0,1:INK 1,24:INK 2,20:INK 3,6:BORDER 1
50 RANDOMIZE TIME:secret=1+INT(RND*1000)
60 low=1:high=1000:tries=0
70 PEN 1:PRINT"Number hunt: 1 to 1000":PRINT
80 |LABEL,"hunt"
90   guess=(low+high)\2:tries=tries+1
100  |GOSUB,"compare"
110  |IF,verdict=0:|THEN
120    |GOTO,"found"
130  |ELSE
140    |IF,verdict<0:|THEN
150      low=guess+1
160    |ELSE
170      high=guess-1
180    |ENDIF
190  |ENDIF
200 |GOTO,"hunt"
210 '
220 |LABEL,"found"
230 PRINT:PEN 2:PRINT"Found";secret;"in";tries;"tries"
240 PEN 1:PRINT:PRINT"Press a key":CALL &BB18:RUN"DISC"
250 '
260 |LABEL,"compare"
270 PEN 1:PRINT"Try";guess;
280 verdict=SGN(guess-secret)
290 |IF,verdict=0:|THEN
300   PEN 2:PRINT"yes!"
310 |ELSE
320   |IF,verdict<0:|THEN:PEN 3:PRINT"too low":|ELSE:PEN 3:PRINT"too high":|ENDIF
330 |ENDIF
340 RETURN

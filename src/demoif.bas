10 ' IF THEN ELSE ENDIF commands: blocks spanning many lines, with nesting.
20 MEMORY &9FFF:LOAD"RSX.BIN",&A000:CALL &A000
30 MODE 2:INK 0,1:INK 1,24:BORDER 1
40 PRINT"FizzBuzz with multi-line blocks":PRINT
50 FOR n=1 TO 15
60   |IF,n MOD 3=0:|THEN
70     |IF,n MOD 5=0:|THEN
80       PRINT"FizzBuzz ";
90     |ELSE
100      PRINT"Fizz ";
110    |ENDIF
120  |ELSE
130    |IF,n MOD 5=0:|THEN
140      PRINT"Buzz ";
150    |ELSE
160      PRINT n;
170    |ENDIF
180  |ENDIF
190 NEXT
200 PRINT:PRINT:PRINT"The whole block can also sit on one line:":PRINT
210 FOR t=-5 TO 35 STEP 20
220   PRINT t;"C is ";
230   |IF,t<0:|THEN:PRINT"frozen":|ELSE:|IF,t>30:|THEN:PRINT"hot":|ELSE:PRINT"mild":|ENDIF:|ENDIF
240 NEXT
250 PRINT:PRINT"Press a key":CALL &BB18:RUN"DISC"

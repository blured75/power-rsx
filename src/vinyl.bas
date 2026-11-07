10 ' VINYL COLLECTION MANAGER - the big sample: every RSX command in a real program.
20 ' Only the ON ERROR line uses a line number. Everything else jumps by name.
30 MEMORY &9FFF:LOAD"RSX.BIN",&A000:CALL &A000
40 MODE 2:INK 0,1:INK 1,24:BORDER 1
50 size=100:n=0:rows=16:fileok=0
60 DIM artist$(size),title$(size),year(size),genre$(size),rating(size)
70 DIM idx(size),sortkey$(size),menu$(9),sortfield$(4)
80 ' The menu is data: each choice holds the name of the subroutine it calls
90 FOR i=1 TO 9:READ menu$(i):NEXT
100 DATA list,add,edit,remove,search,sort,stats,save,load
110 FOR i=1 TO 4:READ sortfield$(i):NEXT
120 DATA artist,title,year,rating
130 |GOSUB,"samples"
140 '
150 ' ===== Main loop =============================================================
160 |LABEL,"menu"
170 |GOSUB,"header"
180 PRINT"   1  List the collection            6  Sort"
190 PRINT"   2  Add a record                   7  Statistics"
200 PRINT"   3  Edit a record                  8  Save to disc"
210 PRINT"   4  Remove a record                9  Load from disc"
220 PRINT"   5  Search                         Q  Quit"
230 PRINT
240 LINE INPUT"Choice: ",k$
250 k$=UPPER$(k$):c=VAL(k$)
260 |IF,k$="Q":|THEN
270   |GOTO,"quit"
280 |ENDIF
290 |IF,c>=1 AND c<=9:|THEN
300   |GOSUB,menu$(c)
310 |ENDIF
320 |GOTO,"menu"
330 '
340 |LABEL,"quit"
350 PRINT:PRINT"Remember to save your changes. Leave anyway (Y/N)";
360 LINE INPUT" ",k$
370 |IF,UPPER$(k$)="Y":|THEN
380   RUN"DISC"
390 |ENDIF
400 |GOTO,"menu"
410 '
420 ' ===== Screen helpers ========================================================
430 |LABEL,"header"
440 CLS:PRINT"VINYL COLLECTION";TAB(60);n;"of";size;"records"
450 PRINT STRING$(79,"-"):RETURN
460 '
470 |LABEL,"tablehead"
480 PRINT"  #  ";"ARTIST";TAB(28);"TITLE";TAB(56);"YEAR  GENRE      RATING"
490 PRINT STRING$(79,"-"):RETURN
500 '
510 ' Prints the record at list position i
520 |LABEL,"row"
530 r=idx(i)
540 PRINT USING"###";i;:PRINT"  ";LEFT$(artist$(r),21);TAB(28);LEFT$(title$(r),26);
550 PRINT TAB(56);MID$(STR$(year(r)),2);TAB(62);LEFT$(genre$(r),10);TAB(73);STRING$(rating(r),"*")
560 RETURN
570 '
580 |LABEL,"pause"
590 PRINT:LINE INPUT"Press RETURN ",k$:RETURN
600 '
610 ' ===== 1 List ================================================================
620 |LABEL,"list"
630 |GOSUB,"header"
640 |IF,n=0:|THEN
650   PRINT"The collection is empty."
660   |GOTO,"pause"
670 |ENDIF
680 |GOSUB,"tablehead"
690 shown=0
700 FOR i=1 TO n
710   |GOSUB,"row"
720   shown=shown+1
730   |IF,shown=rows AND i<n:|THEN
740     LINE INPUT"RETURN for more, Q to stop ",k$
750     |IF,UPPER$(k$)="Q":|THEN
760       i=n
770     |ELSE
780       |GOSUB,"header":|GOSUB,"tablehead":shown=0
790     |ENDIF
800   |ENDIF
810 NEXT
820 |GOTO,"pause"
830 '
840 ' ===== 2 Add =================================================================
850 |LABEL,"add"
860 |GOSUB,"header"
870 |IF,n=size:|THEN
880   PRINT"The collection is full."
890   |GOTO,"pause"
900 |ENDIF
910 PRINT"New record. Leave the artist empty to cancel.":PRINT
920 LINE INPUT"Artist: ",a$
930 |IF,a$="":|THEN
940   RETURN
950 |ENDIF
960 LINE INPUT"Title:  ",b$
970 LINE INPUT"Genre:  ",g$
980 |GOSUB,"askyear"
990 |GOSUB,"askrating"
1000 n=n+1:r=n:idx(n)=n
1010 |GOSUB,"store"
1020 PRINT:PRINT"Added as number";n
1030 |GOTO,"pause"
1040 '
1050 ' Keeps asking until the year is valid. Empty keeps y as it was on entry.
1060 |LABEL,"askyear"
1070 LINE INPUT"Year:   ",k$
1080 |IF,k$<>"":|THEN
1090   y=VAL(k$)
1100   |IF,y<1948 OR y>2100:|THEN
1110     PRINT"Please give a year from 1948, when the LP appeared."
1120     |GOTO,"askyear"
1130   |ENDIF
1140 |ENDIF
1150 RETURN
1160 '
1170 |LABEL,"askrating"
1180 LINE INPUT"Rating (0-5): ",k$
1190 |IF,k$<>"":|THEN
1200   s=VAL(k$)
1210   |IF,s<0 OR s>5:|THEN
1220     PRINT"From 0 to 5, please."
1230     |GOTO,"askrating"
1240   |ENDIF
1250 |ENDIF
1260 RETURN
1270 '
1280 ' Copies the entered fields to record r. A double quote would break the data
1290 ' file, so each field goes through "clean" first.
1300 |LABEL,"store"
1310 t$=a$:|GOSUB,"clean":artist$(r)=t$
1320 t$=b$:|GOSUB,"clean":title$(r)=t$
1330 t$=g$:|GOSUB,"clean":genre$(r)=t$
1340 year(r)=y:rating(r)=s
1350 RETURN
1360 '
1370 |LABEL,"clean"
1380 |LABEL,"clean again"
1390 q=INSTR(t$,CHR$(34))
1400 |IF,q>0:|THEN
1410   MID$(t$,q,1)="'"
1420   |GOTO,"clean again"
1430 |ENDIF
1440 RETURN
1450 '
1460 ' ===== 3 Edit ================================================================
1470 |LABEL,"edit"
1480 |GOSUB,"list numbers"
1490 |IF,i=0:|THEN
1500   RETURN
1510 |ENDIF
1520 r=idx(i)
1530 PRINT:PRINT"RETURN alone keeps the current value.":PRINT
1540 PRINT"Artist was ";artist$(r):LINE INPUT"Artist: ",a$
1550 PRINT"Title was ";title$(r):LINE INPUT"Title:  ",b$
1560 PRINT"Genre was ";genre$(r):LINE INPUT"Genre:  ",g$
1570 y=year(r):s=rating(r)
1580 PRINT"Year was";y:|GOSUB,"askyear"
1590 PRINT"Rating was";s:|GOSUB,"askrating"
1600 |IF,a$="":|THEN:a$=artist$(r):|ENDIF
1610 |IF,b$="":|THEN:b$=title$(r):|ENDIF
1620 |IF,g$="":|THEN:g$=genre$(r):|ENDIF
1630 |GOSUB,"store"
1640 PRINT:PRINT"Record changed."
1650 |GOTO,"pause"
1660 '
1670 ' Shows the list and asks for a position. Out: i, or 0 if cancelled.
1680 |LABEL,"list numbers"
1690 |GOSUB,"header"
1700 |IF,n=0:|THEN
1710   PRINT"The collection is empty.":i=0
1720   |GOSUB,"pause"
1730   RETURN
1740 |ENDIF
1750 |GOSUB,"tablehead"
1760 FOR i=1 TO n
1770   |IF,i<=rows:|THEN
1780     |GOSUB,"row"
1790   |ENDIF
1800 NEXT
1810 |IF,n>rows:|THEN
1820   PRINT"... and";n-rows;"more. Use Search to find their numbers."
1830 |ENDIF
1840 |LABEL,"ask number"
1850 LINE INPUT"Number, RETURN to cancel: ",k$
1860 i=VAL(k$)
1870 |IF,k$<>"" AND (i<1 OR i>n):|THEN
1880   PRINT"No such number."
1890   |GOTO,"ask number"
1900 |ENDIF
1910 RETURN
1920 '
1930 ' ===== 4 Remove ==============================================================
1940 |LABEL,"remove"
1950 |GOSUB,"list numbers"
1960 |IF,i=0:|THEN
1970   RETURN
1980 |ENDIF
1990 r=idx(i)
2000 PRINT:PRINT"Remove ";artist$(r);" - ";title$(r);" (Y/N)";
2010 LINE INPUT" ",k$
2020 |IF,UPPER$(k$)<>"Y":|THEN
2030   RETURN
2040 |ENDIF
2050 ' Keep the displayed order: close the gap in the list, then move the last
2060 ' record into the free slot and repoint whichever list entry referred to it.
2070 FOR j=i TO n-1:idx(j)=idx(j+1):NEXT
2080 |IF,r<n:|THEN
2090   artist$(r)=artist$(n):title$(r)=title$(n):genre$(r)=genre$(n)
2100   year(r)=year(n):rating(r)=rating(n)
2110   FOR j=1 TO n-1
2120     |IF,idx(j)=n:|THEN:idx(j)=r:|ENDIF
2130   NEXT
2140 |ENDIF
2150 n=n-1
2160 PRINT"Removed."
2170 |GOTO,"pause"
2180 '
2190 ' ===== 5 Search ==============================================================
2200 |LABEL,"search"
2210 |GOSUB,"header"
2220 LINE INPUT"Find in artist, title or genre: ",q$
2230 |IF,q$="":|THEN
2240   RETURN
2250 |ENDIF
2260 q$=UPPER$(q$):found=0
2270 PRINT
2280 |GOSUB,"tablehead"
2290 FOR i=1 TO n
2300   r=idx(i)
2310   |IF,INSTR(UPPER$(artist$(r)+" "+title$(r)+" "+genre$(r)),q$)>0:|THEN
2320     found=found+1
2330     |IF,found<=rows:|THEN
2340       |GOSUB,"row"
2350     |ENDIF
2360   |ENDIF
2370 NEXT
2380 |IF,found=0:|THEN
2390   PRINT"Nothing found."
2400 |ELSE
2410   |IF,found>rows:|THEN
2420     PRINT"Showing";rows;"of";found;"matches."
2430   |ELSE
2440     PRINT found;"found."
2450   |ENDIF
2460 |ENDIF
2470 |GOTO,"pause"
2480 '
2490 ' ===== 6 Sort ================================================================
2500 |LABEL,"sort"
2510 |GOSUB,"header"
2520 PRINT"Sort by:  1 artist   2 title   3 year   4 best rating first":PRINT
2530 LINE INPUT"Choice: ",k$
2540 c=VAL(k$)
2550 |IF,c<1 OR c>4:|THEN
2560   RETURN
2570 |ENDIF
2580 PRINT:PRINT"Sorting...";
2590 ' Computed subroutine: builds one comparable text key per record, so the
2600 ' sort below can stay a tight loop with no jump by name inside it.
2610 |GOSUB,"key "+sortfield$(c)
2620 FOR i=2 TO n
2630   v=idx(i):j=i-1
2640   WHILE j>0
2650     |IF,sortkey$(idx(j))>sortkey$(v):|THEN
2660       idx(j+1)=idx(j):j=j-1
2670     |ELSE
2680       idx(j+1)=v:v=-1:j=0
2690     |ENDIF
2700   WEND
2710   |IF,v>=0:|THEN:idx(1)=v:|ENDIF
2720 NEXT
2730 |GOTO,"list"
2740 '
2750 |LABEL,"key artist"
2760 FOR r=1 TO n:sortkey$(r)=UPPER$(artist$(r)+" "+title$(r)):NEXT:RETURN
2770 |LABEL,"key title"
2780 FOR r=1 TO n:sortkey$(r)=UPPER$(title$(r)+" "+artist$(r)):NEXT:RETURN
2790 |LABEL,"key year"
2800 FOR r=1 TO n:sortkey$(r)=STR$(year(r))+UPPER$(artist$(r)):NEXT:RETURN
2810 |LABEL,"key rating"
2820 FOR r=1 TO n:sortkey$(r)=STR$(9-rating(r))+UPPER$(artist$(r)):NEXT:RETURN
2830 '
2840 ' ===== 7 Statistics ==========================================================
2850 |LABEL,"stats"
2860 |GOSUB,"header"
2870 |IF,n=0:|THEN
2880   PRINT"The collection is empty."
2890   |GOTO,"pause"
2900 |ENDIF
2910 total=0:oldest=1:newest=1
2920 FOR r=1 TO n
2930   total=total+rating(r)
2940   |IF,year(r)<year(oldest):|THEN:oldest=r:|ENDIF
2950   |IF,year(r)>year(newest):|THEN:newest=r:|ENDIF
2960 NEXT
2970 PRINT"Records:       ";n
2980 PRINT"Average rating:";ROUND(total/n,1);"out of 5"
2990 PRINT"Oldest:         ";artist$(oldest);" - ";title$(oldest);" (";MID$(STR$(year(oldest)),2);")"
3000 PRINT"Newest:         ";artist$(newest);" - ";title$(newest);" (";MID$(STR$(year(newest)),2);")"
3010 PRINT:PRINT"By genre:":PRINT
3020 ' For each record whose genre was not seen earlier, count that genre
3030 FOR r=1 TO n
3040   seen=0
3050   FOR j=1 TO r-1
3060     |IF,UPPER$(genre$(j))=UPPER$(genre$(r)):|THEN:seen=1:|ENDIF
3070   NEXT
3080   |IF,seen=0:|THEN
3090     c=0
3100     FOR j=r TO n
3110       |IF,UPPER$(genre$(j))=UPPER$(genre$(r)):|THEN:c=c+1:|ENDIF
3120     NEXT
3130     PRINT"  ";LEFT$(genre$(r),14);TAB(19);STRING$(MIN(c,50),CHR$(143));" ";c
3140   |ENDIF
3150 NEXT
3160 |GOTO,"pause"
3170 '
3180 ' ===== 8 Save and 9 Load, on disc ============================================
3190 |LABEL,"save"
3200 |GOSUB,"header"
3210 PRINT"Saving to VINYL.DAT":PRINT
3220 fileok=-1:ON ERROR GOTO 9000
3230 OPENOUT"VINYL.DAT"
3240 |IF,fileok:|THEN
3250   WRITE #9,n
3260   FOR r=1 TO n
3270     WRITE #9,artist$(r),title$(r),year(r),genre$(r),rating(r)
3280   NEXT
3290   CLOSEOUT
3300 |ENDIF
3310 ON ERROR GOTO 0
3320 |IF,fileok:|THEN
3330   PRINT n;"records saved."
3340 |ELSE
3350   PRINT"The disc could not be written. Nothing was saved."
3360 |ENDIF
3370 |GOTO,"pause"
3380 '
3390 |LABEL,"load"
3400 |GOSUB,"header"
3410 PRINT"Loading from VINYL.DAT":PRINT
3420 fileok=-1:ON ERROR GOTO 9000
3430 OPENIN"VINYL.DAT"
3440 ON ERROR GOTO 0
3450 |IF,fileok=0:|THEN
3460   PRINT:PRINT"No collection could be read. The current one is unchanged."
3470   |GOTO,"pause"
3480 |ENDIF
3490 INPUT #9,n
3500 FOR r=1 TO n
3510   INPUT #9,artist$(r),title$(r),year(r),genre$(r),rating(r)
3520   idx(r)=r
3530 NEXT
3540 CLOSEIN
3550 PRINT n;"records loaded."
3560 |GOTO,"pause"
3570 '
3580 ' ===== First collection, used until one is loaded =============================
3590 |LABEL,"samples"
3600 READ a$
3610 |IF,a$<>"*":|THEN
3620   READ b$,y,g$,s
3630   n=n+1:r=n:idx(n)=n
3640   artist$(r)=a$:title$(r)=b$:year(r)=y:genre$(r)=g$:rating(r)=s
3650   |GOTO,"samples"
3660 |ENDIF
3670 RETURN
3680 DATA Pink Floyd,The Dark Side of the Moon,1973,Rock,5
3690 DATA Miles Davis,Kind of Blue,1959,Jazz,5
3700 DATA Kraftwerk,Autobahn,1974,Electronic,4
3710 DATA Serge Gainsbourg,Histoire de Melody Nelson,1971,Chanson,5
3720 DATA Daft Punk,Discovery,2001,Electronic,4
3730 DATA Led Zeppelin,Led Zeppelin IV,1971,Rock,5
3740 DATA Nina Simone,Pastel Blues,1965,Jazz,4
3750 DATA Air,Moon Safari,1998,Electronic,4
3760 DATA Fela Kuti,Zombie,1976,Afrobeat,5
3770 DATA The Beatles,Abbey Road,1969,Rock,5
3780 DATA Jacques Brel,Ne me quitte pas,1972,Chanson,3
3790 DATA John Coltrane,A Love Supreme,1965,Jazz,5
3800 DATA *
9000 ' Only reached for disc errors: the routine that set the handler checks fileok
9010 fileok=0:RESUME NEXT

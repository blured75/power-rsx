# power-rsx

RSX commands that add named labels and multi-line IF blocks to Locomotive BASIC on the
Amstrad CPC 6128, with sample programs on a `.dsk`, including a full vinyl collection manager.

`|` is the key that shows `ù` on a French keyboard, so `|GOTO` is typed `ùGOTO` there.

## Commands

| Command | Effect |
|---|---|
| `\|LABEL,"name"` | Marks a place in the program. Does nothing when reached. |
| `\|GOTO,"name"` | Continues after the matching `\|LABEL`. |
| `\|GOSUB,"name"` | Same, and the ordinary `RETURN` comes back. |
| `\|IF,expr` | Runs the block when `expr` is not zero, otherwise skips to `\|ELSE` or `\|ENDIF`. |
| `\|THEN` | Optional, for readability. |
| `\|ELSE` | Starts the alternative block. |
| `\|ENDIF` | Ends the block. |

```basic
10 MEMORY &9FFF:LOAD"RSX.BIN",&A000:CALL &A000
20 |LABEL,"again"
30 INPUT"Number";n
40 |IF,n<0:|THEN
50   PRINT"negative"
60 |ELSE
70   |GOSUB,"show"
80 |ENDIF
90 |GOTO,"again"
100 |LABEL,"show":PRINT"square";n*n:RETURN
```

A statement must follow a `:` or start a line, as in any BASIC, so `|IF,x:|THEN` needs the colon.

## Behaviour worth knowing

- Labels ignore letter case. The first match in the program wins; duplicates are not reported.
- The label after `|GOTO` and `|GOSUB` can be a string variable. The one in `|LABEL` must be a literal.
- `RENUM` cannot break a jump, because labels are found by name.
- Errors go through BASIC's normal path, so `ON ERROR GOTO`, `ERR`, `ERL` and `RESUME` work:
  unknown label is error 8, wrong argument count error 5, `|IF` or `|ELSE` without `|ENDIF` error 2
  (which also opens the line in the editor, as a Syntax error always does).
- BASIC rounds reals to integers before an RSX sees them, so `|IF,0.4` is false. Comparisons are unaffected.
- As with native `GOTO`, jumping out of a `FOR` or `WHILE` leaves it on BASIC's control stack.
- A string passed to `|IF` counts as true: an RSX cannot tell it from a number.
- Avoid `|` in unquoted `DATA` that gets executed: the ROM misreads it when skipping `DATA`.

**Speed:** each `|GOTO` and `|GOSUB` scans the program from the start. A jump to a label near the end
of the self test (4.4 KB of source) takes about 100 ms, so put frequently used labels early in long programs.
`|IF` and `|ELSE` only scan forward through the block they skip.

## Machines

6128 only, tested in Caprice32. The code uses addresses from the BASIC 1.1 ROM, so installation checks the ROM
version. On anything else it prints `RSX needs a CPC 6128` and installs nothing, and the commands then give
`Unknown command`. A program that clears the screen straight after installing, like `DISC`, hides that message.

## Vinyl collection manager

`RUN"VINYL"`, or choice 5 in the menu, is the big sample. It holds up to 100 records, starts with 12 sample
records, and can list with paging, add, edit, remove, search, sort by artist, title, year or rating, show
statistics, and save to or load from `VINYL.DAT`.

It uses every command: menu choices are label names held in an array (`|GOSUB,menu$(c)`), the sort picks its
routine with `|GOSUB,"key "+sortfield$(c)`, input checks loop with `|GOTO` inside nested `|IF` blocks, and the
only line number used as a jump target is the one `ON ERROR GOTO` requires.

In Caprice32 a save goes to the emulated disk. It reaches the `.dsk` file only if you confirm the save the
emulator offers when you quit.

## Build and test

Needs `make`, `python3`, `gcc` to build RASM, and Caprice32 (`cap32`) for testing.

```sh
git clone --depth 1 https://github.com/EdouardBERGE/rasm.git tools/rasm
make -C tools/rasm

make          # build/rsx.bin and build/democpc2.dsk
make test     # runs the self test, result in screenshots/test.png
make shots    # a screenshot of the menu and each demo
make vinyl    # types through sessions in the vinyl manager, see screenshots/vinyl_*.png
```

On the CPC, or in `cap32 build/democpc2.dsk`, type `RUN"DISC"` for the menu.

| File on disk | Shows |
|---|---|
| `DISC` | Menu, written with the RSX commands |
| `DEMOGOTO` | Traffic light state machine with computed jumps |
| `DEMOGOSB` | Drawing with named subroutines |
| `DEMOIF` | FizzBuzz with nested multi-line blocks |
| `DEMOALL` | Number hunt using every command |
| `VINYL` | Vinyl collection manager |
| `TEST` | Self test, 29 checks |

`tools/mkdsk.py` writes the disk and `tools/shot.sh` runs the emulator without a window. How the commands
hook into BASIC is explained at the top of `src/rsx.asm`.

; =============================================================================
; democpc2 - structured-programming RSX commands for Locomotive BASIC 1.1
; Target : Amstrad CPC 6128 (BASIC 1.1). Installation detects the ROM and refuses
;          any other, because the addresses of BASIC's variables differ between
;          versions.
; Build  : rasm -ob build/rsx.bin src/rsx.asm
; Install: MEMORY &9FFF:LOAD"RSX.BIN",&A000:CALL &A000
;
; Commands (| is the key labelled u-grave on a French keyboard):
;   |LABEL,"name"     mark this place in the program (does nothing when reached)
;   |GOTO,"name"      continue after the matching |LABEL
;   |GOSUB,"name"     same, RETURN comes back to the statement after |GOSUB
;   |IF,expr          runs the following block when expr is not zero, otherwise
;   |THEN               continues after the matching |ELSE or |ENDIF.
;   |ELSE             |THEN is optional and only there for readability.
;   |ENDIF            Blocks nest and may span any number of lines.
;
; How jumping works
; -----------------
; BASIC calls an RSX from &F245. After parsing the arguments it saves its
; execution pointer in EXEC_PTR, calls the RSX, then reloads HL from EXEC_PTR
; and returns to the interpreter loop at &DE6F. That loop expects HL to sit on
; a statement end: 0 (end of line) or 1 (the ":" separator). So an RSX only has
; to store a new position in EXEC_PTR, and CUR_LINE if the line changed.
;
; No state is kept between calls: |IF and |ELSE find the end of their block by
; scanning the tokenised program, so no IF stack can get out of step when a
; program jumps out of a block.
; =============================================================================

        org #A000

; --- Firmware entry points ----------------------------------------------------
KL_LOG_EXT      equ #BCD1       ; register an RSX table (BC=table, HL=4-byte buffer)
KL_FIND_COMMAND equ #BCD4       ; look up an RSX (HL=name), carry set when found
KL_PROBE_ROM    equ #B915       ; ROM information (C=ROM), H=version
TXT_OUTPUT      equ #BB5A       ; print character A

; --- BASIC 1.1 system variables (read from the 6128 ROM disassembly) ----------
CUR_LINE        equ #AE1D       ; address of current line's number field, 0 = direct mode
EXEC_PTR        equ #AE58       ; execution pointer saved around an RSX call (&F27F/&F295)
PROG_START      equ #AE64       ; address of the byte just before the first line
CTRL_MARK       equ #AE19       ; control stack bookmark, restored on error (&F65D)
CTRL_SP         equ #B06F       ; top of the FOR/WHILE/GOSUB control stack, grows upward

; --- BASIC 1.1 ROM ------------------------------------------------------------
ROM_ERROR       equ #CB55       ; raise BASIC error number A (same path as ERROR n)
CTRL_LIMIT_ADD  equ #4F94       ; top + this carries when the control stack is full (&F67E)

; --- ROM version of BASIC 1.1 on the 6128, as reported by KL_PROBE_ROM ----------
BASIC_1_1       equ 2

; --- BASIC error numbers ------------------------------------------------------
ERR_SYNTAX      equ 2           ; |IF or |ELSE without a matching |ENDIF
ERR_ARGUMENT    equ 5           ; wrong number of arguments
ERR_MEMORY      equ 7           ; control stack full in |GOSUB
ERR_NO_LINE     equ 8           ; label not found ("Line does not exist")

; --- Tokens of the tokenised BASIC program -------------------------------------
TOK_EOL         equ #00         ; end of line
TOK_SEP         equ #01         ; ":" statement separator
TOK_QUOTE       equ #22         ; start and end of a string literal
TOK_COMMA       equ #2C
TOK_RSX         equ #7C         ; | then a 0 byte then the name, last char has bit 7 set
TOK_DATA        equ #8C
TOK_APOS        equ #C0         ; ' comment
TOK_REM         equ #C5
TOK_PREFIX      equ #FF         ; function token: one more byte follows

; =============================================================================
; Installation - CALL &A000. Safe to call again: a table registered twice would
; link to itself and hang every later RSX lookup, so check before registering.
; =============================================================================
install:
        ld c,0
        call KL_PROBE_ROM       ; ROM 0 is BASIC, H = its version
        ld a,h
        cp BASIC_1_1
        jr nz,install_refuse

        ld hl,name_label
        call KL_FIND_COMMAND
        ret c                   ; already installed
        ld bc,rsx_table
        ld hl,kernel_buffer
        jp KL_LOG_EXT

install_refuse:
        ld hl,refuse_text
install_refuse_loop:
        ld a,(hl)
        or a
        ret z
        call TXT_OUTPUT
        inc hl
        jr install_refuse_loop

refuse_text:
        db "RSX needs a CPC 6128",13,10,0

; --- RSX table: pointer to the names, then one JP per name, in the same order --
rsx_table:
        dw rsx_names
        jp rsx_label
        jp rsx_goto
        jp rsx_gosub
        jp rsx_if
        jp rsx_no_args          ; |THEN does nothing
        jp rsx_else
        jp rsx_no_args          ; |ENDIF does nothing

; Names end with bit 7 set on the last character. They double as the constants
; that name_is compares against while scanning a program.
rsx_names:
name_label:     db "LABE",'L'+#80
name_goto:      db "GOT",'O'+#80
name_gosub:     db "GOSU",'B'+#80
name_if:        db "I",'F'+#80
name_then:      db "THE",'N'+#80
name_else:      db "ELS",'E'+#80
name_endif:     db "ENDI",'F'+#80
                db 0

; =============================================================================
; RSX entry points. On entry A = argument count, DE = last argument.
; =============================================================================

; |LABEL,"name" - the label is only looked for by scanning, so running it does
; nothing beyond checking the argument count.
rsx_label:
        cp 1
        jp nz,error_argument
        ret

; |THEN and |ENDIF - markers only.
rsx_no_args:
        or a
        jp nz,error_argument
        ret

; |GOTO,"name"
rsx_goto:
        cp 1
        jp nz,error_argument
        call label_from_descriptor
        ; falls through to do_goto

; do_goto - jump to the label held in label_ptr and label_len.
do_goto:
        call find_label         ; HL = position after label, BC = its line
        ; falls through to set_position

; set_position - make BASIC continue at HL, on the line whose number field is at BC.
set_position:
        ld (EXEC_PTR),hl
        ld (CUR_LINE),bc
        ret

; |GOSUB,"name"
rsx_gosub:
        cp 1
        jp nz,error_argument
        call label_from_descriptor
        ; falls through to do_gosub

; do_gosub - pushes the same 6-byte frame as the ROM's GOSUB (&C791), so the
; ordinary RETURN works with it and with native GOSUB interchangeably:
;   +0 0 (normal call, not an event)  +1 return position  +3 calling line  +5 size=6
do_gosub:
        call find_label         ; HL = position after label, BC = its line
        push hl
        push bc

        ; Same overflow test as the ROM (&F672) on the new top of stack
        ld hl,(CTRL_SP)
        push hl
        ld de,6+CTRL_LIMIT_ADD
        add hl,de
        ld a,ERR_MEMORY
        jp c,raise_error
        pop hl

        ld (hl),0               ; +0 frame kind: normal GOSUB
        inc hl
        ld de,(EXEC_PTR)        ; +1 where RETURN continues
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld de,(CUR_LINE)        ; +3 line RETURN restores
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld (hl),6               ; +5 frame size, also the tag RETURN searches for
        inc hl
        ld (CTRL_SP),hl
        ld (CTRL_MARK),hl

        pop bc
        pop hl
        jr set_position

; label_from_descriptor - DE = string descriptor (length, address low, address high)
label_from_descriptor:
        ld a,(de)
        ld (label_len),a
        inc de
        ld a,(de)
        ld l,a
        inc de
        ld a,(de)
        ld h,a
        ld (label_ptr),hl
        ret

; |IF,expr - true: carry on into the block. False: go to |ELSE or |ENDIF.
; A condition such as A>3 gives -1 or 0. A real number is rounded to an integer
; by BASIC before it gets here, so |IF,0.4 counts as false.
rsx_if:
        cp 1
        jp nz,error_argument
        ld a,d
        or e
        ret nz
        ld c,1                  ; a same-level |ELSE also ends the skip
        jr skip_block

; |ELSE - only reached by running off the end of a true branch: go to |ENDIF.
rsx_else:
        or a
        jp nz,error_argument
        ld c,0                  ; only |ENDIF ends the skip
        ; falls through to skip_block

; =============================================================================
; skip_block - move execution forward to the end of the current block.
;   In : C = 1 to stop on |ELSE or |ENDIF, C = 0 to stop on |ENDIF only
;   B counts the |IF blocks opened inside the part being skipped.
;   Raises Syntax error if the program ends first.
; =============================================================================
skip_block:
        ld hl,(CUR_LINE)
        ld (scan_line),hl
        ld hl,(EXEC_PTR)
        ld b,0
skip_next:
        ld (token_ptr),hl
        call next_token
        or a
        jr z,skip_end_of_line
        cp TOK_RSX
        jr nz,skip_next

        ld de,name_if
        call name_is
        jr nz,skip_not_if
        inc b                   ; nested block opens
        jr skip_next
skip_not_if:
        ld de,name_endif
        call name_is
        jr nz,skip_not_endif
        ld a,b
        or a
        jr z,skip_found
        dec b                   ; nested block closes
        jr skip_next
skip_not_endif:
        ld a,b                  ; |ELSE only counts at our own level...
        or a
        jr nz,skip_next
        ld a,c                  ; ...and only when coming from |IF
        or a
        jr z,skip_next
        ld de,name_else
        call name_is
        jr nz,skip_next

skip_found:
        call skip_spaces        ; the interpreter expects to be on 0 or ":"
        ld bc,(scan_line)
        jp set_position

skip_end_of_line:
        ; HL is on the line's final 0. A direct command has no next line.
        ld de,(scan_line)
        ld a,d
        or e
        jp z,error_unmatched
        inc hl                  ; next line's length field; 0 means end of program
        ld a,(hl)
        inc hl
        or (hl)
        jp z,error_unmatched
        inc hl                  ; line number field, which is what CUR_LINE points to
        ld (scan_line),hl
        inc hl
        inc hl                  ; first token
        jr skip_next

; =============================================================================
; find_label - search the whole program for |LABEL,"name".
;   In : label_ptr, label_len = the name
;   Out: HL = position after the label statement, on its 0 or ":"
;        BC = address of that line's number field
;   Raises "Line does not exist" if absent. The first match in the program wins,
;   letter case is ignored. The ROM's line pointers are not used because a label
;   is found by name: RENUM cannot break it.
; =============================================================================
find_label:
        ld hl,(PROG_START)
        inc hl                  ; first line's length field
find_line:
        ld c,(hl)
        inc hl
        ld a,(hl)
        ld b,a
        or c
        jp z,error_no_label     ; length 0 marks the end of the program
        dec hl
        push hl                 ; keep the line start and length for the next line
        push bc
        inc hl
        inc hl                  ; line number field
        ld (scan_line),hl
        inc hl
        inc hl                  ; first token
find_token:
        ld (token_ptr),hl
        call next_token
        or a
        jr z,find_next_line
        cp TOK_RSX
        jr nz,find_token
        ld de,name_label
        call name_is
        jr nz,find_token
        ld (resume_ptr),hl      ; if this label differs, carry on from here

        ; Expect: , "name"  (spaces allowed)
        call skip_spaces
        cp TOK_COMMA
        jr nz,find_differs
        inc hl
        call skip_spaces
        cp TOK_QUOTE
        jr nz,find_differs
        inc hl
        ld de,(label_ptr)
        ld a,(label_len)
        ld b,a
find_compare:
        ld a,b
        or a
        jr z,find_compared
        ld a,(de)
        call to_upper
        ld c,a
        ld a,(hl)
        call to_upper
        cp c
        jr nz,find_differs
        inc hl
        inc de
        dec b
        jr find_compare
find_compared:
        ld a,(hl)               ; same start, so the literal must end here too
        cp TOK_QUOTE
        jr nz,find_differs

        inc hl
        call skip_spaces
        pop bc                  ; drop the saved length
        pop bc                  ; drop the saved line start
        ld bc,(scan_line)
        ret

find_differs:
        ld hl,(resume_ptr)
        jr find_token
find_next_line:
        pop bc                  ; length
        pop hl                  ; line start
        add hl,bc
        jr find_line

; =============================================================================
; next_token - step over one token. Same rules as the ROM's skipper at &E9FD,
; plus DATA contents are skipped as raw text so a | inside them is not misread.
;   In : HL on a token
;   Out: HL on the following token, A = the token just passed
;        A = 0 means end of line, and HL is then left on the line's final 0
;   Only A and HL change.
; =============================================================================
next_token:
        ld a,(hl)
        or a
        ret z
        inc hl
        cp 2
        ret c                   ; 1 = ":"
        cp #0E
        jr c,token_variable     ; 2-13: 2-byte offset, then name
        cp #20
        jr c,token_number       ; 14-31: numeric constants
        cp TOK_QUOTE
        jr z,token_string
        cp TOK_RSX
        jr z,token_name
        cp TOK_DATA
        jr z,token_data
        cp TOK_APOS
        jr z,token_comment
        cp TOK_REM
        jr z,token_comment
        cp TOK_PREFIX
        ret nz                  ; any other character or keyword is one byte
        inc hl
        ret

token_variable:
        inc hl
        inc hl
token_name:                     ; up to and including the byte with bit 7 set
        bit 7,(hl)
        inc hl
        jr z,token_name
        ret

token_number:
        cp #18
        ret c                   ; 14-23: the small constants 0 to 9, no payload
        cp #19
        jr z,token_number_1     ; one byte value
        cp #1F
        jr c,token_number_2     ; word value or line number
        inc hl                  ; 31: five-byte floating point
        inc hl
        inc hl
token_number_2:
        inc hl
token_number_1:
        inc hl
        ret

token_string:                   ; a missing closing quote ends at the end of line
        ld a,(hl)
        or a
        ret z
        inc hl
        cp TOK_QUOTE
        jr nz,token_string
        ret

token_data:                     ; raw text up to ":" or end of line, quotes respected
        ld a,(hl)
        or a
        ret z
        cp TOK_SEP
        ret z
        inc hl
        cp TOK_QUOTE
        jr nz,token_data
        call token_string
        jr token_data

token_comment:                  ; everything up to the end of line
        ld a,(hl)
        or a
        ret z
        inc hl
        jr token_comment

; =============================================================================
; Small helpers
; =============================================================================

; name_is - does the RSX token at token_ptr have the name at DE?
;   Out: Z set when it matches. A and DE change, HL is kept.
name_is:
        push hl
        ld hl,(token_ptr)
        inc hl                  ; skip the | token
        inc hl                  ; skip the 0 byte
name_is_loop:
        ld a,(de)
        cp (hl)
        jr nz,name_is_done      ; Z clear: different
        inc de
        inc hl
        rla                     ; bit 7 of the name character into carry
        jr nc,name_is_loop
        xor a                   ; last character matched: set Z
name_is_done:
        pop hl
        ret

; skip_spaces - move HL to the next non-space. Out: A = that byte.
skip_spaces:
        ld a,(hl)
        cp #20                  ; space
        ret nz
        inc hl
        jr skip_spaces

; to_upper - convert A to upper case if it is a lower case letter.
to_upper:
        cp #61                  ; "a"
        ret c
        cp #7B                  ; just after "z"
        ret nc
        sub 32
        ret

; =============================================================================
; Errors. These enter the ROM's normal error path, so ON ERROR GOTO, ERR, ERL and
; RESUME all behave as usual. That path resets the stack, so it never returns.
; =============================================================================
error_unmatched:
        ld a,ERR_SYNTAX
        jr raise_error
error_no_label:
        ld a,ERR_NO_LINE
        jr raise_error
error_argument:
        ld a,ERR_ARGUMENT
raise_error:
        rst #18                 ; firmware far call: selects the BASIC ROM, keeps A
        dw rom_error_far
rom_error_far:
        dw ROM_ERROR
        db 0                    ; upper ROM 0 is BASIC

; =============================================================================
; Working memory, just after the saved image. It is not part of the file, so a
; program can LOAD the RSX again without wiping the live kernel_buffer, which the
; firmware keeps in its chain of registered tables.
; =============================================================================
image_end:
kernel_buffer   equ image_end           ; 4 bytes owned by the firmware
scan_line       equ kernel_buffer+4     ; line being scanned (its number field)
token_ptr       equ scan_line+2         ; start of the token being examined
resume_ptr      equ token_ptr+2         ; where to continue after a non-matching label
label_ptr       equ resume_ptr+2        ; characters of the label searched for
label_len       equ label_ptr+2         ; their count

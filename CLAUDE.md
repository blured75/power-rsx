# democpcr2

## What this is
This project is aimed to add rsx command to the AMSTRAD CPC 6128 and to demonstrate those RSX through various programs sample. Make also a big sample with all the possibilities like a management of a vinyl collection

## Tech stack
- BASIC Amstrad CPC
- Assembly
- RASM for the assembly 
- Caprice32 or anything better for the code execution
- The produced file should be a dsk

## Conventions
- write the source code in src/
- the build artificats in build/
- make screenshot during your test inside screenshots/
- The assembly code should be rightly commented to be understandable

## Expectation
- ùlabel: allow to set a label on a line
- ùgoto,"mylabel": goto to this label
- ùgosub,"mylabel": gosub to this label
- ùif ùthen ùelse ùendif: allow to make if/then/else statement on many lines, like any mordern language
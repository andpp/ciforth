
( Returns the DEA from the inline word. Like an xt in ans. )
( A subsequent `ID.' must print the name of that word      )
: % [COMPILE] ' NFA ;
: >BODY PFA CELL+ ; ( From DEA to the DATA field of `X' *FOR A <BUILDS WORD!!*)

1 VARIABLE TABLE 1 , ( I TABLE + @ yields $100^x )
( Rotate X by I bytes right  leaving X')
: ROTRIGHT TABLE + @ U* OR ;
: & CURRENT @ @ ID. ;
( First cell : contains bits down for each COMMAER still needed)
( Second cell contains bits up to be filled by TALLY:| )
 0 VARIABLE TALLY 0 CELL+ ALLOT  ( 4 BYTES FOR COMMAER 4 FOR INSTRUCTION)
 0 VARIABLE PRO-TALLY 0 CELL+ ALLOT  ( Prototype for TALLY)
 0 VARIABLE ISS  ( Start of current instruction)
 0 VARIABLE ISL  ( Start of current instruction)
 0 VARIABLE PREVIOUS ( Previous comma, or zero)
: !POST HERE ISS !  0 PREVIOUS ! ;
: @+ >R R CELL+ R> @ ;
: !TALLY -1 TALLY ! -1 TALLY CELL+ ! ;
( Return: instruction IS complete, or not started)
( The first 8 bits of the TALLY need not be consumed. )
: AT-REST? TALLY @ 256 <  TALLY CELL+ @ -1 = AND ;
: CHECK26 AT-REST? 0= 26 ?ERROR ;
( Based on DATAFIELD of a postit, tally it)
: TALLY:, CELL+ @+ TALLY CELL+ ! @+ TALLY ! @ ISL ! ;
( Correct dictionary to have an instruction of N bytes, after           )
( `,' allocated a whole cell)
: CORRECT 0 CELL+ MINUS + ALLOT ;
: DO-POST CHECK26 !POST DUP TALLY:, DUP @ , ISL @ CORRECT ;
: INVERT -1 XOR ;
0 VARIABLE TEMP ( Should be passed via the stack )
( Build a word that tests whether it of same type as stored )
( in `TEMP'. Execution: Leave for DEA : it IS of same type )
: IS-A <BUILDS TEMP @ , DOES> @ SWAP PFA CFA CELL+ @ = ;
( Generate error if data for postit defining word was inconsistent)
: CHECK31 & HERE 4 CELLS - DUP @ SWAP CELL+ @ INVERT  AND 
    31 ?ERROR ;                                                         
HEX

( Apply to 1PI ..3PI 1FI ..3FI . Defines data layout. All work from DEA )
: >INST >BODY @ ;  ( Get INSTRUCTION/FIXUP )
: >MASK >BODY CELL+ @ ; ( Get the BITS in the code that become valid.)
: >COMMA >BODY CELL+ CELL+ @ ; ( WHICH comma-actions are expected? )
( How MANY bytes is the postit/ WHERE sits the byte to be fixed up
( counting backwards from the end of the instruction )
: >CNT >BODY CELL+ CELL+ CELL+ @ ;
( Accept a MASK with a bit up for each commaer, a MASK indicating       )
( which bits are missing from postitted, and the INSTRUCTION )
( Assemble an 1..3 byte instruction and post what is missing.)
( Data : instruction, instruction mask, comma mask, length. See >INST ..)
: 1PI <BUILDS  , INVERT , INVERT , 1 , CHECK31
DOES> [ HERE TEMP ! ] DO-POST ;
( Return for DEA : it IS of type 1PI                                  )
IS-A IS-1PI
: 2PI <BUILDS  , INVERT , INVERT , 2 , CHECK31 
DOES> [ HERE TEMP ! ] DO-POST ;
IS-A IS-2PI
: 3PI <BUILDS  , INVERT , INVERT , 3 , CHECK31 
DOES> [ HERE TEMP ! ] DO-POST ;
IS-A IS-3PI
: IS-PI  >R R IS-1PI R IS-2PI R IS-3PI OR OR R> DROP ;
DECIMAL
: CHECK28 2DUP AND 28 ?ERROR ;
( Or DATA into ADDRESS. If bits were already up its wrong.)
: OR! >R R @  CHECK28 OR R> ! ;
( And DATA into ADDRESS. If bits were already down its wrong.)
: CHECK29 2DUP OR -1 - 29 ?ERROR   ;
: AND! >R R @ ( CHECK29) AND R> ! ;
(   Based on PFA of a fixup fix into tally)
: TALLY:| CELL+ @+ TALLY CELL+ OR! @ TALLY AND! ;

( Note: the mask is inverted compared to postit, such that a            )
( postit and a fixup that go tohether have the same mask                )
( Accept a MASK with a bit up for each commaer, a MASK indicating       )
( which bits are fixupped, and the FIXUP )
( The fixup is a string of 0 CELL+ byte that is masked in this order    )
( from the beginning of the instruction.                                )
( One size fits all. Due to the mask )
: xFI <BUILDS , , INVERT , 0 , CHECK31
DOES> [ HERE TEMP ! ] DUP TALLY:| @ ISS @ OR! ;
IS-A IS-xFI

: CORRECT-I 0 CELL+ ISL @ - ROTRIGHT ;
(   Based on PFA of a fixup fix into tally )
: TALLY:|R CELL+ @+ CORRECT-I TALLY CELL+ OR! @ TALLY AND! ;
( Note: the mask is inverted compared to postit, such that a            )
( postit and a fixup that go together have a masks differing in a shift )
( over whole byte.                                                      )
( Accept a MASK with a bit up for each commaer, a MASK indicating
( which bits are fixupped, and the FIXUP )
( The fixup is a string of `0 CELL+ bytes' that is masked in from )
( behind from the end of the instruction.                               )
( One size fits all. Due to the mask )
: xFIR <BUILDS , , INVERT , 0 , CHECK31
DOES> [ HERE TEMP ! ] DUP TALLY:|R @ ISS @ ISL @ + 0 CELL+ - OR! ;
IS-A IS-xFIR
HEX  0 VARIABLE TABLE FF , FFFF , FFFFFF , FFFFFFFF ,  DECIMAL
: >IMASK >CNT CELLS TABLE + @ ;


: CHECK30 DUP PREVIOUS @ < 30 ?ERROR DUP PREVIOUS ! ;
: BOOKKEEPING CHECK30 TALLY OR! ;
( Build with the LENGTH to comma the ADDRESS that is executint the comm )
( and a MASK with the bit for this commaer.                             )
: COMMAER <BUILDS  , , DUP , ,
DOES> [ HERE TEMP ! ] @+ BOOKKEEPING   @ EXECUTE ;
IS-A IS-COMMA

( Fill in the tally prototype with COMMAMASK and INSTRUCTIONMASK )
: T! PRO-TALLY CELL+ ! PRO-TALLY ! ;
( From `PRO-TALLY' and the  INSTRUCTION code)
( prepare THE THREE CELLS for an instruction )
: PREPARE >R PRO-TALLY @ PRO-TALLY CELL+ @ R> ;
( By INCREMENTing the OPCODE a NUMBER of times generate as much )
(  instructions)
: 1FAMILY, 0 DO DUP PREPARE 1PI OVER + LOOP DROP DROP ;
: 2FAMILY, 0 DO DUP PREPARE 2PI OVER + LOOP DROP DROP ;
: 3FAMILY, 0 DO DUP PREPARE 3PI OVER + LOOP DROP DROP ;

: xFAMILY| 0 DO DUP PREPARE xFI OVER + LOOP DROP DROP ;
: xFAMILY|R 0 DO DUP PREPARE xFIR OVER + LOOP DROP DROP ;

HEX VOCABULARY ASSEMBLER IMMEDIATE
' ASSEMBLER CFA ' ;CODE 4 CELLS + !        ( PATCH ;CODE IN NUCLEUS )
: CODE ?EXEC CREATE [COMPILE] ASSEMBLER !TALLY !CSP ; IMMEDIATE
: C; CURRENT @ CONTEXT ! ?EXEC CHECK26 SMUDGE ; IMMEDIATE
: LABEL ?EXEC 0 VARIABLE SMUDGE -2 ALLOT [COMPILE] ASSEMBLER
    !CSP ; IMMEDIATE     ASSEMBLER DEFINITIONS

( ############## 8086 ASSEMBLER ADDITIONS ############################# )
( The patch ofr the assembler doesn't belong in the generic part        )
( To be used when overruling, e.g. prefix)
: lsbyte, 0 100 U/ SWAP C, ;
: W, lsbyte, lsbyte, DROP ;
: L, lsbyte, lsbyte, lsbyte, lsbyte, DROP ;

( Because there are no fixups-from-reverse that are larger than 2       )
( bytes this trick allows to debug -- but not run -- 8086 assembler     )
( of 32 bits system. The pattern 00 01 {$100} to fixup the last bit     )
( becomes 00 00 00 01 {$1000000} on a 16 bit system                     )
: 0s 2 ROTRIGHT ;  ." WARNING : testing version on 8086"                 )
( By defining 0s as a NOP you get a normal 8086 version                 )
( ############## 8086 ASSEMBLER PROPER ################################ )
( The decreasing order means that a decompiler hits them in the         )
( right order                                                           )
0 CELL+  ' ,  CFA  8000 COMMAER (RX,) ( cell relative to IP )
1        ' C, CFA  4000 COMMAER (RB,) ( byte relative to IP )
2        ' W, CFA  2000 COMMAER SG,   (  Segment: WORD      )
1        ' C, CFA  1000 COMMAER P,    ( port number ; byte     )
0 CELL+  ' ,  CFA   208 COMMAER X,    ( immediate data : address/offset )
1        ' C, CFA   204 COMMAER B,    ( immediate byte : address/offset )
0 CELL+  ' ,  CFA   102 COMMAER IX,   ( immediate data : cell)
1        ' C, CFA   101 COMMAER IB,   ( immediate byte data)

( Only valid for 16 bits real mode  A0JUL04 AvdH )
1 .
00 C000 0s 0000 0s xFIR      D0|
11 .
204 C000 0s 4000 0s xFIR      DB|
208 C000 0s 8000 0s xFIR      DW|
00  C000 0s C000 0s xFIR      R|
00 0700 0s T!
 100 0s 0 8 xFAMILY|R [BX+SI] [BX+DI] [BP+SI] [BP+DI] [SI] [DI] [BP] [BX]
 100 0s 0 8 xFAMILY|R AX| CX| DX| BX| SP| BP| SI| DI|
 100 0s 0 8 xFAMILY|R AL| CL| DL| BL| AH| CH| DH| BH|
2 .
00 3800 0s T!
0800 0s 0 8 xFAMILY|R AX'| CX'| DX'| BX'| SP'| BP'| SI'| DI'|
0208 C700 0s C600 0s xFIR |MEM ( Overrules D0| [BP] )

00 1800 0s T!   800 0s 0 0s 4 xFAMILY|R ES| CS| SS| DS|
00 18 T!     1 6 2 1FAMILY, PUSH|SG, POP|SG,

00 00 T!
 8 26 4 1FAMILY, ES:, CS:, SS:, DS:,
 8 27 4 1FAMILY, DAA, DAS, AAA, AAS,

08 01 T! 02 A0 2 1FAMILY, MOVTA, MOVFA,

3 .
0000 0100 0s T!        100 0s 0 0s 2 xFAMILY|R Y| N|
0000 0E00 0s T!   200 0s 0 0s 8 xFAMILY|R O| C| Z| CZ| S| P| L| LE|
40 0F 70 1PI J,  ( As in J, L| Y| <CALC> S, )
00 07 T!   08 40 4 1FAMILY, INCX, DECX, PUSHX, POPX,
00 07 90 1PI XCHGX,
1 01 0s 0 0s xFIR B| 
2 01 0s 1 0s xFIR W|
00 02 0s T!  2 0s 0 0s 2 xFAMILY|R F| T|
00 FF03 T!
8 0 8 2FAMILY, ADD, OR, ADC, SBB, AND, SUB, XOR, CMP,
00 FF01 T!
2 84 2 2FAMILY, TEST, XCHG,
00 FF03 088 2PI MOV,
00 FF02 08C 2PI MOVSG,
00 FF00 08D 2PI LEA,
01 0100 0s 000 0s xFIR B'|     02 0100 0s 100 0s xFIR W'|
100 01 T!
 08 04 8 1FAMILY, ADDAI, ORAI, ADCAI, SBBAI, ANDAI, SUBAI, XORAI, CMPAI,
4 .
00 01   A8 1PI TESTAI,
0 FF01 C6 2PI MOVI,
1 0 CD 1PI INT,
00 00 T!
 1 98 8 1FAMILY, CBW, CWD, hole WAIT, PUSHF, POPF, SAHF, LAHF,
28 00 9A 1PI CALLFAR,
0 1 T!  2 A4 6 1FAMILY, MOVS, CMPS, hole STOS, LODS, SCAS,
( 1) 101 7 B0 1PI MOVRI,  ( 2) 102 7 B8 1PI MOVXI,
202 0 T!  8 C2 2 1FAMILY, RET+, RETFAR+,
0 0 T!  8 C3 2 1FAMILY, RET,  RETFAR,
0 FF00 T!   1 C4 2 2FAMILY, LES, LDS,
0 0 T!
 1 CC 4 1FAMILY, INT3, hole INTO, IRET,
 1 D4 4 1FAMILY, AAM, AAD, hole XLAT,
5 .
 1 E0 4 1FAMILY, LOOPNZ, LOOPZ, LOOP, JCXZ,
 2 EC 2 1FAMILY, IN|D, OUT|D,
1000 0 T!   2 E4 2 1FAMILY, IN|P, OUT|P,
8004 0 T!   1 E8 2 1FAMILY, CALL, JMP,
2204 00 EA 1PI JMPFAR,
40 0 EB 1PI JMPS,
0 0 T!
 1 F0 6 1FAMILY, LOCK, hole REP, REPZ, HLT, CMC,
 1 F8 6 1FAMILY, CLC, STC, CLI, STI, CLD, STD,
100 C701 T!
 800 80 8 2FAMILY, ADDI, ORI, ADCI, SBBI, ANDI, SUBI, XORI, CMPI,
101 C700 T!
 800 83 8 2FAMILY, ADDSI, hole ADCSI, SBBSI, hole SUBSI, hole CMPSI,
0 2 0s 0 0s xFIR 1|   101 2 0s 2 0s xFIR V|
0 C703 T!
800 D0 8 2FAMILY, ROL, ROR, RCL, RCR, SHL, SHR, hole RAR,
0 C701 T!
6 .
800 10F6 6 2FAMILY, NOT, NEG, MUL, IMUL, DIV, IDIV,
800 FE 2 2FAMILY, INC, DEC,
100 C701 00F6 2PI TESTI,
0 C700 008F 2PI POP,
0 C700 30FE 2PI PUSH,
0 C700 T!   800 10FF 4 2FAMILY, CALLO, CALLFARO, JMPO, JMPFARO,
7 .

( ############## 8086 ASSEMBLER PROPER END ############################ )
( You may always want to use these instead of (RB,)
    : RB, ISS @ - (RB,) ;      : RX, ISS @ - (RX,) ;                    )
    : RW, ISS @ - (RW,) ;      : RL, ISS @ - (RL,) ;                    )
(   : D0|  ' [BP] REJECT D0|  ;                                         )
(   : [BP] ' D0|  REJECT [BP] ;                                         )
(   : R| ' LES, REJECT ' LDS REJECT R| ;                                )
 ASSEMBLER DEFINITIONS
(   : NEXT                                                              )
(        LODS, W1|                                                      )
(        MOV, W| F| AX'| R| BX|                                         )
(        JMPO, D0| [BX]                                                 )
(    ;                                                                  )
( ############## 8086 ASSEMBLER POST ################################## )

(   Given a DEA, return the next DEA)
: >NEXT% PFA LFA @ ;
( The CONTENT of a linkfield is not a dea, leave: it IS the endmarker   )
: VOCEND? @ FFFF AND A081 = ;
: %EXECUTE PFA CFA EXECUTE ;
( Leave the first DEA of the assembler vocabulary.                    )
: STARTVOC ' ASSEMBLER 2 +  CELL+ @ ;


(   The FIRST set is contained in the SECOND set, leaving IT            )
: CONTAINED-IN OVER AND = ;

: SET <BUILDS HERE CELL+ , CELLS ALLOT DOES> ;
( Add ITEM to the SET )
: SET+! DUP >R @ ! 0 CELL+ R> +! ;
( Make the SET empty )
: !SET DUP CELL+ SWAP ! ;
( Print the SET )
: .SET DUP @ SWAP DO I . 0 CELL+ +LOOP ;
( For the SET : it IS non-empty )
: SET? DUP @ SWAP CELL+ = 0= ;
12 SET DISS

: !DISS DISS !SET ;
: .DISS DISS DUP @ SWAP CELL+ DO
    I @ DUP IS-COMMA IF I DISS - . THEN ID.
 0 CELL+ +LOOP CR ;
: +DISS DISS SET+! ;
: DISS? DISS SET? ;

( These dissassemblers are quite similar:                               )
( if the DEA on the stack is of the right type and if the precondition  )
( is fullfilled it does the reassuring actions toward the tally as with )
( assembling and add the fixup/posti/commaer to the disassembly struct. )
( Leave the DEA.                                                        )
: DIS-PI
    DUP IS-PI IF
    AT-REST? IF
        DUP >BODY TALLY:,
        DUP +DISS
    THEN
    THEN
;

: DIS-xFI
   DUP IS-xFI IF
   DUP >MASK TALLY CELL+ @ INVERT CONTAINED-IN IF
       DUP >BODY TALLY:|
       DUP +DISS
   THEN
   THEN
;
: DIS-xFIR
   DUP IS-xFIR IF     
   DUP >MASK CORRECT-I TALLY CELL+ @ INVERT CONTAINED-IN IF
       DUP >BODY TALLY:|R
       DUP +DISS
   THEN
   THEN
;
: DIS-COMMA
   DUP IS-COMMA IF
   DUP >BODY @ TALLY @ INVERT CONTAINED-IN IF
       DUP >BODY @ TALLY OR!
       DUP +DISS
   THEN
   THEN
;

( Generate the situation back, with one less item in `DISS')
: REBUILD
    0 CELL+ MINUS DISS +!
    !TALLY
    DISS? IF
        DISS @+ SWAP !DISS
        DO
            I @ DIS-PI DIS-xFI DIS-COMMA DROP
        0 CELL+ +LOOP
    THEN
;

( Replace DEA with the next DEA                                         )
( Discard the last item of the disassembly that is either               )
( used up or incorrect                                                  )
: BACKTRACK
(   ." BACKTRACKING"                                                    )
    DROP DISS @ 0 CELL+ - @
    >NEXT%
    REBUILD
;

( If the disassembly contains something: `AT-REST?' means               )
( we have gone full cycle rest->postits->fixups->commaers               )
( Return: the disassembly CONTAINS a result.                             )
: RESULT? AT-REST? DISS? AND  ;

: RESULT
    RESULT? IF
        .DISS
        REBUILD
    THEN
;
    % RESULT +DISS                                                      
: DOIT
    !DISS
    !TALLY
    STARTVOC BEGIN
(       DUP ID.                                                         )
        DIS-PI DIS-xFI DIS-xFIR DIS-COMMA
(       ." We are at " .DISS CR CR                                      )
        RESULT
        >NEXT%
        BEGIN DUP VOCEND? DISS? AND WHILE BACKTRACK REPEAT
    DUP VOCEND? UNTIL DROP
;

0 VARIABLE POINTER
HERE POINTER !

( These dissassemblers are quite similar:                               )
( if the DEA on the stack is of the right type and if the               )
( precondition is fullfilled and if the dissassembly fits,              )
( it does the reassuring actions toward the tally as with               )
( assembling and add the fixup/posti/commaer to the                     )
( disassembly struct.                                                   )
( Leave the DEA.                                                        )
: dis-PI
    DUP IS-PI IF
    AT-REST? IF
    DUP >MASK OVER >IMASK AND POINTER @ @ AND OVER >INST = IF
        DUP >BODY TALLY:,
        DUP +DISS
        POINTER @ ISS !
        DUP >CNT POINTER +!
    THEN
    THEN
    THEN
;

: dis-xFI
   DUP IS-xFI IF
   DUP >MASK TALLY CELL+ @ INVERT CONTAINED-IN IF
   DUP >MASK  ISS @ @ AND OVER >INST = IF
       DUP >BODY TALLY:|
       DUP +DISS
   THEN
   THEN
   THEN
;

: dis-COMMA
   DUP IS-COMMA IF
   DUP >BODY @ TALLY @ INVERT CONTAINED-IN IF
       DUP >BODY @ TALLY OR!
       DUP +DISS
   THEN
   THEN
;

( Print the DEA in an appropriate way, it must be a comma-er   )
: .COMMA
    DUP >IMASK POINTER @ @ AND U.
    DUP >CNT POINTER +!
    ID.
;
: .DISS' DISS DUP @ SWAP CELL+ DO
    I @ DUP IS-COMMA IF
       .COMMA       ( DEA -- )
    ELSE
        ID.
    THEN
 0 CELL+ +LOOP CR ;

( Dissassemble one instruction from ADDRESS. )
( Leave `POINTER' pointing after that instruction. )
: (DISASSEMBLE)
    !DISS   !TALLY
    POINTER @ >R
    STARTVOC BEGIN
        dis-PI dis-xFI  dis-COMMA
        >NEXT%
(       DUP ID.                                                         )
    DUP VOCEND? RESULT? OR UNTIL DROP
    RESULT? IF
      R> DROP
      .DISS'
    ELSE
      R> COUNT . 1 POINTER ! ."  C," CR
    THEN
;

: DDD (DISASSEMBLE) ;

( Dissassemble one instruction from ADDRESS. )
: D-F-A POINTER ! (DISASSEMBLE) ;
: DIS-RANGE
    SWAP POINTER !
    BEGIN (DISASSEMBLE) POINTER @ OVER < 0= UNTIL
    DROP
;
: REJECT NFA DUP >MASK ISS @ @ AND SWAP >INST = 27 ?ERROR ;
(   : M| ' M'|  REJECT M| ;  To forbid M| M'| in combination      )



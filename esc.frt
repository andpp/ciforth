
( Copyright{2000}: Albert van der Horst, HCC FIG Holland by GNU Public License)
( $Id$)

\ Fix up the analyser with information about what are duplicators.

WANT $-PREFIX

$1B CONSTANT ESC

: esc-seq   CREATE $, DROP DOES> ESC EMIT $@ TYPE ;

"[?25l" esc-seq INVIS  \ Make cursor invisible
"[?25h" esc-seq CVVIS  \ Make cursor visible
"[H"    esc-seq HOME   \ Set cursor home
"[2J"   esc-seq CLEAR  \ Clear Page
"[4h"   esc-seq enter_insert_mode
"[4l"   esc-seq exit_insert_mode
"[M"    esc-seq delete_line
"[P"    esc-seq delete_character
"[C"    esc-seq cursor_right
"[D"    esc-seq cursor_left
"[A"    esc-seq cursor_up
"[B"    esc-seq cursor_down

\ ISO ``PAGE'' command
: PAGE   HOME CLEAR ;

\ Print N but no space and decimal.
: .no BASE @ >R DECIMAL 0  <# #S #> TYPE R> BASE ! ;

\ ISO ``AT-XY'' command.
: AT-XY   ESC EMIT   &[ EMIT   1+ .no   &; EMIT   1+ .no   &H EMIT ;

CREATE escape-color
ESC C, &[ C, HERE _ C, _ C, &; C, HERE _ C, _ C, &; C, &1 C, &m C,
CONSTANT escape-fore   CONSTANT escape-back

: send-color-escape escape-color 10 TYPE ;

: fore escape-fore SWAP CMOVE ;
: back escape-back SWAP CMOVE ;

: fore-color CREATE $, DROP DOES> $@ fore send-color-escape ;

: back-color CREATE $, DROP DOES> $@ back send-color-escape ;

: color-escape CREATE $, DROP DOES> ESC EMIT &[ EMIT $@ TYPE ;

\ Put the screen in a mode such as to print the chars in the color.
"37"    fore-color    white
"37;1m" color-ESCAPE  white2
"36"    fore-color    aqua
"32"    fore-color    green
"33"    fore-color    yellow
"31"    fore-color    red
"35"    fore-color    pink
"34"    fore-color    fblue
"30"    fore-color    f30

\ Put the screen in a mode such as the background color.
"40"    back-color    black
"41"    back-color    b41
"42"    back-color    b42
"43"    back-color    b43
"44"    back-color    blue
"45"    back-color    b45
"46"    back-color    b46
"47"    back-color    b47
"48"    back-color    b48
"49"    back-color    bwhite


\ Print text in white, not bold.
\ This is sufficient to overrule coloring.
"0m" color-ESCAPE default-white
\ Print text with foreground and background colors swapped.
"7m" color-ESCAPE reverse

VARIABLE I-MODE   0 I-MODE !
DECIMAL
: BLK>V  SCR @ BLOCK 1024 TYPE ;
VARIABLE CURSOR    0 CURSOR !
80 CONSTANT VW
: CP CURSOR @ VW MOD  ;
: SET-CURSOR   CURSOR @ VW /MOD AT-XY ;
: MOVE-CURSOR   ( WORD STAR)
DUP ^D = IF  1 ELSE       DUP ^S = IF -1 ELSE
DUP ^X = IF VW ELSE       DUP ^E = IF 0 VW - ELSE
DUP ^C = IF VW 8 * ELSE   DUP ^R = IF 0 VW 8 * - ELSE
DUP ^I = IF  8 ELSE       DUP ^M = IF VW CP - ELSE
0    THEN THEN THEN THEN THEN THEN THEN THEN CURSOR +! ;
: EM-C EMIT 1 CURSOR +! ;
: PRINT ( C --C . Print it if printable)
  DUP $1F $7F WITHIN IF
  DUP EM-C
  THEN ;
: ROUTE BEGIN KEY
  PRINT
\ DELSTORING
\ INSELETING
\ JOINITTING
\ WORDING
MOVE-CURSOR
SET-CURSOR
( DEBUG)
ESC = UNTIL ;
: E-S  ( EDIT CURRENT SCREEN )
    1 I-MODE !
\    FRAME
    0 CURSOR !   SET-CURSOR
    PAGE   BLK>V
    ROUTE
\    EXITING
\    AT-END
\    NO-FRAME
;
:  EDIT SCR ! E-S ;


;------------------------------------------------
; AUTOCPM.ASM	version 1.0		10/12/81
;
; copyright 1981 by Thom Hogan
;		    Basically Speaking Press
;		    Palo Alto, CA
;
; This program loads and executes MBASIC with O1PRSNT.BAS
;
; Modified for o1prsnt (Osborne 1 presentation software) --
; original AUTOCPM.ASM loads SuperCalc. The Osborne graphics logo
; has been replaced with the o1prsnt ASCII splash banner (plain text).
;
;------------------------------------------------
;
; EQUATES
;
clear	equ	26	;clear screen
escape	equ	1bh	;escape character
graph	equ	'g'	;graphics
nograph	equ	'G'	;nographics
pbuff	equ	9	;BDOS print buffer
bdos	equ	5	;location of BDOS
cr	equ 	0dh	;carriage return
lf	equ	0ah	;line feed
;
; START OF PROGRAM
;
	org	0100h
;
	lhld	01	;get warm start address
	mvi	l,00	;zero L register
	mov	a,h	;get page boundary in A
	sui	16h	;subtract 16 to find CCP
	mov	h,a	;put back new page boundary
	shld	ccp	;store it
;
; NOTE: the original AUTOCPM converted an ASCII logo into Osborne graphics
; characters here (sui 65 over 2047 bytes). The o1prsnt banner is plain text,
; so no conversion is needed -- it is printed exactly as stored below.
;
start:	lxi	d,startgr	;point to startgraphics
	call	print
	lxi	d,logo		;point to logo message
	call 	print		;display it
	lxi	d,stopgr	;point to end of graphics
	call	print		;display it
	lxi	d,endmes	;point to load message
	call	print
	lxi	d,filename	;point to file name
	lxi	b,20		;set counter (length+2, see note below)
move:	lhld	ccp	;get CCP back
	mvi	l,07	;bias by 7 bytes
	call	again	;move file name to CCP
	lhld	ccp	;get CCP back
	mvi	l,88h	;offset to counter
	mvi	a,08h	;lsb of ccp pointer
	mov	m,a	;put it in place
	lhld	ccp	;get CCP one more time
	mvi	l,89h	;offset to counter
	mov 	a,h	;put it in place
	mov 	m,a	;counter restored
	lhld	ccp	;get CCP last time
	pchl		;execute cold start
again:	ldax	d	;get byte to move
	mov	m,a	;move it
	inx	h	;increment location
	inx 	d	;increment location
	dcx	b	;decrement counter
	mov	a,b	;get counter in a
	ora	c	;check if done
	jnz	again	;...not done
	ret		;...done
print:	mvi	c,pbuff	;get proper call in c
	jmp	bdos	;do it
;
;STORAGE AREA
;
ccp:	ds	2	;temp storage of CCP
filename:	db	18,'MBASIC O1PRSNT.BAS',0
;		       /	   \
;	       length /   command   must be followed by at
;	    of command    string    least one zero to work properly
;
; note: if command string is longer than 8 characters,
;	you must change "lxe b,10" just before MOVE: to
;	"lxi b,length+2"
;
startgr:	db	clear,'$'
stopgr:		db	'$'
endmes:		db	cr,lf,'                 Loading O1PRSNT...','$'
;					/
;				  message to print under logo
;
logo:
	db	cr,lf
	db	'    ____       __',cr,lf
	db	'   / __ \_____/ /_  ____  _________  ___',cr,lf
	db	'  / / / / ___/ __ \/ __ \/ ___/ __ \/ _ \',cr,lf
	db	' / /_/ (__  ) /_/ / /_/ / /  / / / /  __/',cr,lf
	db	' \____/____/_.___/\____/_/  /_/ /_/\___/',cr,lf
	db	'    / __ \________  ________  ____  / /____  _____',cr,lf
	db	'   / /_/ / ___/ _ \/ ___/ _ \/ __ \/ __/ _ \/ ___/',cr,lf
	db	'  / ____/ /  /  __(__  )  __/ / / / /_/  __/ /',cr,lf
	db	' /_/   /_/   \___/____/\___/_/ /_/\__/\___/_/',cr,lf
	db	cr,lf
	db	'             We do what we do...',cr,lf
	db	'                    ...because we must.',cr,lf
	db	'               Trust your technolust.',cr,lf
	db	cr,lf
	db	'        https://github.com/Myrcurial/o1prsnt',cr,lf
	db	'$'
end





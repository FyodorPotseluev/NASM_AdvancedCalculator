%include"stud_io.inc"
global  _start

section .bss
string	resb 100	; ??? maybe increase size later ???

section .text
ErrorCheck:
	mov	dl, 1	; set ArSign flag in case 1st chr will be "("
	mov	edi, string
.char:  GETCHAR         ; process a char
.break:	cmp     al, 10  ; we have line break?
        je      .ErrChk	; then it's the end of line. Check for errors
	cmp     al, '(' ; do we have "("?
        jne     .next
	mov	ebp, 1	; set "(" flag
	cmp     dl, 1   ; we must have ArSign before "("?
        jne     .ErrMsg ; if not - print error message
        inc     bl	; increase open brackets counter
	xor	esi, esi; clear ")" flag
        jmp     .RecStr ; proceed with the next char
.next:  cmp     al, ')' ; do we have ")"?
        jne	.next2
	mov	esi, 1	; set ")" flag
	cmp	dl, 1	; we can't have ArSign before ")"
	je	.ErrMsg	
	cmp	ebp, 1	; we can't have empty brackets "()"
	je	.ErrMsg	
        xor     dl, dl  ; clear ArSign flag
	xor	ebp, ebp; clear	"(" flag
        inc     cl	; increase close brackets counter
        cmp     bl, cl	; does amnt of "(" less than amnt of ")" at the time?
	jnb	.RecStr
	jmp     .ErrMsg ; if yes - print error message
.next2:	cmp	al, '*'	
	je	.ArSign
	cmp	al, '+'
	je	.ArSign
	cmp	al, '-'
	je	.ArSign
	cmp	al, '/'
	je	.ArSign
	cmp	al, '0'	; do we
	jb	.ErrMsg
	cmp	al, '9'	; have number?
	ja	.ErrMsg
	cmp	esi, 1	; does ")" symbol goes right before?
	je	.ErrMsg
        xor     dl, dl  ; clear ArSign flag
        xor     ebp, ebp; clear "(" flag
        xor     esi, esi; clear ")" flag
	jmp	.RecStr
.ArSign:cmp	dl, 1	; is this a second ArSign in the row?
	je	.ErrMsg
	cmp	ebp, 1	; is this ArSign goes right after "("?
	je	.ErrMsg	
	mov	dl, 1	; set ArSign flag
        xor     ebp, ebp; clear "(" flag
        xor     esi, esi; clear ")" flag
.RecStr:mov	[edi], al
			; record char into "string" array
	inc	edi
	jmp	.char	
.ErrChk:cmp     bl, cl	; do we have balance of brackets?
        jne     .ErrMsg	; if no - print "NO"
        jmp     .quit 
.ErrMsg:PRINT  	"Error. You can enter only the following symbols:"
	PUTCHAR	10
	PRINT	"numbers, + - * / signs, and a balanced set of brackets"
        PUTCHAR 10
	cmp     al, 10  ; we have line break?
        je      .quit  	; then quit
.loop:	GETCHAR		; processing the rest of string
	cmp     al, 10  ; do we have line break?
	je	.quit	
	jmp	.loop
.quit:  xor	eax, eax
	xor	ebx, ebx
	xor	ecx, ecx
	xor	edx, edx
	xor	esi, esi
	xor	edi, edi
.break2:xor	ebp, ebp
	ret


_start: call	ErrorCheck
	nop
	FINISH
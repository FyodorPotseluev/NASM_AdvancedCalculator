%include"stud_io.inc"
global  _start

section .bss
string	resb 100	; ??? maybe increase size later ???
arg1s   resb 10
arg2s   resb 10
arg1b   resd 1
arg2b   resd 1
mask    resb 1
result	resb 10
FinPos  resd 1

section .data
mult    dd 10
divider dd 10

section .text
ReWriteString:
        push    ebp
        mov     ebp, esp
        pushad          ; save registers values into the stack
        xor     ecx, ecx
        xor     eax, eax; we're looking for zero byte => mov 0 to eax
        mov     edi, string
                        ; source string address now in destination index
.lp:    cmp     [edi], byte al
                        ; looking for zero-byte
        je      .RecFin ; if we've found one then jump
        inc     cl      ; else - increase position counter
        inc     edi     ; and increase the destination address
        jmp     .lp
.RecFin:mov     [FinPos], dword edi
                        ; save source string final position
        mov     edi, string
                        ; source string adress again in destination index
        mov     cl, [ebp + 12]
        dec     cl      ; prepare address of the byte we need to rewrite
        jecxz   .next   
.lp2:   inc     edi
        loop    .lp2    ; in the loop end edi contains byte address we need
                        ; to rewrite
.next   mov     esi, result
                        ; result address now in source index 
.lp3:   mov     bl, [esi]
                        ; move contest of write in address in assist regist
        mov     [edi], bl
                        ; write in the numbers digit
        inc     edi     ; next string position
        inc     esi     ; next number position
        cmp     [esi], byte 0
                        ; the end of number?    
        je      .next2
        jmp     .lp3
.next2: mov     esi, edi; >>> prepare registers for "shift left" operation
        mov     cl, [ebp + 8]
        jecxz   .ErMsg
.lp4:   inc     esi
        loop    .lp4
.break: mov     ecx, [FinPos]
        sub     ecx, esi; >>> end of preparations
        rep movsb       ; SHIFT LEFT OPERATION
        mov     [FinPos], dword edi 
        mov     cl, [ebp + 8]
        rep stosb
        jmp     .quit
.ErMsg: PRINT "lp4 - ecx register is 0"
        PUTCHAR 10
.quit:  popad           ; restore registers values
        mov     esp, ebp
        pop     ebp
        ret

NumToStr:
        push    ebp
        mov     ebp, esp
        pushad          ; push all the registers
        xor     ecx, ecx
        mov     eax, [ebp + 12]
        mov     edi, [ebp + 8]
        cmp     eax, 0  ; do we have at least one char in our text?
        je      .PrintZ ; if no then just return "0"
.lp:    xor     edx, edx; clear the 1st half of dividend
        cmp     eax, 0  ; does quotient equal "0" at last?
        je      .record ; if so, record number of chars
        div     dword [divider]
                        ; divide eax by 10
        push    edx
                        ; record current dividend into the stack
        inc     ecx     ; increase digit counter
        jmp     .lp
.record:pop     eax     ; save another digit to intermidiate storage
        add     al, 48  ; convert it into ascii format 
        mov     [edi], al
        inc     edi
        loop    .record
        jmp     .quit
.PrintZ:mov     [edi], byte '0'
        inc     edi
.quit:  mov     [edi], byte 0
.break: popad           ; pop all the registers
        pop     ebp
        ret

StrToBin:
        push    ebp
        mov     ebp, esp
        sub     esp, 4 
        pushad          ; save registers into the stack
        mov     esi, [ebp + 8]
                        ; now we have str address in source pointer
        xor     edx, edx
.char:  xor	eax, eax
	lodsb           ; get a char from the string 
        sub     eax, 48 ; convert it into a regular number
        mov     ebx, eax; save current number
        mov     eax, edx; prepare the num accumulated before for multiplying
        mul     dword [mult]
                        ; multiplying - raise digit of accum number
        mov     edx, eax; save new accumulated number
        add     edx, ebx; add current number we saved before
        cmp     [esi], byte 0
                        ; have we finished reading the text?
        jne     .char
.output:mov     [ebp - 4], edx
        popad           ; pop registers
        pop     eax
.quit:  pop     ebp
        ret

calculator:
        push    ebp
        mov     ebp, esp
        sub     esp, 4
        pushad          ; push all the register values
        xor     ecx, ecx
        lea     ebx, [ebp + 8]
        mov     esi, ebx
                        ; source - input string
        mov     edi, arg1s
                        ; destination - arg1s
.loop:  lodsd           ; load to eax
        stosb           ; store al to arg1s
        inc     ecx     ; count number's digits (str length count)
        cmp     [esi], dword '0'
        jae     .loop
        mov     [edi], byte 0   
                        ; mark string end for arg1s
        inc     ecx     ; count arithmetic sign (str length count)
        cmp     [esi], byte '+'
        je      .sum
        cmp     [esi], byte '-'
        je      .dif
        cmp     [esi], byte '*'
        je      .prod
        cmp     [esi], byte '/'
        je      .quot
.sum:   mov     [mask], byte 1b
        jmp     .arg2
.dif:   mov     [mask], byte 10b
        jmp     .arg2
.prod:  mov     [mask], byte 100b
        jmp     .arg2
.quot:  mov     [mask], byte 1000b
.arg2:  add     esi, 4  ; the second nbumer now is in esi
        mov     edi, arg2s
                        ; destination - arg2s
.loop2: lodsd           ; load to eax
        stosb           ; store al to arg2s 
        inc     ecx     ; count number's digits (str length count)
        cmp     [esi], dword '0'
        jae     .loop2
        mov     [edi], byte 0   
                        ; mark string end for arg2s
        mov     [ebp - 4], ecx
                        ; save initial string length
        xor     ecx, ecx
	xor	eax, eax
        push    arg1s
        call    StrToBin
.break2:add     esp, 4
        mov     [arg1b], eax
                        ; convert 1st argument from string to byte
	xor	eax, eax
        push    arg2s
        call    StrToBin
        add     esp, 4
        mov     [arg2b], eax
                        ; convert 2nd argument from string to byte
.break3:test    [mask], byte 1b
        jne     .SUM
        test    [mask], byte 10b
        jne     .DIF
        test    [mask], byte 100b
        jne     .PROD
        test    [mask], byte 1000b
        jne     .QUOT
.SUM:   add     eax, [arg1b]
        jmp     .convert
.DIF:   mov	eax, [arg1b]
	sub     eax, [arg2b]
        jmp     .convert
.PROD:  mul     dword [arg1b]
        jmp     .convert
.QUOT:  xor	edx, edx
	mov     eax, [arg1b]
        div     dword [arg2b]
.convert:
        push    eax
        push    result
        call    NumToStr
        add     esp, 8
                        ; prepare variables and find result's length
.break: mov     edi, result
        xor     eax, eax
.loop3: inc     ecx
        scasb
        jne     .loop3
        dec     ecx 
        sub     [ebp - 4], ecx
                        ; find shift value
        popad           ; restore register values
        pop     edx     ; put shift value into edx register
        pop     ebp
        ret 

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
        je      quit  	; then quit
.loop:	GETCHAR		; processing the rest of string
	cmp     al, 10  ; do we have line break?
	je	quit	
	jmp	.loop
.quit:  xor	eax, eax
	xor	ebx, ebx
	xor	ecx, ecx
	xor	edx, edx
	xor	esi, esi
	xor	edi, edi
.break2:xor	ebp, ebp
	ret


CalculateString:
	push	ebp
	mov	ebp, esp
	pushad		; save previous registers values
	sub	esp, 32	; allocate memory for local variables
	mov     esi, [ebp + 8]
                        ; string address saved in source index
	mov	edi, [ebp + 8]
			; prepare fo find last element in the string
	xor	eax, eax; we're looking for 0 byte => clean up eax value
.loop:	scasb
	jnz	.loop
	sub	edi, 2	; now the last string byte address is in edi
	mov	[ebp - 56], edi
			; save the last string byte address in the stack
	mov	[ebp - 36], dword 0
			; set 2nd passage flag
.PrRead:lea	ebx, [ebp - 64]
			; use assist reg to save needed stack ptr address
	mov	esp, ebx
			; again set initial stack value to rewrite string
			; saved into the stack
	xor	ebx, ebx; clean assist register
.PrRead2:
	mov	[ebp - 40], dword 1
			; set reading 1st char of arithmetic subexpression flag
	mov	[ebp - 44], dword 1
			; set reading 1st char of 2nd arith subexpr flag
	mov	[ebp - 48], dword 1
			; set reading 1st arithmetic sign flag
.read:	lodsb		; read a symbol, put it in eax
	cmp	eax, '0'; find out whether we read number or not
	jae	.num
	jmp	.sign
.num:	cmp	[ebp - 40], dword 1
			; do we read 1st sign of arith subexpression?
	jne	.NotFst	; else branch
	mov	bl, [esi - 1]
	push	ebx	; save char in stack memory using assist reg
	mov	[ebp - 40], dword 0
			; read 1st char - FALSE value
	dec	esi	
	mov	[ebp - 52], esi
			; save 1st sign of arith subexpression address
	inc	esi
	jmp     .read
.NotFst:cmp	[ebp - 44], dword 1
			; do we read 1st sign of 2nd arg of arith subexpr?
	jne	.anoth	; else just read another character
.break:	mov	[ebp - 44], dword 0
			; read 1st sign of 2nd arg of arith subexpr - FALSE	
.anoth:	mov	bl, [esi - 1]
	push    ebx	; save char in stack memory using assist reg
	jmp	.read		
.sign:	cmp     eax, '('
        je      .recurs
	cmp	[ebp - 48], dword 1
			; do we read 1st sign char in subexpression?
	jne	.EndExp ; end of the subexpression
	mov	[ebp - 48], dword 0
			; read 1st sign char in subexpression - FALSE value
	cmp	eax, 0	; have we finished reading a string?
	je	.EndStr	; it can be 2 situations "a+b" or "a" read
	cmp	eax, ')'; have we finished reading a substring?
	je	.EndStr
	cmp	eax, '+'
	je	.AddSub
	cmp	eax, '-'
	je	.AddSub
	cmp	eax, '*'
	je	.MulDiv
	cmp	eax, '/'
	je	.MulDiv
.AddSub:cmp	[ebp - 36], dword 1
			; is this the 2nd string passage?
	jne	.PrRead	; {1st string passage} read new subexpression
.MulDiv:mov	bl, [esi - 1]
	push	ebx	; save sign in stack memory using assist reg
	jmp	.read
.recurs:push	esi	; push substring address
	call	CalculateString
			; recursive call
.break6:add	esp, 4	; return back stack pointer value
	dec	esi	; decrease current source pointer (it now points at
			; the '(' 
	mov	eax, string
			; use additional register to put starting string
			; position there
	mov	ebx, esi
	inc	ebx
	sub	ebx, eax; calculate current position in the string
	push	ebx	; push it
	xor	eax, eax; clear additional register
	xor	ebx, ebx
	push	dword 2	; shift value is always 2 - we need to erase '(' 
			; and ')' signs
	call	ReWriteString 
.break7:add     esp, 8	; return stack pointer to the right place
	jmp	.read
.EndExp:push	dword 0 ; if we finish to read subexpression we need to
			; calculate
	lea	edx, [ebp - 64]	
			; start to prepare
	mov	ebx, esp
			; creating a reference point
	add	ebx, 4	; making it's the last chr in stack above zero
	xor	ecx, ecx
.loop2:	push	dword [ebx + ecx]
			; parameters to subroutine
	add	ecx, 4	; REVERSE ORDER because it's variable subroutine 
	lea	eax, [ebx + ecx]
	cmp	eax, edx; have we added all parameters to subroutine?
	jne	.loop2
.break2:call	calculator
			; put number in "result" string, put shift in edx
	lea     ebx, [ebp - 64]
        mov     esp, ebx; return stack pointer to the right place (last
			; local variable) using assist register
	mov	eax, [ebp - 52]
			; now we can use eax to calculate substitute number 
			; starting position
	sub	eax, string
	inc	eax
			; calculate substitute number starting position
	push	eax	; push substitute number starting position
	push	edx	; push shift
.break3:call	ReWriteString 
.break4:lea     ebx, [ebp - 64]
        mov     esp, ebx; return stack pointer to the right place (last
                        ; local variable) using assist register
	xor	ebx, ebx
	mov	esi, [ebp - 52]
			; next char is the 1st position of the number we've
			; just calculated
	jmp	.PrRead2
.EndStr:cmp	dword [ebp - 36], 1
			; do we finish to read the string for the 2nd time?
	jne	.SndPas ; if not - prepare the 2nd passage	
	sub	esi, 2	; if yes - the end of subroutine. Prepare to return
			; shift value - now esi contains the last not zero
			; byte of the final number
			; {number value is in result string}
	sub	[ebp - 56], esi
			; subtract initial last byte addr and get shift val
	mov	ebx, [ebp - 56]
			; using intermidiate register to save shift value
.break5:mov	[ebp - 64], ebx
			; shift value is saved and ready for return
	lea	ebx, [ebp - 32]
	mov     esp, ebx
	popad		; pop all the registers values
			; ??? Just usual retutn
	pop	ebp	; In recursion program it will be
	ret		; different ??? wat? 0_o
.SndPas:mov     esi, [ebp + 8]
                        ; start again from the 1st string address
        mov     [ebp - 36], dword 1
                        ; set 2nd passage flag - TRUE
	jmp	.PrRead

PrintString:
        push    ebp
        mov     ebp, esp
        mov     esi, [ebp + 8]
.loop:  mov     al, [esi]
        cmp     al, 0   ; has we finished printing a string?
        je      .quit
        PUTCHAR al
        inc     esi
        jmp     .loop
.quit:  PUTCHAR 10
	xor     esi, esi
        xor     eax, eax
        pop     ebp
        ret
	
_start: call	ErrorCheck
	push	string
	call	CalculateString
	push    string
        call    PrintString
        add     esp, 4
quit:	FINISH
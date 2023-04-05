%include"stud_io.inc"
global	_start

section	.bss
arg1s   resb 10
arg2s   resb 10
arg1b   resd 1
arg2b   resd 1
mask	resb 1
result	resb 10

section	.data
mult    dd 10
divider dd 10

section	.text
NumToStr:
        push    ebp
        mov     ebp, esp
	pushad		; push all the registers
        xor	ecx, ecx
	mov     eax, [ebp + 12]
        mov     edi, [ebp + 8]
        cmp     eax, 0  ; do we have at least one char in our text?
        je      .PrintZ ; if no then just return "0"
.lp:    xor     edx, edx; clear the 1st half of dividend
        cmp     eax, 0  ; does quotient equal "0" at last?
        je      .record	; if so, record number of chars
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
	inc	edi
.quit:  mov     [edi], byte 0
.break: popad		; pop all the registers
        pop     ebp
        ret

StrToBin:
        push    ebp
        mov     ebp, esp
	sub	esp, 4 
        pushad          ; save registers into the stack
        mov     esi, [ebp + 8]
                        ; now we have str address in source pointer
        xor	edx, edx
.char:  lodsb           ; get a char from the string 
        sub     eax, 48 ; convert it into a regular number
        mov     ebx, eax; save current number
        mov     eax, edx; prepare the num accumulated before for multiplying
        mul     dword [mult]
                        ; multiplying - raise digit of accum number
        mov     edx, eax; save new accumulated number
        add     edx, ebx; add current number we saved before
        cmp	[esi], byte 0
			; have we finished reading the text?
        jne    	.char
.output:mov     [ebp - 4], edx
        popad		; pop registers
	pop	eax
.quit:  pop     ebp
        ret

calculator:
	push	ebp
	mov	ebp, esp
	sub	esp, 4
	pushad		; push all the register values
	xor	ecx, ecx
	lea	ebx, [ebp + 8]
	mov	esi, ebx
			; source - input string
	mov	edi, arg1s
			; destination - arg1s
.loop:	lodsd		; load to eax
	stosb		; store al to arg1s 
	inc	ecx	; count number's digits (str length count)
	cmp	[esi], dword '0'
	jae	.loop
	mov	[edi], byte 0	
			; mark string end for arg1s
	inc	ecx	; count arithmetic sign (str length count)
	cmp	[esi], byte '+'
	je	.sum
	cmp	[esi], byte '-'
	je	.dif
	cmp	[esi], byte '*'
	je	.prod
	cmp	[esi], byte '/'
	je	.quot
.sum:	mov	[mask], byte 1b
	jmp	.arg2
.dif:	mov	[mask], byte 10b
	jmp	.arg2
.prod:	mov	[mask], byte 100b
	jmp	.arg2
.quot:	mov	[mask], byte 1000b
.arg2:	add	esi, 4	; the second numer now is in esi
	mov	edi, arg2s
			; destination - arg2s
.loop2: lodsd           ; load to eax
        stosb           ; store al to arg2s 
        inc     ecx     ; count number's digits (str length count)
        cmp     [esi], dword '0'
        jae     .loop2
        mov     [edi], byte 0   
                        ; mark string end for arg2s
	mov	[ebp - 4], ecx
			; save initial string length
	xor	ecx, ecx
	push 	arg1s
	call	StrToBin
.break2:add	esp, 4
	mov	[arg1b], eax
			; convert 1st argument from string to byte
	push	arg2s
	call	StrToBin
	add	esp, 4
	mov	[arg2b], eax
			; convert 2nd argument from string to byte
.break3:test    [mask], byte 1b
        jne    	.SUM
        test    [mask], byte 10b
        jne     .DIF
        test    [mask], byte 100b
        jne    	.PROD
        test    [mask], byte 1000b
	jne	.QUOT
.SUM:	add	eax, [arg1b]
	jmp	.convert
.DIF:	sub	eax, [arg1b]
	jmp	.convert
.PROD:	mul	dword [arg1b]
	jmp	.convert
.QUOT:	mov	eax, [arg1b]
	div	dword [arg2b]
.convert:
	push	eax
	push	result
	call	NumToStr
	add	esp, 8
			; prepare variables and find result's length
.break:	mov	edi, result
	xor	eax, eax
.loop3:	inc	ecx
	scasb
	jne	.loop3
	dec	ecx 
	sub	[ebp - 4], ecx
			; find shift value
	popad		; restore register values
	pop	edx	; put shift value into edx register
	pop	ebp
	ret 

_start:	push	dword 0
	push	dword '0'
	push 	dword '1'
	push	dword '/'
	push	dword '2'
	push	dword '1'
	call	calculator
break:	add	esp, 16	; ?????????????????????????????????????????????????
	FINISH 
; TEXT
segment	.text
; ALIGN
align	4
; GLOBL
global	$_entry:function
; LABEL
$_entry:
; ENTER
	push	ebp
	mov	ebp, esp
	sub	esp, 12
; CALL
	call	$_prints
; TRASH
	add	esp, 4
; PUSH
	push	eax
; IMM
	push	dword 0
; ADDR
	push	dword $entry
; LEAVE
	leave
; RET
	ret
; EXTRN
extern	$_prints

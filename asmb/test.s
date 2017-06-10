	.file	"test.c"
	.section	.text.unlikely,"ax",@progbits
.LCOLDB0:
	.text
.LHOTB0:
	.p2align 4,,15
	.globl	asmb
	.type	asmb, @function
asmb:
.LFB0:
	.cfi_startproc
	testq	%rcx, %rcx
	movq	%rdi, %rax
	movq	%rdx, %r9
	je	.L2
	xorl	%r8d, %r8d
	.p2align 4,,10
	.p2align 3
.L3:
	imulq	(%rsi,%r8,8), %rax
	cqto
	idivq	(%r9,%r8,8)
	addq	$1, %r8
	cmpq	%r8, %rcx
	jne	.L3
.L2:
	rep ret
	.cfi_endproc
.LFE0:
	.size	asmb, .-asmb
	.section	.text.unlikely
.LCOLDE0:
	.text
.LHOTE0:
	.ident	"GCC: (GNU) 5.3.0"
	.section	.note.GNU-stack,"",@progbits

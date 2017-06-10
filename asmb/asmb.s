# #include <stddef.h>
# long asmb(long a, long b[], long c[], size_t n)
# {
#     size_t i;
#     for (i=0; i<n; i++)
#         a = (a*b[i])/c[i];
#     return a;
# }
    .text
    .globl asmb
    .type asmb, @function

# asmb(%rdi = a, %rsi = b, %rdx = c, %rcx = n)
asmb:
    movq %rdi, %rax
    movq %rdx, %rdi
    movq $8, %r8
1:
    cmpq %r8, %rcx
    jb 2f
    cqo
    imulq -64(%rsi, %r8, 8)
    idivq -64(%rdi, %r8, 8)
    cqo
    imulq -56(%rsi, %r8, 8)
    idivq -56(%rdi, %r8, 8)
    cqo
    imulq -48(%rsi, %r8, 8)
    idivq -48(%rdi, %r8, 8)
    cqo
    imulq -40(%rsi, %r8, 8)
    idivq -40(%rdi, %r8, 8)
    cqo
    imulq -32(%rsi, %r8, 8)
    idivq -32(%rdi, %r8, 8)
    cqo
    imulq -24(%rsi, %r8, 8)
    idivq -24(%rdi, %r8, 8)
    cqo
    imulq -16(%rsi, %r8, 8)
    idivq -16(%rdi, %r8, 8)
    cqo
    imulq -8(%rsi, %r8, 8)
    idivq -8(%rdi, %r8, 8)
    addq $8, %r8
    jmp 1b
2:
    subq $8, %r8
    cmpq %r8, %rcx
    je 4f
3:
    cqo
    imulq (%rsi, %r8, 8)
    idivq (%rdi, %r8, 8)
    incq %r8
    cmpq %r8, %rcx
    jne 3b
4:
    ret

    .size asmb, .-asmb

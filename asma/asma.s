# long asma(long a, long b, long c)
# {
#     return (a * b) / c;
# }
    .text
    .globl asma
    .type asma, @function

# asma(%rdi = a, %rsi = b, %rdx = c)
asma:
    # save c
    movq %rdx, %rcx
    # %rdx:%rax = a
    movq %rdi, %rax
    cqo
    # %rdx:%rax *= b
    imul %rsi
    # %rax = %rdx:%rax / c
    idiv %rcx
    # return
    ret

    .size asma, .-asma

global _start

section .data
    hello db "Hello world!", 0x0A
    hello_len equ $ - hello

section .bss

section .text
; Main function
_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, hello
    mov rdx, hello_len
    syscall

    mov rax, 60
    mov rdi, 0
    syscall
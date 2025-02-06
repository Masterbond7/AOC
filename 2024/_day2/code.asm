global _start

section .data
    hello db "Hello World!", 0x0A, 0x00
    hello_len equ $-hello

section .text
; Main function
_start:
    ; Print hello world
    mov rax, 1 ; sys_write
    mov rdi, 1 ; stdout
    mov rsi, hello
    mov rdx, hello_len
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Jump to error_exit

    ; Exit the program
    mov rax, 60
    mov rdi, 0
    syscall

; Function to exit with error code if there is a problem
error_exit:
    ; Exit with errno code
    mov rdi, rax ; Move return (error) value to rdi
    neg rdi      ; Make it positive
    mov rax, 60  ; sys_exit
    syscall
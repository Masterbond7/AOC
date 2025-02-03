global _start

section .data
    ; Path and length for input file
    path db "./input", 0x00
    path_len equ $ - path

section .bss
    output resb 144
    size resb 8

section .text
; Main function
_start:
    ; Open input file
    mov rax, 2    ; sys_open
    mov rdi, path ; Filename pointer
    mov rsi, 0    ; Flags (O_RDONLY)
    syscall
    push rax ; Push file descriptor onto stack

    ; Get file status and size
    mov rax, 5           ; sys_fstat
    mov rdi, qword [rsp] ; Move the 64bit num from stack to RDI
    mov rsi, output      ; Give pointer to output for the return value
    syscall
    mov rax, qword [output + 0x30] ; Get file size

    ; Close input file
    mov rax, 3 ; close(2)
    pop rdi ; Pop fd from stack into fd parameter
    syscall

    ; Exit program
    mov rax, 60
    mov rdi, 0
    syscall
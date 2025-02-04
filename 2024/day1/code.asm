global _start

section .data
    ; Path and length for input file
    path db "./input", 0x00
    path_len equ $ - path

section .bss

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
    sub rsp, 144         ; Move stack pointer 144 bits for return struct
    mov rsi, rsp         ; Return structure to the stack
    syscall
    mov rax, qword [rsp + 0x30] ; Get file size
    add rsp, 136                ; Move the stack pointer back - 8 bytes (144-8)
    mov [rsp], rax             ; Move size from rax to [size] var

    ; Get rid of file size
    add rsp, 8 ; Move back 8 bytes

    ; Close input file
    mov rax, 3 ; close(2)
    pop rdi ; Pop fd from stack into fd parameter
    syscall

    ; Exit program
    mov rax, 60
    mov rdi, 0
    syscall
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

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Jump to error_exit

    push rax      ; Otherwise push file descriptor onto stack


    ; Get file status and size
    mov rax, 5           ; sys_fstat
    mov rdi, qword [rsp] ; Move the fd from stack to RDI
    sub rsp, 144         ; Allocate 144 bits on the stack for return struct
    mov rsi, rsp         ; Return structure to the stack
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Jump to error_exit

    mov rax, qword [rsp + 0x30] ; Otherwise, get file size
    add rsp, 136                ; Move the stack pointer back - 8 bytes (144-8)
    mov [rsp], rax              ; Move size from rax to stack


    ; Get rid of file size
    add rsp, 8 ; Move back 8 bytes


    ; Close input file
    mov rax, 3 ; sys_close
    pop rdi    ; Pop fd from stack into fd parameter
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Jump to error_exit


    ; Exit program
    mov rax, 60
    mov rdi, 0
    syscall


error_exit:
    ; Exit with errno code
    mov rdi, rax ; Move return (error) value to rdi
    neg rdi      ; Make it positive
    mov rax, 60  ; sys_exit
    syscall
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
    mov rdi, qword [rsp] ; Copy the fd from stack to RDI
    sub rsp, 144         ; Allocate 144 bits on the stack for return struct
    mov rsi, rsp         ; Return structure to the stack
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Jump to error_exit

    mov rax, qword [rsp + 0x30] ; Otherwise, get file size
    add rsp, 136                ; Move the stack pointer back - 8 bytes (144-8)
    mov [rsp], rax              ; Move size from rax to stack


    ; Map some memory and load the file!
    mov rax, 9      ; sys_mmap
    mov rdi, 0      ; Set address to 0 (let the computer choose)
    mov rsi, [rsp]  ; Set the length to the file size (from stack)
    mov rdx, 0x01   ; Set protection to PROT_READ
    mov r10, 0x02   ; Set flags to MAP_PRIVATE
    mov r8, [rsp+8] ; Set the fd (from stack)
    mov r9, 0       ; Set the offset to 0
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Jump to error_exit

    sub rsp, 8     ; Allocate 8 bytes on stack
    mov [rsp], rax ; Move file pointer to stack


    ; Calculate list size required (RAX)
    mov rax, [rsp+8] ; Load file size into RAX
    mov rdx, 0       ; Set RDX to 0
    mov rbx, 14      ; 14 bytes per line
    div rbx          ; Divide to calculate no. lines (/numbers)

    mov rdx, 0 ; Set RDX to 0
    mov rbx, 4 ; 4 bytes per number (11111-99999 so 32-bit)
    mul rbx    ; Multiply to calculate bytes per list of numbers


    ; Unmap the memory for the input file
    mov rax, 11      ; sys_munmap
    mov rdi, [rsp]   ; Set addr to file pointer (from stack)
    mov rsi, [rsp+8] ; Set len to the file size (from stack)
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Jump to error_exit

    add rsp, 8 ; Free 8 bytes from stack (remove file pointer)


    ; Get rid of file size
    add rsp, 8 ; Free 8 bytes from stack (remove file size)


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
global _start

section .data
    path db "./input.txt", 0x00
    path_len equ $-path

section .text
; Main function
_start:
    ; Init rbp
    mov rbp, rsp



    ; Open input file
    mov rax, 2    ; sys_open
    mov rdi, path ; Filename pointer
    mov rsi, 0    ; Flags (O_RDONLY)
    syscall
    
    cmp rax, 0    ; If error (<0)
    jl error_exit ; Then jump to error_exit
    
    push rax ; Otherwise push FD onto the stack (rbp-8)



    ; Get file status (for size)
    sub rsp, 144      ; Allocate 144 bits on the stack for return struct
    mov rax, 5        ; sys_fstat
    mov rdi, [rbp-8]  ; Copy FD from stack to RDI
    mov rsi, rsp      ; Put return structure in the stack
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Then jump to error_exit
    
    mov rax, [rsp+0x30] ; Otherwise, get file size
    add rsp, 136        ; Move stack pointer back (but keep 8 for size)
    mov [rsp], rax      ; Move size to stack (rbp-16)



    ; Map some memory and load the file
    mov rax, 9        ; sys_mmap
    mov rdi, 0        ; Set address to 0 (let the computer choose)
    mov rsi, [rbp-16] ; Set the length to the file size (rbp-16)
    mov rdx, 0x01     ; Set proteciton to PROT_READ
    mov r10, 0x02     ; Set the flags to MAP_PRIVATE
    mov r8, [rbp-8]   ; Set the fd from stack (rbp-8)
    mov r9, 0         ; Set the offset to 0
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Then jump to error_exit

    sub rsp, 8     ; Otherwise, allocate 8 bytes for pointer to file
    mov [rsp], rax ; Move pointer to stack (rbp-24)



    ; Dump the first 16 bytes
    mov rax, 1
    mov rdi, 1
    mov rsi, [rbp-24]
    mov rdx, 16
    syscall



    ; Unmap the memory for the input file
    mov rax, 11 ; sys_munmap
    mov rdi, [rbp-24] ; Set addr to file pointer (rbp-24)
    mov rsi, [rbp-16] ; Set length to file size (rbp-16)
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Then jump to error_exit

    mov qword [rbp-24], 0 ; Otherwise, remove file pointer



    ; Close the input file
    mov rax, 3       ; sys_close
    mov rdi, [rbp-8] ; Copy FD of input file from stack (rbp-8)
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Then jump to error_exit



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
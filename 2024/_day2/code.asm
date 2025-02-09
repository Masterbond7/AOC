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



    ; Loop through file
    add rsp, 32 ; 8b safe#, 8b unsafe#, and 8 to load line, 8 for offset
    mov qword [rbp-32], 0 ; Zero # of safe reports (rbp-32)
    mov qword [rbp-40], 0 ; Zero # of unsafe reports (rbp-40)
    mov qword [rbp-48], 0 ; Zero Reading offset (rbp-48)
    .read_file_loop:
        mov qword [rbp-56], 0 ; Zero line contents (rbp-56)
        mov r12, 0            ; Zero line contents index

        ; Loop to read the chars in each line
        .read_line_loop:
            ; Get a char
            mov rax, [rbp-24]     ; Get pointer to file
            add rax, [rbp-48]     ; Add offset
            mov dil, [rax]        ; Copy char from A into DI
            add qword [rbp-48], 1 ; Add one to reading offset

            cmp dil, 0x20 ; If char is space
            je .read_line_loop_space

            cmp dil, 0x0A ; If char is new line 
            je .read_line_loop_newl

            ; If not space or newl, parse char (->RDI) to integer (RAX->)
            movzx rax, byte [rbp-56+r12] ; Set RAX to current line_contents[r12]
            mov rdx, 0                   ; Zero RDX
            mov rbx, 10                  ; Set RBX=10 (multiply by 10)
            mul rbx                      ; Multiply to make room for next value
            mov byte [rbp-56+r12], al    ; Move multiplied result back

            movzx rdi, dil            ; Copy over char to DI
            call char_to_int          ; Convert char to int
            add al, byte[rbp-56+r12]  ; Add old result (for multi digit nums)
            mov byte [rbp-56+r12], al ; Copy ans from A to line_contents[r12]
            jmp .read_line_loop       ; Continue reading line

            .read_line_loop_space:
            inc r12                   ; Increment line contents index
            jmp .read_line_loop ; Continue reading line

            .read_line_loop_newl:
            ; Do stuff like print line contents
            mov rax, 1
            mov rdi, 1
            mov rbx, rbp
            sub rbx, 56 ;56 is line contents; 48 is reading offset
            mov rsi, rbx
            mov rdx, 8
            syscall

            mov r10, [rbp-48]
            mov r11, [rbp-16]
            cmp r10, r11 ; If offset is less than file size
            jb .read_file_loop     ; Read next line, otherwise, continue

    


    ; Unmap the memory for the input file
    mov rax, 11 ; sys_munmap
    mov rdi, [rbp-24] ; Set addr to file pointer (rbp-24)
    mov rsi, [rbp-16] ; Set length to file size (rbp-16)
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Then jump to error_exit

    mov qword [rbp-24], 0 ; Otherwise, remove file pointer
    add rsp, 8            ; Free 8 the bytes from stack



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



; Function to convert char ADDR (->RDI) to integer (RAX->)
char_to_int:
    mov rax, 0    ; Zero result

    cmp rdi, 0x30 ; If less than '0'
    jb .exit_err  ; Exit with error
    cmp rdi, 0x39 ; If greater than '9'
    jg .exit_err  ; Exit with error

    ; Otherwise, convert char to int and add to result
    sub rdi, 0x30 ; Char - '0'
    add rax, rdi  ; Set result
    ret           ; Return

    ; Exit with error code 255
    .exit_err:
        mov rax, 60
        mov rdi, 255
        syscall



; Function to exit with error code if there is a problem
error_exit:
    ; Exit with errno code
    mov rdi, rax ; Move return (error) value to rdi
    neg rdi      ; Make it positive
    mov rax, 60  ; sys_exit
    syscall
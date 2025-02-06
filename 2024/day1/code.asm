global _start

section .data
    ; Path and length for input file
    path db "./input", 0x00
    path_len equ $ - path
    newl db 0x0A

section .bss

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
    jl error_exit ; Jump to error_exit

    push rax      ; Otherwise push file descriptor onto stack (rbp-8)



    ; Get file status and size
    mov rax, 5             ; sys_fstat
    mov rdi, qword [rbp-8] ; Copy the fd from stack to RDI
    sub rsp, 144           ; Allocate 144 bits on the stack for return struct
    mov rsi, rsp           ; Return structure to the stack
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Jump to error_exit

    mov rax, qword [rsp + 0x30] ; Otherwise, get file size
    add rsp, 136                ; Move the stack pointer back - 8 bytes (144-8)
    mov [rsp], rax              ; Move size from rax to stack (rbp-16)



    ; Map some memory and load the file!
    mov rax, 9        ; sys_mmap
    mov rdi, 0        ; Set address to 0 (let the computer choose)
    mov rsi, [rbp-16] ; Set the length to the file size (from stack)
    mov rdx, 0x01     ; Set protection to PROT_READ
    mov r10, 0x02     ; Set flags to MAP_PRIVATE
    mov r8, [rbp-8]   ; Set the fd (from stack)
    mov r9, 0         ; Set the offset to 0
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Jump to error_exit

    sub rsp, 8     ; Allocate 8 bytes on stack
    mov [rsp], rax ; Move file pointer to stack (rbp-24)



    ; Calculate no. lines and list size required (rbp-32,-40)
    mov rax, [rbp-16] ; Load file size into RAX
    mov rdx, 0        ; Set RDX to 0
    mov rbx, 14       ; 14 bytes per line
    div rbx           ; Divide to calculate no. lines (/numbers)
    push rax          ; Push no. lines to stack (rbp-32)

    mov rdx, 0   ; Set RDX to 0
    mov rbx, 4   ; 4 bytes per number (11111-99999 so 32-bit)
    mul rbx      ; Multiply to calculate bytes per list of numbers
    push rax     ; Push list size required to stack (rbp-40)



    ; Map memory to store the two lists of numbers
    mov rbx, 2
    .make_lists:
        ; Reserve memory and add address to stack
        mov rax, 9         ; sys_mmap
        mov rdi, 0         ; Set address to 0 (let the computer choose)
        mov rsi, [rbp-40]  ; Set the length to required no. of bytes for list
        mov rdx, 0x03      ; Set protection to PROT_READ | PROT_WRITE
        mov r10, 0x22      ; Set flags to MAP_PRIVATE | MAP_ANONYMOUS
        mov r8, -1         ; Set fd to -1 (required as no file)
        mov r9, 0          ; Set offset to 0 (required as no file)
        syscall

        cmp rax, 0    ; If error (<0)
        jl error_exit ; Jump to error_exit
        push rax      ; Otherwise push pointer to stack (rbp-48,-56)

        ; Decrement rbx counter and loop if >0
        dec rbx
        cmp rbx, 0
        jnz .make_lists


    ; Loop through List A from input file and display
    mov r12, 0; Set r12 (counter) to 0
    .load_listA:
        ; Calculate offset then read address
        mov rax, 14       ; 14 bytes per line
        mul r12           ; Multiply by line num being read
        add rax, [rbp-24] ; Add address to offset

        ; Convert ascii at ADDR (->RDI) to integer (RAX->)
        mov rdi, rax ; Set address to read
        call ascii_to_int
        mov r10, rax ; Temp store output in r10

        ; Calculate offset and write to List A
        mov rax, 4            ; 4 bytes per number
        mul r12               ; Multiply by line num
        add rax, [rbp-48]     ; Add address to offset
        mov dword [rax], r10d ; Move 4 byte result to address

        ; Increment r12 counter and loop if < line count
        inc r12
        cmp r12, [rbp-32]
        jl .load_listA


    ; Loop through List B from input file and display
    mov r12, 0; Set r12 (counter) to 0
    .load_listB:
        ; Calculate offset then read address
        mov rax, 14       ; 14 bytes per line
        mul r12           ; Multiply by line num being read
        add rax, 8        ; Offset to start read at 8th char of line (2nd num)
        add rax, [rbp-24] ; Add address to offset

        ; Convert ascii at ADDR (->RDI) to integer (RAX->)
        mov rdi, rax ; Set address to read
        call ascii_to_int
        mov r10, rax ; Temp store output in r10

        ; Calculate offset and write to List B
        mov rax, 4            ; 4 bytes per number
        mul r12               ; Multiply by line num
        add rax, [rbp-56]     ; Add address to offset
        mov dword [rax], r10d ; Move 4 byte result to address

        ; Increment r12 counter and loop if < line count
        inc r12
        cmp r12, [rbp-32]
        jl .load_listB
    

    ; Sort lists A & B at ADDR (->RDI) of length (->RSI)
    mov rdi, [rbp-48] ; List A
    mov rsi, [rbp-40] ; List length
    call insertion_sort

    mov rdi, [rbp-56] ; List B
    mov rsi, [rbp-40] ; List length
    call insertion_sort


    ; Loop through the lists get diff between A[i] and B[i], store sum in RAX



    ; Unload the input file and its memory
    mov rax, 11       ; sys_munmap
    mov rdi, [rbp-24] ; Set addr to file pointer (from stack)
    mov rsi, [rbp-16] ; Set len to the file size (from stack)
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Jump to error_exit

    mov qword [rbp-24], 0 ; Zero 8 bytes from stack (remove file pointer)
    mov qword [rbp-16], 0 ; Zero 8 bytes from stack (remove file size)



    ; Close input file
    mov rax, 3       ; sys_close
    mov rdi, [rbp-8] ; Get fd from stack for fd parameter
    syscall

    cmp rax, 0    ; If error (<0)
    jl error_exit ; Jump to error_exit

    mov qword [rbp-8], 0 ; Zero 8 bytes from stack (remove fd)



    ; Unload the two lists and remove their pointers
    mov rbx, 2
    mov r12, rbp
    .unmake_lists:
        ; Unload list at r12-48 (initially the same as rbp-48) and later lists
        mov rax, 11       ; sys_munmap
        mov rsi, [rbp-40] ; Set length to length of list
        mov rdi, [r12-48] ; Set addr to List address
        syscall

        cmp rax, 0    ; If error (<0)
        jl error_exit ; Jump to error_exit

        mov qword [r12-48], 0 ; Zero 8 bytes from stack (remove list pointer)

        ; Subtract 8 bytes from r12 to get to next list address
        sub r12, 8

        ; Decrement rbx counter and loop if >0
        dec rbx
        cmp rbx, 0
        jnz .unmake_lists
    add rsp, 16 ; 16 bytes were freed!

    ; Exit program
    mov rax, 60
    mov rdi, 0
    syscall


; Sort list at ADDR (->RDI) of length (->RSI)
insertion_sort:
    mov r10, 0 ; Set sorted index to 0
    sub rsi, 4 ;

    .sort_i:
        add r10, 4 ; Go to sort the next item
        mov r8, r10 ; keep track of where we are pointing

        .insert_check:
            mov eax, dword[rdi+r8]   ; Load item to sort into rax
            cmp eax, dword[rdi+r8-4] ; Compare with previous item
            jb .swap                  ; If needed, swap
            jmp .loop                 ; otherwise, loop

        .swap:
            mov r11d, dword [rdi+r8-4] ; Store higher value temp
            mov [rdi+r8-4], eax          ; Put lower value in place
            mov [rdi+r8], r11d       ; Put higher value in place
            
            sub r8, 4; move 4 back and check again (if not too far)
            cmp r8, rsi
            jb .insert_check

        .loop:
            ; Looping conditions
            cmp r10, rsi ; Compare sorted index to length of array
            jb .sort_i   ; Loop until end of array

        ; Once array is sorted, returm
        ret


; Function to exit with error code if there is a problem
error_exit:
    ; Exit with errno code
    mov rdi, rax ; Move return (error) value to rdi
    neg rdi      ; Make it positive
    mov rax, 60  ; sys_exit
    syscall


; Function to print a newline
func_newl:
    ; Also print a newline
    mov rdi, 1        ; stdout
    mov rsi, newl     ; Newline char
    mov rdx, 1        ; 1 byte
    mov rax, 1        ; sys_write
    syscall

    ; Return
    ret
; Function to convert text at ADDR (->RDI) to integer (RAX->)
ascii_to_int:
    ; Init vars
    mov rax, 0 ; Set result to 0
    mov r10, 0 ; Set offset counter to 0

    .loop:
        ; Load char and check if number
        movzx r11, byte [rdi+r10] ; Load address+offset
        cmp r11, 0x30 ; If less than '0'
        jb .exit      ; Jump to .exit
        cmp r11, 0x39 ; If greater than '9'
        jg .exit      ; Jump to .exit

        ; Increment offset counter
        inc r10

        ; Convert char to int and add to result
        sub r11, 0x30 ; Char - '0'
        imul rax, 10  ; Multiply current result by 10
        add rax, r11  ; Add new number to result
        jmp .loop     ; Loop until non-number char found

    ; Return to main code
    .exit:
        ret
bits 64

global _start

section .bss
        list1: resb 256
        list1Size: resb 1
        list2: resb 256
        list2Size: resb 1

section .text
        ; rdi:code
        exit:
                mov rax, 60
                syscall

        ; rdi:base, rsi:power -> rax
        power:
                push rbp
                mov rbp, rsp
                push rdx
                mov rax, 1
                test rsi, rsi
                jz .done
                mov rax, 1
        .powerLoop:
                mul rdi
                dec rsi
                test rsi, rsi
                jnz .powerLoop
        .done:
                pop rdx
                pop rbp
                ret

        ; rdi:string, rsi:list, rdx:pListSize
        parseStringIntoList:
                push rbp
                mov rbp, rsp
        .parseNumber:
                xor r8, r8
        .getStringNumberSizeLoop:
                inc r8
                mov al, [rdi + r8]
                cmp al, ','
                je .parseStringIntoNumber
                test al, al
                jnz .getStringNumberSizeLoop
        .parseStringIntoNumber:
        .parseStringIntoNumberLoop:
                dec r8
                movzx rax, byte [rdi]
                sub rax, '0'
                push rax
                push rdi
                push rsi
                mov rdi, 10
                mov rsi, r8
                call power
                pop rsi
                pop rdi
                mov rbx, rax
                pop rax
                imul rax, rbx
                add byte [rsi], al
                inc rdi
                test r8, r8
                jnz .parseStringIntoNumberLoop
                inc byte [rdx]
                mov al, byte [rdi]
                test al, al
                jz .done
                inc rdi
                inc rsi
                jmp .parseNumber
        .done:
                pop rbp
                ret

        ; rax:valueA, rdx:valueB -> rax
        min:
                push rbp
                mov rbp, rsp
                cmp rax, rdx
                jbe .done
                mov rax, rdx
        .done:
                pop rbp
                ret

        ; rax:valueA, rdx:valueB -> rax
        max:
                push rbp
                mov rbp, rsp
                cmp rax, rdx
                jge .done
                mov rax, rdx
        .done:
                pop rbp
                ret

        ; rdi:listA, rsi:sizeOfListA, rdx:listB, rcx:sizeOfListB -> xmm0
        findMedianOfTwoArrays:
                push rbp
                mov rbp, rsp
                ; Check that A < B, otherwise swap and recursive call
                mov al, byte [rcx]
                cmp byte [rsi], al
                jb .proceed
                push rdi
                push rsi
                mov rdi, rdx
                mov rsi, rcx
                pop rdx
                pop rcx
                call findMedianOfTwoArrays
                pop rbp
                ret
        .proceed:
                xor r8, r8
                movzx r9, byte [rsi]
        .loop:
                mov rax, r8
                add rax, r9
                shr rax, 1 ; (r8 + r9) / 2, the bitshift right divides by 2
                push rax
                movzx rax, byte [rsi]
                movzx r14, byte [rcx]
                add rax, r14
                inc rax
                shr rax, 1 ; (sizeOfListA + sizeOfListB + 1) / 2
                sub rax, [rsp]
                push rax
        .getALeft:
                mov rax, [rsp + 8]
                test rax, rax
                jnz .mid1Valid
                mov r10, 0x8000000000000000
                jmp .getARight
        .mid1Valid:
                movzx r10, byte [rdi + rax - 1]
        .getARight:
                movzx r14, byte [rsi]
                cmp rax, r14
                jne .mid1Valid2
                mov r11, 0x7FFFFFFFFFFFFFFF
                jmp .getBLeft
        .mid1Valid2:
                movzx r11, byte [rdi + rax]
        .getBLeft:
                mov rax, [rsp]
                test rax, rax
                jnz .mid2Valid
                mov r12, 0x8000000000000000
                jmp .getBRight
        .mid2Valid:
                movzx r12, byte [rdx + rax - 1]
        .getBRight:
                movzx r14, byte [rcx]
                cmp rax, r14
                jne .mid2Valid2
                mov r13, 0x7FFFFFFFFFFFFFFF
                jmp .finalize
        .mid2Valid2:
                movzx r13, byte [rdx + rax]
        .finalize:
                cmp r10, r13
                jg .invalidPartition
                cmp r12, r11
                jg .invalidPartition
                movzx rax, byte [rsi]
                movzx rbx, byte [rcx]
                add rax, rbx 
                test rax, 1
                jnz .oddCase
                mov rax, r10
                mov rdx, r12
                call max
                push rax
                mov rax, r11
                mov rdx, r13
                call min
                pop rdx
                add rax, rdx
                cvtsi2sd xmm0, rax
                mov rax, 2
                cvtsi2sd xmm1, rax
                divsd xmm0, xmm1
                jmp .done
        .oddCase:
                mov rax, r10
                mov rdx, r12
                call max
                cvtsi2sd xmm0, rax
                jmp .done
        .invalidPartition:
                ; While r8 <= r9 keep going
                cmp r8, r9
                jg .done
                cmp r10, r13
                jg .high
                mov r8, [rsp + 8]
                inc r8
                jmp .loop
        .high:
                mov r9, [rsp + 8]
                dec r9
                jmp .loop
        .done:
                add rsp, 16 ; Make sure to re-align the stack because of the two pushes   
                pop rbp
                ret

        ; rsp:argc, rsp+8:argv
        _start:
                ; Check that argc is 2
                mov rsi, [rsp]
                cmp rsi, 3
                mov rdi, 1
                jne exit
                ; Get argv[0] and parse the argument into list1
                lea rdx, [rsp+8]
                mov rdi, [rdx+8]
                lea rsi, [list1]
                lea rdx, [list1Size]
                call parseStringIntoList
                ; Get argv[1] and parse the argument into list2
                lea rdx, [rsp+8]
                mov rdi, [rdx+16]
                lea rsi, [list2]
                lea rdx, [list2Size]
                call parseStringIntoList
                lea rdi, [list1]
                lea rsi, [list1Size]
                lea rdx, [list2]
                lea rcx, [list2Size]
                call findMedianOfTwoArrays
                mov rdi, 0
                jmp exit
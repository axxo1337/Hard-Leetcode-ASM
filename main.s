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
                dec r8 ; Yes the size is correct, but remove 1 to make sure last digit is *10^0
                xor r9, r9
        .parseStringIntoNumberLoop:
                push rdi
                push rsi
                mov rdi, 10
                mov rsi, r8
                sub rsi, r9
                call power ; 10^(r8-r9), r8 starts as r8-1
                pop rsi
                pop rdi
                push rdx
                mov rdx, rax
                movzx rax, byte [rdi]
                sub rax, '0'
                mul rdx ; rax is now actual value
                pop rdx
                movzx rbx, byte [rdx]
                add byte [rsi + rbx], al
                inc rdi ; string += 1 (next char)
                inc r9
                cmp r9, r8
                jne .parseStringIntoNumberLoop
                inc rsi
                mov al, [rdi]
                test al, al
                jz .done
                inc rsi
                inc rdi
                jmp .parseNumber
        .done:
                pop rbp
                ret

        ; rdi:listA, rsi:sizeOfListA, rdx:listB, rcx:sizeOfListB
        findMedianOfTwoArrays:
                push rbp
                mov rbp, rsp

                pop rbp
                ret

        ; [rsp]:argc, [rsp+8]:argv
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
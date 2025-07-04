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
                xor r8, r8
                mov byte [rsi], 0 
        .calculateNumSizeLoop:
                inc r8
                cmp byte [rdi+r8], ','
                je .parseNumLoop
                cmp byte [rdi+r8], 0
                jne .calculateNumSizeLoop
        .parseNumLoop:
                movzx rax, byte [rdi]
                sub rax, '0' ; This converts the character digit into its real number
                push rsi
                push rdi
                mov rdi, 10
                mov rsi, r8
                dec rsi
                push rax
                call power
                mov rdx, rax
                pop rax
                mul rdx
                pop rdi
                pop rsi
                add byte [rsi], al 
                inc rdi
                dec r8
                test r8, r8
                jnz .parseNumLoop
                inc rsi
                cmp byte [rdi], 0
                jz .done
                inc rdi
                mov byte [rsi], 0
                xor r8, r8
                jmp .calculateNumSizeLoop
        .done:
                pop rbp
                ret

        ; rbp:listA, rsi:sizeOfListA, rdx:listB, rcx:sizeOfListB
        findMedianOfTwoArrays:
                push rbp
                mov rbp, rsp

                pop rbp
                ret

        ; [rsp]:argc, [rsp+8]:argv
        _start:
                ; Check that argc is 2
                mov rsi, [rsp]
                cmp rsi, 2
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
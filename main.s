bits 64

global _start

section .data
        dotChar: db '.'
        newline: db 10

section .bss
        list1: resb 256
        list1Size: resb 1
        list2: resb 256
        list2Size: resb 1
        buffer: resb 32

section .text
        ; rdi:code
        exit:
                mov rax, 60
                syscall

        printFloat:
                push rbp
                mov rbp, rsp
                sub rsp, 16
                movq xmm0, rax
                cvttsd2si rbx, xmm0
                cvtsi2sd xmm1, rbx
                subsd xmm0, xmm1
                mov rdi, rbx
                call printInteger
                mov rax, 10
                cvtsi2sd xmm2, rax
                mulsd xmm0, xmm2
                cvttsd2si rcx, xmm0
                test rcx, rcx
                jz .printNewline
                push rcx
                mov rax, 1
                mov rdi, 1
                mov rsi, dotChar
                mov rdx, 1
                syscall
                pop rcx
                add rcx, '0'
                mov [buffer], cl
                mov rax, 1
                mov rdi, 1
                mov rsi, buffer
                mov rdx, 1
                syscall
        .printNewline:
                mov rax, 1
                mov rdi, 1
                mov rsi, newline
                mov rdx, 1
                syscall
                add rsp, 16
                pop rbp
                ret

        printInteger:
                push rbp
                mov rbp, rsp
                test rdi, rdi
                jnz .nonZero
                mov byte [buffer], '0'
                mov rax, 1
                mov rdi, 1
                mov rsi, buffer
                mov rdx, 1
                syscall
                pop rbp
                ret
        .nonZero:
                test rdi, rdi
                jns .positive
                neg rdi
                mov byte [buffer], '-'
                mov rax, 1
                push rdi
                mov rdi, 1
                mov rsi, buffer
                mov rdx, 1
                syscall
                pop rdi
        .positive:
                lea rsi, [buffer + 31]
                mov byte [rsi], 0
                dec rsi
                mov rax, rdi
                mov rbx, 10
        .convertLoop:
                xor rdx, rdx
                div rbx
                add dl, '0'
                mov [rsi], dl
                dec rsi
                test rax, rax
                jnz .convertLoop
                inc rsi
                mov rcx, rsi
                lea rdx, [buffer + 31]
                sub rdx, rsi
                mov rax, 1
                mov rdi, 1
                mov rsi, rcx
                syscall
                pop rbp
                ret

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
                sub rsp, 16
                movzx rax, byte [rsi]
                movzx rbx, byte [rcx]
                cmp rax, rbx
                jbe .proceed
                push rdi
                push rsi
                mov rdi, rdx
                mov rsi, rcx
                pop rdx
                pop rcx
                call findMedianOfTwoArrays
                add rsp, 16
                pop rbp
                ret  
        .proceed:
                xor r8, r8
                movzx r9, byte [rsi]
        .loop:
                cmp r8, r9
                jg .done
                mov rax, r8
                add rax, r9
                shr rax, 1
                mov [rsp], rax
                movzx rbx, byte [rsi]
                movzx r14, byte [rcx]
                add rbx, r14
                inc rbx
                shr rbx, 1
                sub rbx, rax
                mov [rsp + 8], rbx
        .getALeft:
                test rax, rax
                jz .setALeftMin
                movzx r10, byte [rdi + rax - 1]
                jmp .getARight
        .setALeftMin:
                mov r10, 0
        .getARight:
                movzx r14, byte [rsi]
                cmp rax, r14
                jae .setARightMax
                movzx r11, byte [rdi + rax]
                jmp .getBLeft
        .setARightMax:
                mov r11, 255
        .getBLeft:
                mov rbx, [rsp + 8] 
                test rbx, rbx
                jz .setBLeftMin
                movzx r12, byte [rdx + rbx - 1]
                jmp .getBRight
        .setBLeftMin:
                mov r12, 0
        .getBRight:
                movzx r14, byte [rcx]
                cmp rbx, r14
                jae .setBRightMax
                movzx r13, byte [rdx + rbx]
                jmp .checkPartition
        .setBRightMax:
                mov r13, 255
        .checkPartition:
                cmp r10, r13
                jg .adjustHigh
                cmp r12, r11
                jg .adjustLow
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
        .adjustLow:
                mov r8, [rsp]
                inc r8
                jmp .loop
        .adjustHigh:
                mov r9, [rsp]
                dec r9
                jmp .loop
        .done:
                add rsp, 16
                pop rbp
                ret

        ; rsp:argc, rsp+8:argv
        _start:
                ; Check that argc is 3
                mov rsi, [rsp]
                cmp rsi, 3
                mov rdi, 1
                jne exit
                ; Get argv[1] and parse the argument into list1
                lea rdx, [rsp+8]
                mov rdi, [rdx+8]
                lea rsi, [list1]
                lea rdx, [list1Size]
                call parseStringIntoList
                ; Get argv[2] and parse the argument into list2
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
                movq rax, xmm0
                call printFloat
                mov rdi, 0
                jmp exit

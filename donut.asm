segment .data
    theta_spacing:  dd 0.07
    phi_spacing:    dd 0.02
    r1:             dd 1
    r2:             dd 2
    k_1:            dd 50
    k_2:            dd 5
    screen_width:   dd 80
    screen_height:  dd 22
    frmt_print      db "%f",10,0
    frmtd           db "%d", 10, 0
    frmt_nl         db 10, 0
    frmt_char       db "%c", 0
    tesr            dd 0.5
    pi:             dd 3.1415926
    twopi:          dd 6.2831853
    chars           db ".,-~:;=!*#$@",0
    frmt            db 0x1b, "[H",0
    zero:           dd 0
    one:            dd 1
    two:            dd 2
    eight:          dd 8
    hello           db "hello world", 0

segment .bss
    A:      resd 1
    B:      resd 1
    cosA:   resd 1
    cosB:   resd 1
    sinA:   resd 1
    sinB:   resd 1
    zbuf:   resd 1760
    output  resb 1760
    phi:    resd 1
    theta:  resd 1
    costheta:  resd 1
    sintheta:  resd 1
    cosphi:    resd 1
    sinphi:   resd 1
    circlex:   resd 1
    circley:   resd 1
    x:         resd 1
    y:         resd 1
    z:         resd 1
    ooz:       resd 1
    xp        resd 1
    yp          resd 1
    L:         resd 1
    tmp1:      resd 1
    tmp2:      resd 1
    tmp3:      resd 1
    tmp4       resd 1

segment .text
    global  main
    extern  printf
    extern putchar

main:
    push    rbp
    mov     rbp, rsp

    sub     rsp, 16
    mov     QWORD[rbp-8], 0
    mov     QWORD[rbp-16], 0

    mov     DWORD[A], 0
    mov     DWORD[B], 0
    call    render_frame

    mov     rdi, frmtd
    mov     rsi, r10
    call    printf

    top_print:
    cmp     QWORD[rbp-8], 22
    jge     end_print
        inner:
        cmp     QWORD[rbp-16], 80
        jge     bot_print
            xor     rax, rax
            xor     rbx, rbx
            mov     eax, DWORD[rbp-8]
            cdq
            mul     DWORD[screen_width]
            add     eax, DWORD[rbp-16]
            mov     bl, BYTE[output+rax]
            
            ;mov     rdi, frmt_char
            ;mov     rsi, rbx
            ;call    printf
            mov     rdi, rbx
            call    putchar
        inc     QWORD[rbp-16]
        jmp     inner
        bot_print:
    mov     rdi, frmt_nl
    call    printf
    inc     QWORD[rbp-8]
    jmp     top_print
    end_print:


    mov     rax, 0
    mov     rsp, rbp
    pop     rbp
    ret

render_frame:
    push    rbp
    mov     rbp, rsp

    fld     DWORD[A]
    fsin
    fstp    DWORD[sinA]

    fld     DWORD[A]
    fcos
    fstp    DWORD[cosA]

    fld     DWORD[B]
    fsin
    fstp    DWORD[sinB]

    fld     DWORD[B]
    fcos
    fstp    DWORD[cosB]

    xor     rcx, rcx
    top_fill:
    cmp     rcx, 1760
    jge     end_fill
        mov     BYTE[output+rcx], " "
        mov     DWORD[zbuf+4*rcx], 0
    inc     rcx
    jmp     top_fill
    end_fill:

    mov     r10, 0
    mov     DWORD[theta], 0
    top_calc:
    pxor     xmm0, xmm0
    pxor     xmm1, xmm1
    cvtss2sd xmm0, DWORD[theta]
    cvtss2sd xmm1, DWORD[twopi]
    comiss   xmm0, xmm1
    ja       end_calc

    ;fld     DWORD[theta]
    ;fcomp   DWORD[twopi]
    ;ja     end_calc
    ;fnstsw  ax
    ;test    ah, 0x41
    ;jz     end_calc
    ;jge     end_calc
        fld     DWORD[theta]
        fcos    
        fstp    DWORD[costheta]
        fld     DWORD[theta]
        fsin    
        fstp    DWORD[sintheta]

    mov     DWORD[phi], 0
    inner_calc:
    pxor     xmm0, xmm0
    pxor     xmm1, xmm1
    cvtss2sd xmm0, DWORD[phi]
    cvtss2sd xmm1, DWORD[twopi]
    comiss   xmm0, xmm1
    ja      bot_calc
    ;fld     DWORD[twopi]
    ;fld     DWORD[phi]
    ;fcomp   DWORD[twopi]
    ;ja      bot_calc
    ;fcomi
    ;fstp    DWORD[tmp1]
    ;fstp    DWORD[tmp1]
    ;jle     bot_calc
        ; cos(phi), sin(phi)
        fld     DWORD[phi]
        fcos    
        fstp    DWORD[cosphi]
        fld     DWORD[phi]
        fsin    
        fstp    DWORD[sinphi]

        ; circlex = R2 + R1*costheta 
        fld     DWORD[costheta]
        fmul    DWORD[r1]
        fadd    DWORD[r2]
        fstp    DWORD[circlex]

        ; circley = R1 * sintheta
        fld     DWORD[sintheta]
        fadd    DWORD[r1]
        fstp    DWORD[circley]

        ; x = circlex*(cosB*cosphi + sinA*sinB*sinphi) - circley*cosA*cosB
        fld     DWORD[circley]
        fmul    DWORD[cosA]
        fmul    DWORD[cosB]
        fstp    DWORD[tmp2]
        fld     DWORD[cosB]
        fmul    DWORD[cosphi]
        fstp    DWORD[tmp1]
        fld     DWORD[sinA]
        fmul    DWORD[sinB]
        fmul    DWORD[sinphi]
        fadd    DWORD[tmp1]
        fmul    DWORD[circlex]
        fsub    DWORD[tmp2]
        fstp    DWORD[x]

        ; y = circlex*(sinB*cosphi - sinA*cosB*sinphi) - cirley*cosA*cosB
        fld     DWORD[circley]
        fmul    DWORD[cosA]
        fmul    DWORD[cosB]
        fstp    DWORD[tmp2]
        fld     DWORD[sinA]
        fmul    DWORD[cosB]
        fmul    DWORD[sinphi]
        fstp    DWORD[tmp1]
        fld     DWORD[sinB]
        fmul    DWORD[cosphi]
        fsub    DWORD[tmp1]
        fmul    DWORD[circlex]
        fsub    DWORD[tmp2]
        fstp    DWORD[y]

        ; z = K2 + cosA*circlex*sinphi + circley*sinA
        fld     DWORD[circley]
        fmul    DWORD[sinA]
        fstp    DWORD[tmp1]
        fld     DWORD[cosA]
        fmul    DWORD[circlex]
        fmul    DWORD[sinphi]
        fadd    DWORD[k_2]
        fadd    DWORD[tmp1]
        fstp    DWORD[z]

        ; ooz = 1/z
        fld     DWORD[one]
        fdiv    DWORD[z]
        fstp    DWORD[ooz]

        ; xp = (int)(screen_width/2 + K1*ooz*x)
        fld     DWORD[screen_width]
        fdiv    DWORD[two]
        fstp    DWORD[tmp1]
        fld     DWORD[k_1]
        fmul    DWORD[ooz]
        fmul    DWORD[x]
        fadd    DWORD[tmp1]
        fistp   DWORD[xp]

        ; yp = (int)(screen_height/2 - K1*ooz*y)
        fld     DWORD[k_1]
        fmul    DWORD[ooz]
        fmul    DWORD[y]
        fstp    DWORD[tmp1]
        fld     DWORD[screen_height]
        fdiv    DWORD[two]
        fsub    DWORD[tmp1]
        fistp   DWORD[yp]

        ;L = cosphi*costheta*sinB - cosA*costheta*sinphi - sinA*sintheta + cosB*(cosA*sintheta - costheta*sinA*sinphi)
        fld     DWORD[costheta] 
        fmul    DWORD[sinA]
        fmul    DWORD[sinphi]
        fstp    DWORD[tmp1]
        fld     DWORD[cosA]
        fmul    DWORD[sintheta]
        fsub    DWORD[tmp1]
        fmul    DWORD[cosB]
        fstp    DWORD[tmp1]
        fld     DWORD[sinA]
        fmul    DWORD[sintheta]
        fstp    DWORD[tmp2]
        fld     DWORD[cosA]
        fmul    DWORD[costheta]
        fmul    DWORD[sinphi]
        fstp    DWORD[tmp3]
        fld     DWORD[cosphi]
        fmul    DWORD[costheta]
        fmul    DWORD[sinB]
        fsub    DWORD[tmp3]
        fsub    DWORD[tmp2]
        fadd    DWORD[tmp1]
        fstp    DWORD[L]

        ;fld     DWORD[L]
        ;fld     DWORD[zero]
        ;fcomi
        ;fstp    DWORD[tmp1]
        ;fstp    DWORD[tmp1]
        ;jle     endif
        pxor     xmm0, xmm0
        pxor     xmm1, xmm1
        cvtss2sd xmm0, DWORD[L]
        cvtss2sd xmm1, DWORD[zero]
        comiss   xmm0, xmm1
        jb       endif
            xor     rax, rax
            cqo
            mov     eax, DWORD[yp]
            mov     rbx, 80
            mul     rbx
            add     eax, DWORD[xp] 

            pxor     xmm0, xmm0
            pxor     xmm1, xmm1
            cvtss2sd xmm0, DWORD[ooz]
            cvtss2sd xmm1, DWORD[zbuf+4*rax]
            comiss   xmm0, xmm1
            jb       endif
                xor     rbx, rbx
                fld     DWORD[ooz]
                fstp    DWORD[zbuf+4*rax]
                fld     DWORD[L]
                fmul    DWORD[eight]
                fistp   DWORD[tmp4]
                mov     ebx, DWORD[tmp4]
                mov     dl, BYTE[chars+rbx]
                mov     BYTE[output+rax], dl
    endif:
    fld     DWORD[phi]
    fadd    DWORD[phi_spacing]
    fstp    DWORD[phi]

    ;pxor     xmm0, xmm0
    ;cvtss2sd xmm0, DWORD[theta]
    ;mov      rdi, frmt_print
    ;mov      al, 1
    ;call     printf 

    jmp     inner_calc

    bot_calc:
    fld     DWORD[theta]
    fadd    DWORD[theta_spacing]
    fstp    DWORD[theta]
    inc     r10

    ;pxor     xmm0, xmm0
    ;cvtss2sd xmm0, DWORD[twopi]
    ;mov      rdi, frmt_print
    ;mov      al, 1
    ;call     printf 

    jmp     top_calc
    end_calc:

    mov     rsp, rbp
    pop     rbp
    ret

; vim:ft=nasm

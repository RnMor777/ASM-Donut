segment .data
    theta_spacing: dd 0.07
    phi_spacing: dd 0.02
    r1: dd 1
    r2: dd 2
    k_1: dd 3
    k_2: dd 5
    screen_width: dd 50

segment .bss
    A: resd 1
    B: resd 1

segment .text
    global  main

main:
    push    rbp
    mov     rbp, rsp


    mov     rax, 0
    mov     rsp, rbp
    pop     rbp
    ret

render_frame:
    push    rbp
    mov     rbp, rsp

    movss xmm0, [A]

    mov     rsp, rbp
    pop     rbp
    ret

; vim:ft=nasm

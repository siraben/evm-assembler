;; Prime numbers.
(subroutine ,)
(subroutine inc-n)
(subroutine prime?)
(subroutine square)

(write-ptr equ 1000)
(n equ 1032)
(mem-start equ 64)

;; Initialize
mem-start write-ptr !
1 n !


(label write-loop)
inc-n
n @ 3000 >

(jumpi write-done)

n @ prime? 0=
(jumpi write-loop)
n @ ,

(jump write-loop)

(label write-done)
860 64 return
stop

(label inc-n) n @ 1 + n ! ret

;; Write a 16-bit value ( n -- )
(label ,)
write-ptr @ d!
2 write-ptr +!
ret

(label square) dup * ret

(label prime?) ;; ( n -- b )
2 ;; primality tester (k)
over 2 = (jumpi prime-succ) ;; n == 2
(label prime-loop)
2dup square < (jumpi prime-succ)    ;; if k^2 > n, n is prime.
2dup modulo 0= (jumpi prime-fail)   ;; if k (mod n) == 0, n is not prime
1 +                                 ;; k <- k + 1
(jump prime-loop)

(label prime-succ) 2drop 1 ret
(label prime-fail) 2drop 0 ret

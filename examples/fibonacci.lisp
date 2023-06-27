;; Calculate fibonacci of 7 on the EVM!
;; Main
7 (call fib)
stop

;; Subroutine
(label fib)
dup 2 <
(jumpi fib-base)
dup 1 -
(call fib)
swap
2 -
(call fib)
+
ret
(label fib-base)
ret

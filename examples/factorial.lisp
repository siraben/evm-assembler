;; Calculate factorial of 16.
(subroutine factorial)

16 factorial
stop


(label factorial) ;; ( n -- n! )
dup 0= fact-base jumpi
dup 1 -
factorial
*
ret
(label fact-base)
drop 1
ret

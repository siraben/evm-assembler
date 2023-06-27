;; Fibonacci memoized
(mem-start equ 0)

(write-ptr equ 300)       ;; Locations of variables
(n equ 332)

;; Compute the 24th fibonacci number (just before overflowing 16 bits)
24 n !


mem-start 2 + write-ptr ! ;; fib 0 = 0, so start writing at 1

1 write-ptr @ d!          ;; fib 1 = 1

2 write-ptr +!

(label fib-loop)

1 n -!                    ;; Decrement n

write-ptr @ 2 - d@        ;; Compute the next fib from the previous
write-ptr @ 4 - d@        ;; two entries
+

write-ptr @ d!            ;; Store it
2 write-ptr +!            ;; Increment the write pointer


n @ 1 > (jumpi fib-loop)  ;; Jump if n > 1


write-ptr @ 2 - d@        ;; Read the fibonacci number
stop

;; Calculate factorial of 16 iteratively

16

1 swap ;; 1 n

(label loop)
dup 1 - ;; acc n n-1
2 gt (jumpi end)
;; acc n, n > 1
swap over * swap 1 -
(jump loop)

(label end)
drop
stop

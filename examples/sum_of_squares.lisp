;; Sum of squares
3 4 (call sum-of-squares)
stop

(label square)
dup *
ret

(label sum-of-squares)
(call square)
swap
(call square)
+
ret

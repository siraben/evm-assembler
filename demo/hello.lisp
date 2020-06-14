;; hello world on the EVM

32 48 c!            ;; init pointer at address 48 to 32
104 (call write-byte!)
101 (call write-byte!)
108 (call write-byte!)
108 (call write-byte!)
111 (call write-byte!)
44 (call write-byte!)
32 (call write-byte!)
119 (call write-byte!)
111 (call write-byte!)
114 (call write-byte!)
108 (call write-byte!)
100 (call write-byte!)
33 (call write-byte!)

stop

(label write-byte!) ;; ( c -- )

48 c@ c!            ;; write to pointer

48 c@ 1 + 48 c!     ;; increment pointer
ret

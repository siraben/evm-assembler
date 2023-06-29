;; Program to do a quadratic number of operations on the stack.

1020 0

(label main)
over
(label push-n)
dup 0= (jumpi end)
dup 1 - (jump push-n)

(label end)
drop
(label clear)
dup 0= (jumpi end2)
drop
(jump clear)

(label end2)
over 0= (jumpi finish)
swap 1 - swap
(jump main)

(label finish)
stop


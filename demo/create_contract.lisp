;; PUSH1 17 DUP1 PUSH1 12 PUSH1 0 CODECOPY PUSH1 0 RETURN STOP PUSH1 0
;; CALLDATALOAD SLOAD NOT PUSH1 9 JUMPI STOP JUMPDEST PUSH1 32
;; CALLDATALOAD PUSH1 0 CALLDATALOAD SSTORE
19
dup
12
0
codecopy
push1
0
return
stop
0
calldataload
sload
not
(jumpi foo)
stop
(label foo)
32
calldataload
0
calldataload
sstore


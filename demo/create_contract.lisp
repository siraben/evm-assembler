;; PUSH1 17 DUP1 PUSH1 12 PUSH1 0 CODECOPY PUSH1 0 RETURN STOP PUSH1 0
;; CALLDATALOAD SLOAD NOT PUSH1 9 JUMPI STOP JUMPDEST PUSH1 32
;; CALLDATALOAD PUSH1 0 CALLDATALOAD SSTORE
19
dup
contract-start
1 + ;; HACK: adjust the address
0
codecopy
0
return
stop
;; Contract starts
(label contract-start)
(org 0)
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


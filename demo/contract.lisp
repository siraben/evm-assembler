;; PUSH1 0 CALLDATALOAD SLOAD NOT PUSH1 10 JUMPI STOP JUMPDEST PUSH1 32 CALLDATALOAD PUSH1 0 CALLDATALOAD SSTORE
0 calldataload
sload not
(jumpi foo)
stop
(label foo)
32
calldataload
0
calldataload

sstore
stop

;; Eaxmple contract from
;; https://github.com/ethereum/wiki/wiki/Ethereum-Development-Tutorial

;; PUSH1 0 CALLDATALOAD SLOAD NOT PUSH1 10 JUMPI STOP JUMPDEST PUSH1
;; 32 CALLDATALOAD PUSH1 0 CALLDATALOAD SSTORE
0 calldataload
sload
;; If key not found in store
not
(jumpi write_store)
;; Already in store, push 10 to indicate so.
;; 10
stop
(label write_store)
;; Get the value, key
32 calldataload
0 calldataload
;; Store it
sstore
stop

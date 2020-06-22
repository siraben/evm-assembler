;; Example contract from
;; https://github.com/ethereum/wiki/wiki/Ethereum-Development-Tutorial

;; PUSH1 0 CALLDATALOAD SLOAD NOT PUSH1 10 JUMPI STOP JUMPDEST PUSH1
;; 32 CALLDATALOAD PUSH1 0 CALLDATALOAD SSTORE
0 calldataload
sload
;; If the key is not in storage, jump to write it.
not (jumpi write_storage)
;; Already in storage, stop.
stop
(label write_storage)
;; Get the value, key.
32 calldataload
0 calldataload
;; Store it.
sstore
stop

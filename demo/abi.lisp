100
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
0 calldataload
28 8 * rshift
;; 0xcdcd77c0
3452794816 = (jumpi baz)
stop
(label baz)
4 calldataload  ;; Load x : u32
0 sstore
36 calldataload ;; Load y : bool
1 sstore
stop

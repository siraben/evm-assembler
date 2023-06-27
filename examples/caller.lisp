;;

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
;; 0xfc149efd, first four bytes of keccak(address, uint256)
3452794816 = (jumpi baz)
stop
(label baz)
4 calldataload  ;; Load x : u32
dup 0 !
0 sstore
36 calldataload ;; Load y : bool
dup 32 !
1 sstore
;; 3452794816 32 32 log1
63 32 return ;; Return the bool param back

;; stop

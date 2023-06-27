;; Virtual machine that runs SKI combinators

(subroutine $)
(subroutine arg)
(subroutine num)
(subroutine lazy)
(subroutine $arg)
(subroutine run)
(subroutine init)
(subroutine sp!)
(subroutine sp@)
(subroutine hp!)
(subroutine hp@)
(subroutine mem!)
(subroutine mem@)
(subroutine alloc)
(subroutine advance-free)
(subroutine ,)
(subroutine cell-)
(subroutine stack-push)
(subroutine isaddr)
(subroutine tick)
(subroutine count@)
(subroutine exhausted)

;; Memory base address 8192 + 128, since addresses are > 127.
(mem equ 8192)

;; Heap pointer
(hp equ 4096)

;; Stack pointer
(sp equ 4098)

;; Result register
(result equ 4100)

;; Reduction counter
(count equ 65535)

;; Combinators
;; When possible, use ASCII equivalents, so we can see in the memory
;; dump.
(# equ 35)
(** equ 42)
(++ equ 43)
(-- equ 45)
(. equ 46)
(== equ 61)
(I equ 73)
(K equ 75)
(S equ 83)
(Y equ 89)
(B equ 66)
(C equ 67)
(R equ 82)
(T equ 84)
(DONE equ 99)
(RET equ 10)


;; For testing, limit the number of reductions.
(limit equ 2000)

init
;; Examples
;; --------
;; S K K I DONE =  S K $ K $ K $ I $ DONE $
;; Reduction:
;;    S K K I DONE
;; => (K K) (K K) I DONE
;; => K I DONE
;; => I
;; Since I is a bare combinator, we should expect the final stack to
;; be [0,404].

;; On the other hand, this evaluates differently, to the "success" combinator.
;; S K K DONE I =  S K $ K $ K $ DONE $ I $
;; Reduction:
;;    S K K DONE I
;; => (K K) (K K) DONE I
;; => K K DONE I
;; => K DONE I
;; => DONE
;; DONE is a combinator that pushes 123456 onto the stack, yay!

;; We have Turing completeness, since SKI is Turing complete.
;; Try evaluating (SII)(SII), it won't terminate! Here it is.
;; S I $ I $
;; S I $ I $ $

;; Evaluate (SII)((SII)(SII)) to see exhaustion.  Here's the assembly.
;; S I $ I $
;; S I $ I $
;; S I $ I $ $

;; S K $ K $ K $ DONE $ I $

;; K # 42 $ $
;; 0 num
;; stop

;; (+)(#3)(#6)
;; ++ # 3 $ $ # 6 $ $ RET $
;;    (+)(#3)(#2) RET
;; => (# 9) RET
;; => [$ done, stack is [9]

;; S K S I $ $ $ K $ RET $ # 10 $ $
;;   S(K(SI))K RET (#10)
;; => ...
;; => (#10) RET
;; => [] done, stack is [10]

;; if (1 == 2) then 222 else 111
;; can be written as NOTE: the order is flipped due to Scott encoding
;; of booleans
;; == # 1 $ $ # 2 $ $ # 111 $ $ # 222 $ $ RET $
;; ==   # 1 $
;; $ # 2 $
;; $ # 111 $
;; $ # 222 $
;; $ RET $

;; Successful compilation of
;; (add (int 1) (mul (int 3) (int 5)))
;; # 5 $ # 3 $ ** $ $ # 1 $ ++ $ $ RET $

;; (if_ (bool False) (int 111) (int 222))
;; (add (int 3) (if_ (bool False) (int 100) (int 200)))
;; K I $ # 100 $ $ # 200 $ $ # 3 $ ++ $ $ RET $

;; B T $ T $ ++ $ # 1 $ $ # 2 $ $ RET $
;; ++ # 3 $ $ # 5 $ $ RET $
;; # 10 $ ++ $ # 20 $ $ RET $
;; B T $ T ++ $ $ # 150 $ $ # 3 $ $
;; B T $ T ++ $ $ # 3 $ $ # 5 $ $ RET $
# 5 $ # 3 $ ++ $ $ RET $
stack-push
run

;; 2 10 1 arg lazy
stop

;; ( n -- b )
(label isaddr) 127 > exit

(label exhausted)
9999999 stop
;; ( -- )
(label run)
;; Stop if we've exceeded limit.
count@ limit > (jumpi exhausted)
tick
;; x = (sp)
sp d@ d@
dup
isaddr
;; If it's an address, deref it and try again.
(jumpi deref)
;; We have a combinator
;; K?
dup Y = (jumpi runY)
dup S = (jumpi runS)
dup K = (jumpi runK)
dup I = (jumpi runI)
dup B = (jumpi runB)
dup C = (jumpi runC)
dup R = (jumpi runR)
dup T = (jumpi runT)

dup ++ = (jumpi run++)
dup ** = (jumpi run**)
dup -- = (jumpi run--)
dup == = (jumpi run==)
dup # = (jumpi run#)
dup . = (jumpi run.)
dup RET = (jumpi runRET) ;; (#3) RET => terminates with [3] on stack
dup DONE = (jumpi runDONE)
;; 404 combinator not found
404
exit

(label runB) pop
3 1 arg 2 3 $arg lazy
(jumpi run)

(label runC) pop
3 1 3 $arg 2 arg lazy
(jumpi run)

(label runR) pop
3 2 3 $arg 1 arg lazy
(jumpi run)

(label runT) pop
2 2 arg 1 arg lazy
(jumpi run)

(label runY) pop
1 1 arg 1 sp@ lazy
(jumpi run)

(label run==) pop
1 num 2 num =
(jumpi ==T)

;; False branch
2 I K lazy
(jump run)

;; True branch
(label ==T)
2 K I lazy
(jump run)

(label run--) pop
2 # 1 num 2 num - lazy
(jump run)

(label run**) pop
2 # 1 num 2 num * lazy
(jump run)

(label run++) pop
2 # 1 num 2 num + lazy
(jump run)

(label runS) pop
3 1 3 $arg 2 3 $arg lazy
(jump run)

;; https://www.cs.york.ac.uk/fp/reduceron/jfp-reduceron.pdf
;; Source: https://crypto.stanford.edu/~blynn/compiler/ION.html We
;; introduce a combinator called # and reduce, say, # 42 f to f(# 42)
;; for any f. For example, the term ((I#2)(K(#3)S))(+) reduces to
;; (+)(#3)(#2).

(label run#) pop
2 2 arg 1 sp@ lazy
(jump run)


;; RET should be called by a number, e.g.
;; # 100 $ RET $
;; Terminate the machine, the stack will contain
;; <number of times run was called> <1 num>
(label runRET) pop
count@ 1 num stop

;; Dummy success combinator, for now.
(label runDONE) pop 123456 stop
(label run.)
drop
result d@
stop

(label runK) pop
2 I 1 arg lazy
(jump run)

(label runI) pop
1 arg 1 sp!
sp d@ cell+ sp d!
(jump run)

;; Deref the node, pushing the result onto the stack.
(label deref) mem@ stack-push (jump run)

;; Increment the counter
(label tick) count @ 1 + count ! exit
;; Fetch the counter
(label count@) count @ exit

;; ( -- )
(label init)
;; sp := 8190
8190 sp d!
;; hp := mem+128
mem 128 cells + hp d!
;; count := 0
0 count !
exit

;; ( i j -- )
;; $arg(i,j) = $(arg(i), arg(j))
(label $arg) swap arg swap arg $ exit

;; ( n -- )
(label arg)
;; arg(n) = mem[sp[n] + 1]
sp@ 1 + mem@
exit


;; ( uint16 -- )
(label stack-push)
sp d@ cell- sp d!
sp d@ d!
exit

;; (f x -- )
(label $)
swap
;; mem[hp] := f
,
;; mem[hp + 1] := x
,
;; hp := hp + 2  (done by ,)
hp@ mem - 1 shr
2 -
;; return (hp - 2) (but as an offset from mem)
exit

(label num)
;; num(n) = mem[arg(n) + 1]
arg 1 + mem@
exit

;; ( height f x -- )
(label lazy)
rot dup
;; f x h h
sp@ cells mem +
;; f x h (p = mem + sp[h])
dup
;; f x h p p
dup4
;; f x h p p x
swap
;; f x h p x p
d!
;; f x h p
cell+
;; f x h p+1
rot
;; f h p+1 x
swap
;; f h x p+1
d!
;; f h
cells
sp d@ + cell-
;; f sp+h-1
;; sp := sp+h-1
sp d!
;; f
;; (sp) := f
sp d@ d!
;; --
exit

(label hp!) hp d! exit
(label hp@) hp d@ exit

;; ( uint16 n -- ) Stores uint16 at sp[n].
(label sp!) 2 * sp d@ + d! exit
;; ( n -- uint16 ) Gets value at sp[n].
(label sp@) 2 * sp d@ + d@ exit

;; Set and get values at memory locations
;; ( uint16 n -- ) Stores uint16 at mem[n].
(label mem!) 2 * mem + d! exit

;; ( n -- uint16 ) Gets value at mem[n].
(label mem@) 2 * mem + d@ exit

;; ( uint16 -- ) Store a given uint16.
(label ,) alloc d! exit


;; ( -- ) Advance the heap pointer.
(label advance-free) 
hp d@ cell+
hp d!
exit

;; ( -- addr ) Return the address of the next free uint16.
(label alloc) hp d@ advance-free exit

(label cell-) 2 - exit

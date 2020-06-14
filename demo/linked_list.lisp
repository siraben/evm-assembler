(subroutine advance-free)
(subroutine alloc)
(subroutine alloc-node)
(subroutine ,)
(subroutine .next)
(subroutine .value)
(subroutine insert)
(subroutine read-list)
(subroutine find)
(subroutine a!)
(subroutine a@)
(subroutine b!)
(subroutine b@)

;; Pointer to the next free address space.
(next-free equ 4096)

;; Pointer to the front of our linked list.
(head      equ 4098)
(a      equ 4100)
(b      equ 4102)

32 next-free d!
5 insert
4 insert
2 insert
1 insert

;; head d@ 5 read-list
6 head d@ find dup .value
stop

;; ( list* uint16 -- ) Read n elements from a list
(label read-list)
dup 0= (jumpi read-list-done)
1 - over .value -rot
swap .next swap
(jump read-list)

(label read-list-done)
2drop
exit

;; ( uint16 -- ) Store a given uint16.
(label ,) alloc d! exit

;; ( -- ) Advance the free pointer.
(label advance-free) 
next-free d@ cell+
next-free d!
exit

;; ( -- addr ) Return the address of the next free uint16.
(label alloc) next-free d@ advance-free exit

;; ( prev uint16 -- node* ) Allocate a new node.
;; Node structure: [link][value]
(label alloc-node) , , exit

;; ( node* -- node* ) Get the next node.
(label .next) d@ exit

;; ( node* -- uint16 ) Extract the value.
(label .value) cell+ d@ exit

;; ( val -- ) Insert to the head of the list.
(label insert) 
next-free d@ swap ;; Save the address of the new link.
head d@ ,        ;; Write the link.
,                ;; Write the value.
head d!          ;; Update head.
exit

(label find)
a! b!
a@ .next 0= (jumpi find-end)

(label find-loop)
a@ .next 0= (jumpi find-end)
b@ a@ .next .value > 0= (jumpi find-end)
a@ .next a!
(jump find-loop)

(label find-end)
a@ exit

(label a!) a d! exit
(label a@) a d@ exit
(label b!) b d! exit
(label b@) b d@ exit

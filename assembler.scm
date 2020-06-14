#!/usr/bin/env -S guile --no-auto-compile -e main
!#

(use-modules (ice-9 match) (rnrs io ports) (rnrs bytevectors) (srfi srfi-9))

;; set! this to #t to see debugging information.  Note that `lookup`
;; will complain a lot but generally it's fine.
(define verbose? #f)

(define (lookup key alist)
  (let ((match (assoc key alist)))
    (if match
        (cdr match)
        (begin
          ;; Verbose
          (if verbose? (format #t "Failed to lookup: ~a\n" key))
          #f))))

(define-record-type <inst>
  (make-inst-rec length generator)
  inst?
  (length inst-length)
  (generator inst-generator))

(define-syntax make-inst
  (syntax-rules ()
    ((_ length generator)
     (make-inst-rec length (delay generator)))))

(define (gen-inst inst)
  (force (inst-generator inst)))

(define (unsigned-nat? x) (and (integer? x) (>= x 0)))
(define (num->binary n) (format #f "~8,'0b" n))
(define (num->hex n) (format #f "~2,'0x" n))

(define (256-bit-imm? x)
  (and (unsigned-nat? x)
       (> (ash 1 256) x)))

(define (256-bit-imm-or-label? x)
  (or (256-bit-imm? x) (symbol? x)))

;; Least significant byte.
(define (lsb n) (logand n 255))

;; Most significant bytes.
(define (msb n) (ash n -8))

(define (resolve-label label-or-imm256)
  (if (256-bit-imm? label-or-imm256)
      label-or-imm256
      (or (lookup label-or-imm256 *labels*)
          (error (format #f "Label not found: ~a" label-or-imm256)))))

(define (simple-op? op) (lookup op simple-ops))

;; Operations that don't receive arguments or have specific ones.
(define simple-ops
  '((stop          #x00)
    (add           #x01) (+             #x01)
    (mul           #x02) (*             #x02)
    (sub           #x03) (-             #x03)
    (div           #x04) (/             #x04)
    (sdiv          #x05) (s/            #x05)
    (mod           #x06)
    (smod          #x07)
    (addmod        #x08) (+mod          #x08)
    (mulmod        #x09) (*mod          #x09)
    (exp           #x0a)
    (signextend    #x0b)
    (lt            #x10) (<             #x10)
    (gt            #x11) (>             #x11)
    (slt           #x12) (s<            #x12)
    (sgt           #x13) (s>            #x13)
    (eq            #x14) (=             #x14)
    (iszero        #x15) (0=            #x15)
    (and           #x16)
    (or            #x17)
    (xor           #x18)
    (not           #x19)
    (byte          #x1a)
    (sha3          #x20) (keccak256     #x20)
    (address       #x30)
    (balance       #x31)
    (origin        #x32)
    (caller        #x33)
    (callvalue     #x34)
    (calldataload  #x35)
    (calldatasize  #x36)
    (calldatacopy  #x37)
    (codesize      #x38)
    (codecopy      #x39)
    (gasprice      #x3a)
    (extcodesize   #x3b)
    (extcodecopy   #x3c)
    (blockhash     #x40)
    (coinbase      #x41)
    (timestamp     #x42)
    (number        #x43)
    (difficulty    #x44)
    (gaslimit      #x45)
    (pop           #x50)
    (mload         #x51) (@             #x51)
    (mstore        #x52) (!             #x52)
    (mstore8       #x53)
    (sload         #x54) (s@            #x54)
    (sstore        #x55) (s!            #x55)
    (jump          #x56)
    (jumpi         #x57)
    (pc            #x58)
    (msize         #x59)
    (gas           #x5a)
    (jumpdest      #x5b)
    (log0          #xa0)
    (log1          #xa1)
    (log2          #xa2)
    (log3          #xa3)
    (log4          #xa4)
    (create        #xf0)
    (call          #xf1)
    (callcode      #xf2)
    (return        #xf3)
    (delegatecall  #xf4)
    (revert        #xfd)
    (invalid       #xfe)
    (selfdestruct  #xff)))

(define (assemble-simple a)
  (let ((res (lookup a simple-ops)))
    (if res
        (make-inst (length res) res)
        (error (format #f "Operation not found: ~a" a)))))

(define (add-label! name val)
  (if (assv name *labels*)
      (error (format #f "Cannot add another label of ~a" name))
      (begin
        (if verbose?
            (format #t "Adding label ~a with value #x~4,'#x\n" name val))
        (set! *labels* `((,name . ,val) . ,*labels*)))))

(define (advance-pc! count) (set! *pc* (+ *pc* count)))

(define (assemble-label name)
  (add-label! name *pc*)
  (make-inst 1 '(#x5b)))

(define (assemble-org new-pc)
  (set! *pc* new-pc)
  '())

(define (signed-8-bit-imm? x)
  (and (integer? x) (>= 127 (abs x))))

(define (8-bit-imm? x)
  (and (unsigned-nat? x)
       (> (ash 1 8) x)))

(define (big-endian-rep n)
  (let loop ((c 32)
             (res `(,(lsb n)))
             (n (msb n)))
    (if (or (zero? n) (zero? c))
        res
        (loop (1- c)
              (cons (lsb n) res)
              (msb n)))))

(define (assemble-dw word-list)
  (make-inst (length word-list)
             (flatten (map
                       (lambda (x)
                         (let ((x (if (symbol? x) (resolve-label x) x)))
                           (if (256-bit-imm? x)
                               (list x)
                               (error (format #f "Invalid word in dw: ~a" x)))))
                       word-list))))

(define (assemble-db byte-list)
  (make-inst (length byte-list)
             (if (all-sat? 8-bit-imm? byte-list)
                 byte-list
                 (error (format #f "Invalid byte in db: ~a" byte-list)))))


;; Assemble an instruction that has variations (push, dup, swap)
(define (assemble-var-op name base offset arg)
  (match arg
    ('()
     (make-inst 1 `(,(+ base offset))))
    ((? 256-bit-imm-or-label? a)
     (make-inst 2 `(,(+ base offset) ,(resolve-label arg))))
    (_ (error (format #f "Invalid operand to ~a: ~a" name arg)))))

(define (assemble-push arg)
  (match arg
    ;; We know the size of the argument in advance, so emit the PUSH
    ;; instruction that fits.
    ((? 256-bit-imm? a)
     (make-inst (1+ (sizeof arg)) `(,(+ #x5f (sizeof arg)) ,@(big-endian-rep a))))
    ((? symbol? s)
     ;; Assume that we will never push a label at position > 65535, so always emit a PUSH2
     (make-inst 3 `(,(+ #x5f 2) ,@(let ((push-arg (big-endian-rep (resolve-label s))))
                                    ;; If the label is at position <
                                    ;; 256, fill the high byte,
                                    ;; otherwise append nothing.
                                    ;; e.g. PUSH2 0x00 0x30
                                    (append (if (= 1 (length push-arg))
                                                '(0)
                                                '())
                                            (big-endian-rep (resolve-label s)))))))
    (_ (error (format #f "Invalid operand to push: ~a" arg)))))

;; Return the number of bytes needed to represent n.
(define (sizeof n)
  (let loop ((c 1)
             ;; n needs at least 1 byte to be represented.
             (n (msb n)))
    (if (or (zero? n) (= c 32))
        c
        (loop (1+ c) (msb n)))))

(define (within? low high n)
  (and (>= n low) (<= n high)))

(define (assemble-expr expr)
  ;; Pattern match EXPR against the valid instructions and dispatch to
  ;; the corresponding sub-assembler.
  (match expr
    ((? simple-op? a)             (assemble-simple a))
    (((? simple-op? a))           (assemble-simple a))
    (`(label ,name)               (assemble-label name))
    (`(org   ,(? 256-bit-imm? a)) (assemble-org a))
    (`(push ,a)                   (assemble-push a))
    ;; Handle PUSH1 to PUSH32
    (`(push ,(? (lambda (x) (within? 1 32 x)) p) ,a) (assemble-var-op "push" #x5f p a))
    ;; Handle DUP1 to DUP16
    (`(dup  ,(? (lambda (x) (within? 1 16 x)) p)) (assemble-var-op "dup" #x7f p '()))
    ;; Handle SWAP1 to SWAP16
    (`(swap ,(? (lambda (x) (within? 1 16 x)) p)) (assemble-var-op "swap" #x8f p '()))
    (`(db          ,arg)          (assemble-db arg))
    (`(dw          ,arg)          (assemble-dw arg))
    ((? 256-bit-imm? a)           (assemble-push a))
    (((? 256-bit-imm? a))           (assemble-push a))
    (_ (error (format #f "Unknown expression: ~a" expr))))
  )

(define *pc*            0)
(define *labels*        0)
(define (reset-pc!)     (set! *pc* 0))
(define (reset-labels!) (set! *labels* '()))

(define (write-bytevector-to-file bv fn)
  (let ((port (open-output-file fn)))
    (put-bytevector port bv)
    (close-port port)))

(define (flatten l)
  (if (null? l)
      '()
      (append (car l) (flatten (cdr l)))))

(define (all-sat? p l)
  (cond ((null? l) #t)
        ((p (car l)) (all-sat? p (cdr l)))
        (else #f)))

(define (pass1 exprs)
  ;; Check each instruction for correct syntax and produce code
  ;; generating thunks.  Meanwhile, increment PC accordingly and build
  ;; up labels.
  (reset-labels!)
  (reset-pc!)
  (format #t "Pass one...\n")

  ;; Every assembled instruction, or inlined procedure should return a
  ;; value.  A value of () indicates that it will not be included in
  ;; pass 2.
  (filter
   (lambda (x) (not (null? (car x))))
   ;; Order of SRFI1 map is unspecified, but Guile's map-in-order goes from
   ;; left to right.
   (map-in-order
    (lambda (expr)
      (if (procedure? expr)
          ;; Evaluate an inlined procedure (could do anything(!)).
          (let ((macro-val (expr)))
            ;; But that procedure has to return () or an instruction
            ;; record.
            (if (not (or (null? macro-val)
                         (inst? macro-val)))
                (error (format #f
                               "Error during pass one: macro did not return an instruction record: instead got ~a.  PC: ~a"
                               macro-val
                               *pc*))
                (begin (if (inst? macro-val)
                           ;; This macro generated an instruction
                           ;; record, so advance the program counter.
                           (advance-pc! (inst-length macro-val)))
                       ;; Return a "tagged" result, where the original
                       ;; expression is preserved for debugging.
                       (cons macro-val expr))))

          ;; Assemble a normal instruction.
          (let ((res (assemble-expr expr)))
            (if (inst? res)
                (advance-pc! (inst-length res)))
            ;; Return a "tagged" result, where the original expression
            ;; is preserved, for debugging..
            (cons res expr))))
    exprs)))

(define (pass2 insts)
  (reset-pc!)
  (format #t "Pass two...\n")
  ;; Force the code generating thunks.  All labels should be resolved by now.
  (map-in-order
   (lambda (x)
     (if (not (inst? (car x)))
         (error (format #f "Pass 2: not an instruction record: ~a. PC: ~a." (car x) (num->hex *pc*))))
     (advance-pc! (inst-length (car x)))
     (let ((res (gen-inst (car x))))
       (if verbose? (format #t "PC: ~a ~a\n" (num->hex *pc*) (cdr x)))
       (cond
        ;; Check consistency of declared instruction length and actual
        ;; length.
        ((not (= (inst-length (car x)) (length res)))
         (error (format #f
                        "Pass 2: Instruction length declared does not match actual: Expected length ~a, got length ~a of expression ~a\n PC: ~a"
                        (inst-length (car x)) (length res) res *pc*)))
        ;; Check that everything is at most 256-bit unsigned integers.
        ((not (all-sat? 256-bit-imm? res))
         (error (format #f "Invalid byte at ~4'#x: ~a" *pc* res)))
        (else
         ;; We're ok.
         res))))
   insts))

(define (assemble-prog prog)
  (pass2 (pass1 prog)))

(define (assemble-to-binary prog)
  (map num->binary (flatten (assemble-prog prog))))

(define (assemble-to-hex prog)
  (map num->hex (flatten (assemble-prog prog))))

(define (assemble-to-file prog filename)
  (write-bytevector-to-file
   (u8-list->bytevector (flatten (assemble-prog prog)))
   filename))

;; Take n elements from a list.
(define (take n list)
  (if (or (zero? n) (null? list))
      '()
      (cons (car list)
            (take (1- n) (cdr list)))))

;; For debugging purposes.  Assemble the program and find the
;; instruction that is at the specified byte address.
(define (assemble-find-instr-byte byte prog context)
  (let ((partial-asm (pass1 prog)))
    (let loop ((pc 0) (rest-insts partial-asm))
      (cond ((null? rest-insts) (error (format #f "Reached end of program before specified address ~a" byte)))
            ((>= pc byte)
             (map cdr (take context rest-insts)))
            (else
             (loop (+ pc (inst-length (caar rest-insts)))
                   (cdr rest-insts)))))))

(define example-contract
  '(100000
    calldataload
    sload
    not
    (push add-key)
    jumpi
    stop
    (label add-key)
    32
    calldataload
    0
    calldataload
    sstore))

(define (equ sym val)
  (lambda ()
    (if (not (256-bit-imm? val))
        (error (format #f "Error in equ: Cannot set ~a to ~a." sym val))
        (add-label! sym val))
    '()))

(define (fill-up-to byte addr)
  (lambda ()
    (assemble-expr `(db ,(make-list
                          (- addr *pc*)
                          byte)))))

(define prelude
  `(,(equ 'rsp 64)
    ,(equ 'ip  65)
    ,(equ 'w   66)))

(define next-sub
  `(,(equ 'ip 65)
    (label next)
    (push 1 ip)
    @ @))

(define (assemble-to-bytecode prog)
  (string-concatenate `("0x" ,@(assemble-to-hex prog))))

(define (assemble-to-python prog)
  (format #t "~a\n" (string-concatenate (map (lambda (x)
                                               (string-append "\\x" x))
                                             (assemble-to-hex prog)))))

(define (arith-op? x)
  (member x '(+ - * /)))

(define (assemble-arith-expr expr)
  (match expr
    ((? integer? x) (list x))
    (`(,(? arith-op? op) ,a ,b)
     (append (assemble-arith-expr b)
             (assemble-arith-expr a)
             (list op)))
    (_ (error "Unknown arithmetic expression: " expr))))

(define (main x)
  (if (= 3 (length x))
      (begin (assemble-to-file (append (assemble-arith-expr (read (open-input-string (list-ref x 1)))) '(stop))
                               (list-ref x 2))
             (format #t "Done.\n"))
      (format #t "./assembler.scm <expr> <outfile>"))
  )

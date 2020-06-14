# ActorForth Typing Rules
TODO: Formalize in Coq.
## Notation
The notation `X : a b -> c` indicates that the word `X` takes two
arguments of type `a` and `b` from the stack and produces an argument
of type `c`.

The input/output arities may be 0, as in `drop : a ->` and pushing
constants. The curly brackets notation `{a}` denotes an arbitrary
(possibly empty) stack picture.

## Introduction rule
If `X` is a constant (e.g. number, string) of type `a`, then the type
of the program fragment `X` is `-> a`.
```
                           const(x), x : a
                         -------------------   [Intro]
                               x : -> a
```

`T(a)` means "the type of program fragment `a`.
## Composition via concatenation
A program fragment is either the empty fragment `[]` or the concatenation
of two fragments `a` and `b`, where `a` has the same output arity as
the input arity of `b` and the fragment `a ++ b` has the input arity
of `a` and the output arity of `b`;
```
                            --------------   [Empty]
                             fragment([])

                             fragment(a)
                             fragment(b)
                            a : {x} -> {y}
                            b : {y} -> {z}
                       depth({x}) <= depth({z})
                       ------------------------   [Concat]
                           fragment(a ++ b)
                         a ++ b : {x} -> {z}
```
Note that the resulting stack must have a depth greater than or
equal to the stack depth prior to the first fragment.
### Fragment Concatenation Laws
```
a ++ [] = [] ++ a = a
(a ++ b) ++ c = a ++ (b ++ c).
```
## if
The consequent `c` and alternative `a` fragments of an `if` statement
must have the same type.
```
                             T(c) = T(a)
                         p : {x} -> {y} bool
                         c : {y} -> {z}
                         a : {y} -> {z}
              ------------------------------------------   [If]
              fragment(p if c else a endif) : {x} -> {z}
```
## while
The loop body `b` must have the same stack picture as the input of the
predicate fragment `p`.
```
                          p : {x} -> {y} bool
                          b : {y} -> {x}
         ---------------------------------------------------   [Begin]
           fragment(begin p while b endwhile) : {x} -> {x}
```

## Standard Library
```
0<> : Int -> Bool .
0= : Int -> Bool .
2drop : a b -> .
2dup : a b -> a b a b .
2over : a b c d -> a b c d a b .
2swap : a b c d -> c d a b .
3dup : a b c -> a b c a b c .
< : a Ord , a a -> Bool .
<= : a Ord , a a -> Bool .
= : a Ord , a a -> Bool .
> : a Ord , a a -> Bool .
>= : a Ord , a a -> Bool .
? : a Ref -> a .
[] : Int a Array -> a .
drop : a -> .
dup : a -> a a .
fromMaybe : a a Maybe -> a .
get : a a b Map -> b .
hd : a List -> a .
lrot : a b c -> b c a .
nip : a b -> b .
over : a b -> a b a .
rrot : a b c -> c b a .
swap : a b -> b a .
tl : a List -> a List .
tuck : a b -> b a b .
```

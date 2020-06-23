# Assembler for the EVM

## Installation requirements
- Virtualenv


## Private node

### Docker
To run a private node, execute:
`docker-compose up -d`

### Natively
`./nodestart`


## Files
- `assembler.py` is the EVM assembler
- `main.py` reads Lisp-style EVM assembly (see `demo` folder) from a
  file and returns with stack information.  The memory is stored
  `f.mem` where `f` is the name of the file passed to it.
- `run.sh` accepts a filename as an argument, assembles the file and
  runs it, reporting the stack, contract code and memory at the end.
- `demo/` - demo folder
  - `factorial.lisp` computes factorial
  - `hello.lisp` writes 'hello, world!' to memory
  - `fibonacci.lisp` computes fibonacci
  - `sum_of_squares.lisp` computes the sum of squares

## Usage
1. Run `source setup.sh` to download the appropriate Virtualenv
   dependencies.
2. Use `run.sh` like so:

```text
$ ./run.sh demo/factorial.lisp 
Filename: factorial.lisp
Contract size: 104 bytes
Stack: [20922789888000]

Contract code

00000000: 6010 6100 1960 1058 0160 0051 6010 6002  `.a..`.X.`.Q`.`.
00000010: 0a02 0160 0052 565b 005b 8015 6100 5057  ...`.RV[.[..a.PW
00000020: 8060 0190 0361 0019 6010 5801 6000 5160  .`...a..`.X.`.Q`
00000030: 1060 020a 0201 6000 5256 5b02 6000 5180  .`....`.RV[.`.Q.
00000040: 61ff ff16 9060 1060 020a 9004 6000 5256  a....`.`....`.RV
00000050: 5b50 6001 6000 5180 61ff ff16 9060 1060  [P`.`.Q.a....`.`
00000060: 020a 9004 6000 5256                      ....`.RV

Memory

00000000: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000010: 0000 0000 0000 0000 0000 0000 0000 0000  ................
```

## Assembler documentation
### Pass 1
#### Handling expressions
Each expression of a program is passed to `assemble_expr` (which also
checks if they're well-formed).  `assemble_expr` returns an
`Instruction` dataclass that has the following fields (for a normal
instruction):

| Record entry | Type       | Description                                       |
| :-:          | :-:        | :-:                                               |
| `len`        | `int`      | The length of the instruction, in bytes.          |
| `gen`        | `callable` | Thunk that computes the actual instruction bytes. |

**Assertion**: For all `Instruction` objects `i`, `i.len ==
i.gen(None)`.

The use of converting expressions into record types like this allows
us to compute the length of the program (and resolve look ahead
labels).

#### Handling lambdas
Lambdas (i.e. `type(x) == callable`) that are embedded in a program
must accept (and ignore) one argument (`None`), and return either `[]`
or an instruction record (whose thunk must return a list of the
specified length).  This is the main extension mechanism for the
assembler.  For instance, to handle `(foo equ 10)` expressions,
`assemble_expr` returns `make_inst(0, lambda _: add_label(expr[0],
expr[2]))`, an instruction record that, during pass 2, will add a
label with the specified value.  `add_label` returns `[]`, so this is
a valid instruction record as `[]` has length 0.

### Pass 2
Once the program makes it through pass 1, we perform code generation
and label resolution.  Instruction records have a `len` field that
tells in advance how many bytes will be generated from the thunk.
Consistency between this number and what the thunk outputs is checked.
Each instruction record is also checked that it generates only
unsigned 8-bit integers.  The result is flattened into a list of
unsigned numbers, which can be manipulated as the user wishes.


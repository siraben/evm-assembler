# EVM Assembler in Python

This project provides an assembler for the Ethereum Virtual Machine
(EVM), written purely in Python without any dependencies.

## Files and Directories

- `assembler.py`: The core EVM assembler script.
- `main.py`: This script reads Lisp-style EVM assembly from a file
  (see `examples` folder for examples), assembles it into bytecode, and
  writes the bytecode to a new file.
- `examples/`: This directory contains a set of examples that you can
  use to test the assembler.
  - `factorial.lisp`: Computes factorial.
  - `hello.lisp`: Writes 'Hello, world!' to memory.
  - `fibonacci.lisp`: Computes fibonacci numbers.
  - `sum_of_squares.lisp`: Computes the sum of squares.
  - `ski.lisp`: A graph reduction machine for λ-calculus.

## Usage
Use the `main.py` script to assemble and write bytecode. It accepts
the filename of the source file as a command-line argument.

Here's an example of how to use it:

```sh
$ python main.py demo/factorial.lisp
```

The output of this command will be a new file named
`demo/factorial.lisp.vm`, which contains the bytecode of the assembled
program.

Please note that the previous functionalities related to running a
private node, or reporting the stack, contract code and memory at the
end, have been removed in the latest version of the project. The
primary focus now is to provide a lightweight, dependency-free EVM
assembler.

## License
This project is licensed under the MIT license.

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


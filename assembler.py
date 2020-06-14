from dataclasses import dataclass

# Verbosity setting
# 0 - Silent
# 1 - Pass 1 and 2 are reported
# 2 - Debug information reported
verbosity = 0


@dataclass
class Instruction:
    len: int
    gen: callable


def make_inst(len, gen):
    res = Instruction(len=len, gen=gen)
    return res


simple_ops = {
    "stop": [0x00],
    "add": [0x01],
    "+": [0x01],  # custom
    "mul": [0x02],
    "*": [0x02],  # custom
    "sub": [0x03],
    "div": [0x04],
    "sdiv": [0x05],
    "mod": [0x06],
    "smod": [0x07],
    "addmod": [0x08],
    "+mod": [0x08],  # custom
    "mulmod": [0x09],
    "*mod": [0x09],  # custom
    "exp": [0x0A],
    "signextend": [0x0B],
    "lt": [0x10],
    "gt": [0x11],
    "slt": [0x12],
    "sgt": [0x13],
    "eq": [0x14],
    "=": [0x14],  # custom
    "iszero": [0x15],
    "0=": [0x15],  # custom
    "and": [0x16],
    "or": [0x17],
    "xor": [0x18],
    "not": [0x19],
    "byte": [0x1A],
    "sha3": [0x20],
    "address": [0x30],
    "balance": [0x31],
    "origin": [0x32],
    "caller": [0x33],
    "callvalue": [0x34],
    "calldataload": [0x35],
    "calldatasize": [0x36],
    "calldatacopy": [0x37],
    "codesize": [0x38],
    "codecopy": [0x39],
    "gasprice": [0x3A],
    "extcodesize": [0x3B],
    "extcodecopy": [0x3C],
    "blockhash": [0x40],
    "coinbase": [0x41],
    "timestamp": [0x42],
    "number": [0x43],
    "difficulty": [0x44],
    "gaslimit": [0x45],
    "pop": [0x50],
    "mload": [0x51],
    "mstore": [0x52],
    "mstore8": [0x53],
    "sload": [0x54],
    "sstore": [0x55],
    "jump": [0x56],
    "jumpi": [0x57],
    "pc": [0x58],
    "msize": [0x59],
    "gas": [0x5A],
    "jumpdest": [0x5B],
    "push1": [0x60],
    "push2": [0x61],
    "push3": [0x62],
    "push4": [0x63],
    "push5": [0x64],
    "push6": [0x65],
    "push7": [0x66],
    "push8": [0x67],
    "push9": [0x68],
    "push10": [0x69],
    "push11": [0x6A],
    "push12": [0x6B],
    "push13": [0x6C],
    "push14": [0x6D],
    "push15": [0x6E],
    "push16": [0x6F],
    "push17": [0x70],
    "push18": [0x71],
    "push19": [0x72],
    "push20": [0x73],
    "push21": [0x74],
    "push22": [0x75],
    "push23": [0x76],
    "push24": [0x77],
    "push25": [0x78],
    "push26": [0x79],
    "push27": [0x7A],
    "push28": [0x7B],
    "push29": [0x7C],
    "push30": [0x7D],
    "push31": [0x7E],
    "push32": [0x7F],
    "dup1": [0x80],
    "dup2": [0x81],
    "dup3": [0x82],
    "dup4": [0x83],
    "dup5": [0x84],
    "dup6": [0x85],
    "dup7": [0x86],
    "dup8": [0x87],
    "dup9": [0x88],
    "dup10": [0x89],
    "dup11": [0x8A],
    "dup12": [0x8B],
    "dup13": [0x8C],
    "dup14": [0x8D],
    "dup15": [0x8E],
    "dup16": [0x8F],
    "swap1": [0x90],
    "swap2": [0x91],
    "swap3": [0x92],
    "swap4": [0x93],
    "swap5": [0x94],
    "swap6": [0x95],
    "swap7": [0x96],
    "swap8": [0x97],
    "swap9": [0x98],
    "swap10": [0x99],
    "swap11": [0x9A],
    "swap12": [0x9B],
    "swap13": [0x9C],
    "swap14": [0x9D],
    "swap15": [0x9E],
    "swap16": [0x9F],
    "log0": [0xA0],
    "log1": [0xA1],
    "log2": [0xA2],
    "log3": [0xA3],
    "log4": [0xA4],
    "create": [0xF0],
    "call": [0xF1],
    "callcode": [0xF2],
    "return": [0xF3],
    "delegatecall": [0xF4],
    "revert": [0xFD],
    "invalid": [0xFE],
    "selfdestruct": [0xFF],
}

labels = {}
subroutines = {}
pc = 0


def advance_pc(count):
    global pc
    pc += count


def assemble_simple(a):
    if a in simple_ops:
        return make_inst(len(simple_ops[a]), lambda _: simple_ops[a])
    else:
        raise Exception("Operation not found: {}".format(a))


def add_label(name, val):
    global labels
    if name in labels:
        raise Exception("Label with name {} already exists".format(name))
    else:
        if verbosity == 2:
            print("Adding label {} with value {}".format(name, hex(val)))
        labels[name] = val
        return []

def add_subroutine(name, val):
    global subroutines
    if name in subroutines:
        raise Exception("Subroutine with name {} already exists".format(name))
    else:
        if verbosity == 2:
            print("Adding subroutine {} with value {}".format(name, hex(val)))
        subroutines[name] = val
        return []

def resolve_label(n):
    global labels
    if is_256_bit_imm(n):
        return label_or_imm256
    if n in labels:
        return labels[n]
    raise Exception("Label not found: {}".format(n))


def assemble_label(name):
    if type(name) == str:
        add_label(name, pc)
        return make_inst(1, lambda _: simple_ops["jumpdest"])
    else:
        # It's possible to add a non-string label, but we don't want
        # people to start having tuples, lists etc. as labels.
        raise Exception("Cannot add non-string label: {}".format(name))
    
def assemble_subroutine(name):
    if type(name) == str:
        add_subroutine(name, pc)
        return make_inst(0, lambda _: [])
        # return make_inst(1, lambda _: simple_ops["jumpdest"])
    else:
        # It's possible to add a non-string label, but we don't want
        # people to start having tuples, lists etc. as labels.
        raise Exception("Cannot add non-string name for subroutine: {}".format(name))


def reset_labels():
    """Reset labels."""
    global labels
    labels = {}


def reset_pc():
    """Reset the program counter."""
    global pc
    pc = 0


def is_256_bit_imm(n):
    """Is n a 256-bit number?"""
    return type(n) == int and n >= 0 and 1 << 256 > n


def sizeof(n):
    """Return the number of bytes needed to represent n."""
    return len(big_endian_rep(n))


def is_simple_op(op):
    """Is op a simple op?"""
    return op in simple_ops


def lsb(n):
    """Extract the least significant byte from n."""
    return n & 255


def msb(n):
    """Extract the most significant bytes from n."""
    return n >> 8


def big_endian_rep(n):
    res = [lsb(n)]
    n = msb(n)
    for c in range(32):
        if n == 0 or c == 31:
            break
        else:
            res = [lsb(n)] + res
            n = msb(n)
    return res


# push, jump, jumpi
def assemble_push_then(arg, after):
    if type(arg) == int:
        return make_inst(
            1 + sizeof(arg) + len(after),
            lambda _: [0x5F + sizeof(arg)] + big_endian_rep(arg) + after,
        )
    elif type(arg) == str:
        return make_inst(
            3 + len(after),
            lambda _: (
                [0x5F + 2]
                + (
                    (lambda push_arg: ([0] if 1 == len(push_arg) else []) + push_arg)(
                        big_endian_rep(resolve_label(arg))
                    )
                )
                + after
            ),
        )
    else:
        raise Exception("Invalid operand to push: {}".format(arg))


def assemble_call(arg):
    if type(arg) == str:
        return make_inst(
            22,
            lambda _: (
                [0x5F + 2]
                + (
                    (lambda push_arg: ([0] if 1 == len(push_arg) else []) + push_arg)(
                        big_endian_rep(resolve_label(arg))
                    )
                )
                + [
                    *simple_ops["push1"],
                    16,
                    *simple_ops["pc"],
                    *simple_ops["add"],
                    *simple_ops["pushr"],
                    *simple_ops["jump"],
                    *simple_ops["jumpdest"],
                ]
            ),
        )
    else:
        raise Exception("Invalid operand to call: {}".format(arg))


def assemble_expr(expr):
    if type(expr) == str and expr in simple_ops:
        # expr == simple_op
        return assemble_simple(expr)
    elif is_256_bit_imm(expr):
        # implicit push
        return assemble_push_then(expr, [])
    elif type(expr) == str:
        # If expr was already declared a subroutine previously.
        if expr in subroutines:
            return assemble_call(expr)
        elif expr in labels:
            return assemble_push_then(expr, [])
        else:
        # Otherwise, expr's value as a label be resolved at pass 2.
            return assemble_push_then(expr, [])
    elif type(expr) == list:
        # expr == [??]
        if len(expr) == 1:
            if expr[0] in simple_ops:
                # expr == [simple_op]
                return assemble_simple(expr[0])
        elif len(expr) == 2:
            if expr[0] == "label" and type(expr[1]) == str:
                # expr == ["label", string]
                return assemble_label(expr[1])
            elif expr[0] == "subroutine" and type(expr[1]) == str:
                # expr == ["subroutine", string]
                return assemble_subroutine(expr[1])
            elif expr[0] == "org" and is_256_bit_imm(expr[1]):
                # expr == ["org", uint256]
                return assemble_org(expr[1])
            elif expr[0] == "push":
                # expr == ["push", ???]
                return assemble_push_then(expr[1], [])
            elif expr[0] == "jump" and type(expr[1]) == str:
                # expr == ["jump", ???]
                return assemble_push_then(expr[1], [0x56])
            elif expr[0] == "jumpi" and type(expr[1]) == str:
                # expr == ["jumpi", ???]
                return assemble_push_then(expr[1], [0x57])
            elif expr[0] == "db" and type(expr[1]) == list:
                # expr == ["db", [???]]
                return assemble_dw(expr[1])
            elif expr[0] == "dw" and type(expr[1]) == list:
                # expr == ["dw", [???]]
                return assemble_dw(expr[1])
            elif expr[0] == "call" and type(expr[1]) == str:
                # expr == ["call", ???]
                return assemble_call(expr[1])
        elif len(expr) == 3:
            # expr == [string, "equ", uint256]
            if expr[1] == "equ" and type(expr[0]) == str and is_256_bit_imm(expr[2]):
                return make_inst(0, lambda _: add_label(expr[0], expr[2]))
    else:
        raise Exception("Unknown expression: {}".format(expr))


def pass1(exprs):
    reset_labels()
    reset_pc()
    if verbosity == 1:
        print("Pass one...")
    res = []
    for expr in exprs:
        if type(expr) == callable:
            macro_val = expr(None)
            if macro_val == [] or type(macro_val) == Instruction:
                if type(macro_val) == Instruction:
                    advance_pc(macro_val.len)
                res.append([macro_val, expr])
            else:
                raise Exception(
                    "Error during pass one: macro did not return an instruction record: instead got {}. PC: {}".format(
                        macro_val, pc
                    )
                )
        else:
            temp = assemble_expr(expr)
            if type(temp) == Instruction:
                advance_pc(temp.len)
            res.append([temp, expr])
    return res


def pass2(insts):
    reset_pc()
    if verbosity == 1:
        print("Pass two...")
    res = []
    for inst in insts:
        if type(inst[0]) == Instruction:
            advance_pc(inst[0].len)
            temp = inst[0].gen(None)
            if verbosity == 2:
                print("PC: {} {}".format(hex(pc), inst[1]))
            if inst[0].len != len(temp):
                raise Exception(
                    "Pass 2: Instruction length declared does not match actual: Expected length {}, got length {} of expression {}\n PC: {}".format(
                        inst[0].len, len(temp), temp, pc
                    )
                )
            elif not all(is_256_bit_imm(elem) for elem in temp):
                raise Exception("Invalid byte at {}: {}".format(hex(pc), temp))
            else:
                res.append(temp)
        else:
            raise Exception(
                "Pass 2: not an instruction record: {}. PC: {}.".format(inst, hex(pc))
            )
    return res


def flatten(ll):
    res = []
    for x in ll:
        for y in x:
            res.append(y)
    return res


def assemble_prog(prog):
    """Assemble a program in the EVM bytecode format."""
    return flatten(pass2(pass1(prog)))


## Custom opcodes

# Location of return stack
return_stack_loc = 0
forth_words = []

forth_words += [
    # Left shift
    ("shl", [2, "exp", "mul"]),
    # Right shift
    ("shr", [2, "exp", "swap1", "div"]),
    # Pushing to the return stack
    (
        "pushr",
        [return_stack_loc, "mload", 16, "shl", "add", return_stack_loc, "mstore"],
    ),
    # Popping from the return stack
    (
        "popr",
        [
            return_stack_loc,
            "mload",
            "dup1",
            (1 << 16) - 1,
            "and",
            "swap1",
            16,
            "shr",
            return_stack_loc,
            "mstore",
        ],
    ),
    # Subroutine return
    ("ret", ["popr", "jump"]),
    ("exit", ["popr", "jump"]),
]

# Forth style stack words
forth_words += [
    ("dup", ["dup1"]),
    ("swap", ["swap1"]),
    ("drop", ["pop"]),
    ("nip", ["swap", "drop"]),
    ("2drop", ["pop", "pop"]),
    (">r", ["pushr"]),
    ("r>", ["popr"]),
    ("rdrop", ["r>", "drop"]),
    ("2dup", ["dup2", "dup2"]),
    ("rot", ["swap1", "swap2"]),
    ("lrot", ["swap1", "swap2"]),
    ("-rot", ["swap2", "swap1"]),
    ("rrot", ["swap2", "swap1"]),
    ("over", ["dup2"]),
    ("2over", ["dup4", "dup4"]),
    ("2swap", ["swap2", "swap1", "swap3", "swap1"]),
]

# Forth style arithmetic operators
forth_words += [
    ("-", ["swap", "sub"]),
    ("/", ["swap", "div"]),
    ("s/", ["swap", "sdiv"]),
    ("modulo", ["swap", "mod"]),
    ("^", ["swap", "exp"]),
]

# Forth style comparison operators
forth_words += [
    (">", ["swap", "gt"]),
    ("<", ["swap", "lt"]),
    ("s<", ["swap", "lt"]),
    ("s<", ["swap", "slt"]),
    ("rshift", ["shr"]),
    ("lshift", ["shl"]),
]


# Forth style memory operators
forth_words += [
    ("@", ["mload"]),
    ("!", ["mstore"]),
    ("c@", ["mload", 248, "shr"]),
    ("c!", ["mstore8"]),
    ("+c!", ["dup", "c@", "dup3", "+", "swap", "c!", "drop"]),
    ("-c!", ["dup", "c@", "dup3", "-", "swap", "c!", "drop"]),
    ("d@", ["mload", 240, "shr"]),
    ("d!", ["dup2", 8, "shr", "dup2", "c!", 1, "+", "swap", 255, "and", "swap", "c!"]),
    ("+d!", ["dup", "d@", "dup3", "+", "swap", "d!", "drop"]),
    ("-d!", ["dup", "d@", "dup3", "-", "swap", "d!", "drop"]),
    ("s@", ["sload"]),
    ("s!", ["sstore"]),
    ("+!", ["dup", "@", "dup3", "+", "swap", "!", "drop"]),
    ("-!", ["dup", "@", "dup3", "-", "swap", "!", "drop"]),
    ("cell+", [2, "+"]),
    ("cells", [2, "*"]),
]


for (x, y) in forth_words:
    simple_ops[x] = assemble_prog(y)

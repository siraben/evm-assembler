from eth import constants
from eth.chains.mainnet import MainnetChain
from eth.db.atomic import AtomicDB
from eth_utils import to_wei, encode_hex
from assembler import assemble_prog
from sexp import parse_sexp
import sys

MOCK_ADDRESS = constants.ZERO_ADDRESS
DEFAULT_INITIAL_BALANCE = to_wei(1, "ether")

GENESIS_PARAMS = {
    "parent_hash": constants.GENESIS_PARENT_HASH,
    "uncles_hash": constants.EMPTY_UNCLE_HASH,
    "coinbase": constants.ZERO_ADDRESS,
    "transaction_root": constants.BLANK_ROOT_HASH,
    "receipt_root": constants.BLANK_ROOT_HASH,
    "difficulty": constants.GENESIS_DIFFICULTY,
    "block_number": constants.GENESIS_BLOCK_NUMBER,
    "gas_limit": constants.GENESIS_GAS_LIMIT,
    "extra_data": constants.GENESIS_EXTRA_DATA,
    "nonce": constants.GENESIS_NONCE,
}

GENESIS_STATE = {
    MOCK_ADDRESS: {
        "balance": DEFAULT_INITIAL_BALANCE,
        "nonce": 0,
        "code": b"",
        "storage": {},
    }
}

chain = MainnetChain.from_genesis(AtomicDB(), GENESIS_PARAMS, GENESIS_STATE)

vm = chain.get_vm()


def run_bytecode(code):
    return vm.execute_bytecode(
        origin=MOCK_ADDRESS,
        gas=100000000,
        gas_price=1,
        to=MOCK_ADDRESS,
        value=123,
        data = bytes([0] * 31 + [54] + [0] * 31 + [210]),
        code=code,
        sender=MOCK_ADDRESS,
    )


def extract_stack(vm):
    return list(
        map(
            lambda x: int.from_bytes(x[1], byteorder="big")
            if type(x[1]) == bytes
            else x[1],
            vm._stack.values,
        )
    )

def extract_storage(vm):
    print(vm.state.get_storage(MOCK_ADDRESS, 54))
    return [vm.state.get_storage(MOCK_ADDRESS, i) for i in range(0,10000)]

if len(sys.argv) == 2:
    with open(sys.argv[1], "r") as f:
        bytecode = assemble_prog(parse_sexp(f.read()))
        vm2 = run_bytecode(bytes(bytecode))
        storage = extract_storage(vm2)
        print(
            "Filename: {}\nContract size: {} bytes\nStack: {}\n".format(
                sys.argv[1], len(bytecode), extract_stack(vm2)
            )
        )
        with open(sys.argv[1] + ".mem", "wb") as f:
            f.write(bytes(vm2.memory_read(0, 10000)))
            f.flush()
            
        with open(sys.argv[1] + ".vm", "wb") as f:
            f.write(bytes(bytecode))

        with open(sys.argv[1] + ".ss", "wb") as f:
            f.write(bytes(storage))

        import ipdb; ipdb.set_trace()
else:
    print("python main.py <assembly file>")

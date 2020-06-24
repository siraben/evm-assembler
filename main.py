from eth import constants
from eth.chains.mainnet import MainnetChain
from eth.db.atomic import AtomicDB
from eth_utils import to_wei, encode_hex
from assembler import assemble_prog, big_endian_rep
from sexp import parse_sexp
from web3 import Web3
from web3.middleware import geth_poa_middleware
import sys


SENDER = "0x0712fa982f9c9cCd74aA698eF03f5Bda837BC81f"
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

def extract_storage(vm, address):
    print(vm.state.get_storage(address, 54))
    return [vm.state.get_storage(address, i) for i in range(0,10000)]

if len(sys.argv) == 2:
    with open(sys.argv[1], "r") as f:
        bytecode = assemble_prog(parse_sexp(f.read()))
        vm2 = run_bytecode(bytes(bytecode))
        storage = extract_storage(vm2, MOCK_ADDRESS)

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


        # Stuff to connect to a local node
        w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))
        with open("password.txt", "r") as f:
            pwd = f.read().replace('\n', '')
            w3.geth.personal.unlock_account(SENDER, pwd, 3600)
            w3.middleware_onion.inject(geth_poa_middleware, layer=0)


        tx_hash = w3.eth.sendTransaction({'from': SENDER, 'value': 0, 'data': bytes(bytecode)})
        receipt = w3.eth.waitForTransactionReceipt(tx_hash)
        contract_address = receipt['contractAddress']

        # tx_hash = w3.eth.sendTransaction(
        #     {
        #         'from': SENDER,
        #         'to': contract_address,
        #         'value': 0,
        #         'data': bytes([0] * 31 + [57] + [0] * 31 + [210])
        #     }
        # )
        # receipt = w3.eth.waitForTransactionReceipt(tx_hash)

        abi = [
            {
                "name": "baz",
                "type": "function",
                "inputs": [
                    {
                        "name": "x",
                        "type": "uint32"
                    },
                    {
                        "name": "y",
                        "type": "bool"
                    }
                ],
                "outputs": [
                    {
                        "name": "r",
                        "type": "bool"
                    }
                ]
            }
        ]

        contract = w3.eth.contract(
            abi=abi,
            bytecode=w3.eth.getCode(contract_address),
            address=contract_address
        )

        # tx_hash = contract.functions.baz(44, True).transact({'from': SENDER})
        # receipt = w3.eth.waitForTransactionReceipt(tx_hash)
        print(contract.functions.baz(44, True).call())


        import ipdb; ipdb.set_trace()
else:
    print("python main.py <assembly file>")

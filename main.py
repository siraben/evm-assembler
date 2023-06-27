import argparse
import binascii
import os
from assembler import assemble_prog
from sexp import parse_sexp

def parse_args():
    parser = argparse.ArgumentParser(
        description="Assemble a given source file into EVM bytecode."
    )
    parser.add_argument(
        'source_file', 
        type=str, 
        help='Path to the source file in Lisp-style EVM assembly format.'
    )
    parser.add_argument(
        '-o', '--output', 
        type=str, 
        default=None, 
        help='Path to the output file. Default is the name of the source file with .bin extension.'
    )
    return parser.parse_args()

def validate_file(file_path):
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
    if not file_path.endswith('.lisp'):
        raise ValueError(f"File must have a .lisp extension: {file_path}")

def read_source(file_path):
    validate_file(file_path)
    with open(file_path, 'r') as source_file:
        return parse_sexp(source_file.read())

def get_output_file_path(source_file_path, output_file_path):
    if output_file_path:
        return output_file_path
    else:
        source_file_name = os.path.basename(source_file_path)
        base_name = os.path.splitext(source_file_name)[0]
        return os.path.join(os.getcwd(), f"{base_name}.bin")

def write_bytecode_to_file(bytecode, file_path):
    with open(file_path, 'wb') as output_file:
        output_file.write(binascii.hexlify(bytes(bytecode)))

def main():
    args = parse_args()
    source_code = read_source(args.source_file)
    bytecode = assemble_prog(source_code)
    output_file_path = get_output_file_path(args.source_file, args.output)
    write_bytecode_to_file(bytecode, output_file_path)
    print(f"Bytecode written to: {output_file_path}")

if __name__ == "__main__":
    main()

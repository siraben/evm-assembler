from assembler import assemble_prog
from sexp import parse_sexp
import argparse
import os


def run_assembler(filename):
    with open(filename, "r") as f:
        return assemble_prog(parse_sexp(f.read()))


def write_bytecode(bytecode, filename):
    base_filename = os.path.splitext(filename)[0]
    with open(base_filename + ".bin", "wb") as f:
        f.write(bytes(bytecode))


def main():
    parser = argparse.ArgumentParser(description='Assemble a given source file.')
    parser.add_argument('filename', type=str, help='source file name')

    args = parser.parse_args()

    bytecode = run_assembler(args.filename)
    write_bytecode(bytecode, args.filename)


if __name__ == '__main__':
    main()

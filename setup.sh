#!/usr/bin/env bash
virtualenv -p python3 venv &&
source venv/bin/activate &&
pip3 install py-evm pycryptodome &&
echo "Done setting up."

#!/usr/bin/env bash
set -e
python main.py "$1"
printf '\nContract code\n\n'
xxd -a "$1.vm" | tail -n 20
printf '\nMemory\n\n'
xxd -a "$1.mem"
printf '\nStorage\n\n'
xxd -a "$1.ss"

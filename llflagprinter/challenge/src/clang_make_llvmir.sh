#!/bin/bash

# Turn c into llvm IR assembly
clang -S -emit-llvm llflagprinter.c
# Assemble that into LLVM IR bitcode
llvm-as llflagprinter.ll

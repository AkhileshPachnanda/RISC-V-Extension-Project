@echo off
REM Compile C test to RISC-V binary and convert to program.mem

SET RISCV_PREFIX=riscv64-unknown-elf
SET TEST_FILE=tests\sha_accel_test.c
SET OUTPUT_DIR=sim

echo Compiling %TEST_FILE%...

REM Compile C to object file
%RISCV_PREFIX%-gcc -march=rv32i -mabi=ilp32 -O2 -nostdlib -nostartfiles -Wl,-Ttext=0x00000000 -o %OUTPUT_DIR%\program.elf %TEST_FILE%

if errorlevel 1 (
    echo Compilation failed!
    exit /b 1
)

echo Converting to memory file...

REM Convert ELF to binary
%RISCV_PREFIX%-objcopy -O binary %OUTPUT_DIR%\program.elf %OUTPUT_DIR%\program.bin

REM Convert binary to hex format for Verilog $readmemh
%RISCV_PREFIX%-objcopy -O verilog %OUTPUT_DIR%\program.elf %OUTPUT_DIR%\program.mem

echo Done! Generated %OUTPUT_DIR%\program.mem

REM Show disassembly for verification
echo.
echo Disassembly:
%RISCV_PREFIX%-objdump -d %OUTPUT_DIR%\program.elf

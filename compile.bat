@echo off
REM Compile all Verilog source files for ModelSim simulation

echo Compiling Verilog files...
vlog -work work src\pcpi_sha.v
vlog -work work src\ram_model.v
vlog -work work src\picorv32.v
vlog -work work src\riscv_top.v
vlog -work work tb\riscv_tb.v

echo Compilation complete!

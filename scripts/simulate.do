# Questa/ModelSim RTL simulation and VCD generation.
file mkdir saved/sha256_core/simulation

if {[file exists work]} {
    vdel -lib work -all
}
vlib work

vlog \
    rtl/sha256_core/src/sha256_k_constants.v \
    rtl/sha256_core/src/sha256_w_mem.v \
    rtl/sha256_core/src/sha256_core.v \
    rtl/sha256_core/tb/tb_sha256_core.v

vsim -voptargs=+acc work.tb_sha256_core
vcd file saved/sha256_core/simulation/sha256_core.vcd
vcd add -r /tb_sha256_core/dut/*
run -all
quit -f

IVERILOG ?= iverilog
VVP ?= vvp

BUILD_DIR := build
SIM_BINARY := $(BUILD_DIR)/tb_sha256_core.vvp
RTL := \
	rtl/sha256_core/src/sha256_k_constants.v \
	rtl/sha256_core/src/sha256_w_mem.v \
	rtl/sha256_core/src/sha256_core.v
TB := rtl/sha256_core/tb/tb_sha256_core.v

.PHONY: sim clean

sim: $(SIM_BINARY)
	$(VVP) $(SIM_BINARY)

$(SIM_BINARY): $(RTL) $(TB)
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) -g2005 -Wall -s tb_sha256_core -o $@ $(RTL) $(TB)

clean:
	rm -rf $(BUILD_DIR)

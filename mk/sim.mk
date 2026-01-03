# ============================================================
# mk/sim.mk
# ============================================================

SIM_ROOT := $(BUILD_PATH)/sim

TB_NAMES := $(notdir $(basename $(TB_VERILOG_FILES)))
TB_VCDS  := $(foreach tb,$(TB_NAMES),$(SIM_ROOT)/$(tb)/$(tb).vcd)

.PHONY: sim sim-wave wave-gui

sim: $(TB_VCDS)

define SIM_RULE
$(SIM_ROOT)/$(1)/$(1).vcd: $(VERILOG_FILES) $(filter %/$(1).v,$(TB_VERILOG_FILES))
	@echo "==> Simulating $(1)"
	@mkdir -p $(SIM_ROOT)/$(1)
	iverilog -g2012 -Wall -Wno-timescale \
		-o $(SIM_ROOT)/$(1)/sim.out \
		$(VERILOG_FILES) \
		$(filter %/$(1).v,$(TB_VERILOG_FILES))
	cd $(SIM_ROOT)/$(1) && vvp sim.out
endef

$(foreach tb,$(TB_NAMES),$(eval $(call SIM_RULE,$(tb))))

sim-wave: sim
	@echo "Waveforms generated:"
	@for vcd in $(TB_VCDS); do echo "  $$vcd"; done

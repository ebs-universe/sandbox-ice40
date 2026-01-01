# ============================================================
# mk/sim.mk
#
# Simulation build phase (explicit rules, Make-correct)
# ============================================================

SIM_ROOT := $(BUILD_PATH)/sim

# Testbench basenames: tb/top_tb.v -> top_tb
TB_NAMES := $(notdir $(basename $(TB_VERILOG_FILES)))

# VCD targets: build/.../sim/top_tb/top_tb.vcd
TB_VCDS := $(foreach tb,$(TB_NAMES),$(SIM_ROOT)/$(tb)/$(tb).vcd)

.PHONY: sim wave wave-gui

# ------------------------------------------------------------
# Top-level simulation target
# ------------------------------------------------------------

sim: $(TB_VCDS)

# ------------------------------------------------------------
# One explicit rule per testbench (generated)
# ------------------------------------------------------------

define SIM_RULE
$(SIM_ROOT)/$(1)/$(1).vcd: $(VERILOG_FILES) $(filter %/$(1).v,$(TB_VERILOG_FILES))
	@echo "==> Simulating $(1)"
	@mkdir -p $(SIM_ROOT)/$(1)
	iverilog -g2012 -o $(SIM_ROOT)/$(1)/sim.out \
		$(VERILOG_FILES) \
		$(filter %/$(1).v,$(TB_VERILOG_FILES))
	cd $(SIM_ROOT)/$(1) && vvp sim.out
endef

$(foreach tb,$(TB_NAMES),$(eval $(call SIM_RULE,$(tb))))

# ------------------------------------------------------------
# Non-GUI wave target
# ------------------------------------------------------------

wave: sim
	@echo "Waveforms generated:"
	@for vcd in $(TB_VCDS); do \
		echo "  $$vcd"; \
	done

# ------------------------------------------------------------
# GUI wave viewing
# ------------------------------------------------------------

wave-gui: sim
	@echo "Opening GTKWave with all testbench waveforms..."
	@gtkwave $(TB_VCDS)

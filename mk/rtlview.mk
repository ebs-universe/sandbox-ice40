# ============================================================
# mk/rtlview.mk
#
# RTL visualization using yosys + graphviz (dot)
# (Apio-style, no npm)
# ============================================================

RTLVIEW_DIR := $(BUILD_PATH)/rtl
RTL_DOT     := $(RTLVIEW_DIR)/$(TOP_MODULE).dot
RTL_SVG     := $(RTLVIEW_DIR)/$(TOP_MODULE).svg

.PHONY: rtlview

rtlview: $(RTL_SVG)

$(RTLVIEW_DIR):
	mkdir -p $(RTLVIEW_DIR)

$(RTL_DOT): $(VERILOG_FILES) | $(RTLVIEW_DIR)
	yosys -p "\
		read_verilog $(VERILOG_FILES); \
		hierarchy -top $(TOP_MODULE); \
		proc; opt; \
		show -format dot -prefix $(RTLVIEW_DIR)/$(TOP_MODULE) \
	"

# Yosys already produces .dot; this step is optional but explicit
$(RTL_SVG): $(RTL_DOT)
	dot -Tsvg $< -o $@

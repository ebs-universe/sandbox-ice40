# ============================================================
# mk/analysis.mk
#
# Post-P&R analysis from nextpnr --report JSON
#
# Generates human-readable summaries for:
#   - Utilization
#   - Clock fmax
#   - Global resources (SB_GB)
#   - Critical timing paths (top 5)
#
# Requires:
#   nextpnr --report <file>.json
# ============================================================

ANALYSIS_JSON := $(RPT)
ANALYSIS_DIR  := $(BUILD_PATH)/analysis

UTIL_TXT  := $(ANALYSIS_DIR)/utilization.txt
CLK_TXT   := $(ANALYSIS_DIR)/clocks.txt
GB_TXT    := $(ANALYSIS_DIR)/globals.txt
PATHS_TXT := $(ANALYSIS_DIR)/timing-top5.txt
SUMMARY   := $(ANALYSIS_DIR)/summary.txt

.PHONY: analysis analysis-util analysis-clocks analysis-globals analysis-paths

# ------------------------------------------------------------
# Master target
# ------------------------------------------------------------

analysis: analysis-util analysis-clocks analysis-globals analysis-paths
	@echo ""
	@echo "Analysis reports generated:"
	@echo "  Utilization : $(UTIL_TXT)"
	@echo "  Clocks      : $(CLK_TXT)"
	@echo "  Globals     : $(GB_TXT)"
	@echo "  Top paths   : $(PATHS_TXT)"
	@echo ""

# ------------------------------------------------------------
# Directory
# ------------------------------------------------------------

$(ANALYSIS_DIR):
	@mkdir -p $(ANALYSIS_DIR)

# ------------------------------------------------------------
# Utilization summary
# ------------------------------------------------------------

analysis-util: $(ANALYSIS_JSON) | $(ANALYSIS_DIR)
	@echo "Resource utilization:" > $(UTIL_TXT)
	@echo "" >> $(UTIL_TXT)
	@jq -r '.utilization | to_entries[] | "\(.key): \(.value.used) / \(.value.available)"' \
	  $(ANALYSIS_JSON) >> $(UTIL_TXT)

# ------------------------------------------------------------
# Clock / fmax summary
# ------------------------------------------------------------

analysis-clocks: $(ANALYSIS_JSON) | $(ANALYSIS_DIR)
	@echo "Clock timing summary:" > $(CLK_TXT)
	@echo "" >> $(CLK_TXT)
	@jq -r '.fmax | to_entries[] | "\(.key): achieved=\(.value.achieved) MHz, constraint=\(.value.constraint) MHz"' \
	  $(ANALYSIS_JSON) >> $(CLK_TXT)

# ------------------------------------------------------------
# Global resource usage
# ------------------------------------------------------------

analysis-globals: $(ANALYSIS_JSON) | $(ANALYSIS_DIR)
	@echo "Global resources:" > $(GB_TXT)
	@echo "" >> $(GB_TXT)
	@jq -r '.utilization.SB_GB | "SB_GB used: \(.used) / \(.available)"' \
	  $(ANALYSIS_JSON) >> $(GB_TXT)

# ------------------------------------------------------------
# Top 5 worst timing paths
# ------------------------------------------------------------

analysis-paths: $(ANALYSIS_JSON) | $(ANALYSIS_DIR)
	@echo "Top 5 critical paths:" > $(PATHS_TXT)
	@echo "" >> $(PATHS_TXT)
	@jq -r '.critical_paths[] | { delay: ([.path[].delay] | add), from: (.from // "<unknown>"), to: (.to // "<unknown>") } | "\(.delay) ns"' \
	  $(ANALYSIS_JSON) \
	| sort -nr \
	| head -n 5 \
	>> $(PATHS_TXT)

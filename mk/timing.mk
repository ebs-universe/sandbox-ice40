# ============================================================
# mk/timing.mk
#
# Timing analysis from nextpnr JSON report
# ============================================================

TIMING_JSON := $(RPT)

TIMING_DIR := $(BUILD_PATH)/timing

TIMING_PATHS := $(TIMING_DIR)/timing-paths.txt
TIMING_TOP5  := $(TIMING_DIR)/timing-top5.txt
TIMING_MOD   := $(TIMING_DIR)/timing-by-module.txt
TIMING_CLK   := $(TIMING_DIR)/timing-by-clock.txt

.PHONY: timing timing-paths timing-top5 timing-modules timing-clocks

# ------------------------------------------------------------
# Master target
# ------------------------------------------------------------

timing: timing-paths timing-top5 timing-modules timing-clocks
	@echo ""
	@echo "Timing reports generated:"
	@echo "  Paths        : $(TIMING_PATHS)"
	@echo "  Top 5 paths  : $(TIMING_TOP5)"
	@echo "  By module    : $(TIMING_MOD)"
	@echo "  By clock     : $(TIMING_CLK)"
	@echo ""

# ------------------------------------------------------------
# Preparation targets
# ------------------------------------------------------------

$(TIMING_JSON) : build $(TIMING_DIR)

$(TIMING_DIR) :
	@mkdir -p $@

# ------------------------------------------------------------
# Full critical-path listing (sorted worst first)
# ------------------------------------------------------------

timing-paths: $(TIMING_JSON)
	@jq -r ".critical_paths[] | \
	  { \
	    delay: ([.path[].delay] | add), \
	    src: (.path[0].from.cell // \"<async>\" | split(\".\")[0]), \
	    dst: (.path[-1].to.cell  // \"<async>\" | split(\".\")[0]) \
	  } | \
	  \"\\(.delay) ns : \\(.src) -> \\(.dst)\"" \
	  $(TIMING_JSON) \
	| sort -nr \
	> $(TIMING_PATHS)

# ------------------------------------------------------------
# Top 5 worst paths
# ------------------------------------------------------------

timing-top5: timing-paths
	@head -n 5 $(TIMING_PATHS) > $(TIMING_TOP5)

# ------------------------------------------------------------
# Aggregate timing by module
# ------------------------------------------------------------

timing-modules: $(TIMING_JSON)
	@jq -r ".critical_paths[] | \
	  { \
	    delay: ([.path[].delay] | add), \
	    mod: (.path[].from.cell? | split(\".\")[0]) \
	  } | \
	  select(.mod != null) | \
	  \"\\(.mod) \\(.delay)\"" \
	  $(TIMING_JSON) \
	| awk '{ sum[$$1] += $$2 } END { for (m in sum) printf "%-25s %8.2f ns\n", m, sum[m] }' \
	| sort -k2 -nr \
	> $(TIMING_MOD)

# ------------------------------------------------------------
# Clock-by-clock summary
# ------------------------------------------------------------

timing-clocks: $(TIMING_JSON)
	@jq -r ".fmax | to_entries[] | \
	  \"\\(.key) : achieved=\\(.value.achieved) MHz, constraint=\\(.value.constraint) MHz\"" \
	  $(TIMING_JSON) \
	> $(TIMING_CLK)

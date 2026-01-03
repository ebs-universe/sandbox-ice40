# ============================================================
# mk/deps.mk
#
# RTL module dependency graph (from Yosys JSON)
# ============================================================

DEPS_DIR := $(BUILD_PATH)/deps
DEPS_DOT := $(DEPS_DIR)/deps.dot
DEPS_SVG := $(DEPS_DIR)/deps.svg

.PHONY: deps

deps: $(DEPS_SVG)
	@echo ""
	@echo "RTL dependency graph generated:"
	@echo "  $(DEPS_SVG)"
	@echo ""

$(DEPS_DIR):
	@mkdir -p $@

# ------------------------------------------------------------
# Generate dependency DOT from Yosys JSON
# ------------------------------------------------------------

$(DEPS_DOT): $(JSON) | $(DEPS_DIR)
	@echo "digraph rtl_deps {" > $@
	@echo "  rankdir=LR;" >> $@
	@echo "  node [shape=box];" >> $@
	@jq -r '.modules | to_entries[] | .key as $parent | (.value.cells // {}) | to_entries[] | "  \"\($parent)\" -> \"\(.value.type)\";"' $(JSON) >> $@
	@echo "}" >> $@
	@echo "Wrote $(DEPS_DOT)"

$(DEPS_SVG): $(DEPS_DOT)
	dot -Tsvg $< -o $@

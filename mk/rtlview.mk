# ============================================================
# mk/rtlview.mk
#
# RTL visualization using yosys + graphviz (dot)
# Compatible with Yosys 0.60
#
# Generates:
#   1) Flattened RTL view (DOT + SVG)
#   2) Hierarchical RTL view (DOT only)
# ============================================================

RTLVIEW_DIR := $(BUILD_PATH)/rtl

# ------------------------------------------------------------
# Flattened view (single graph, hierarchy removed)
# ------------------------------------------------------------

FLAT_PREFIX := $(RTLVIEW_DIR)/$(TOP_MODULE)
FLAT_DOT    := $(FLAT_PREFIX).dot
FLAT_SVG    := $(FLAT_PREFIX).svg

# ------------------------------------------------------------
# Hierarchical view
# ------------------------------------------------------------

HIER_PREFIX := $(RTLVIEW_DIR)/$(TOP_MODULE)-hier
HIER_DOT    := $(HIER_PREFIX).dot

HIER_SVG_DIR := $(RTLVIEW_DIR)/hier
HIER_DOT_DIR := $(HIER_SVG_DIR)/dot

# ------------------------------------------------------------
# Phony targets
# ------------------------------------------------------------

.PHONY: rtlview rtlview-flat rtlview-hier

rtlview: rtlview-flat rtlview-hier rtlview-hier-svg
	@echo ""
	@echo "RTL views generated:"
	@echo "  Flattened:"
	@echo "    $(FLAT_SVG)"
	@echo ""
	@echo "  Hierarchical:"
	@for f in $(HIER_SVG_DIR)/*.svg; do \
		echo "    $$f"; \
	done
	@echo ""
	@echo "Generating RTL SVG index..."
	@{ \
		echo "<!DOCTYPE html>"; \
		echo "<html><head><title>RTL View: $(TOP_MODULE)</title>"; \
		echo "<style>"; \
		echo "body { font-family: sans-serif; }"; \
		echo "object { width: 100%; height: 600px; border: 1px solid #ccc; }"; \
		echo "details { margin-bottom: 1em; }"; \
		echo "</style></head><body>"; \
		echo "<h1>RTL View: $(TOP_MODULE)</h1>"; \
		echo "<h2>Flattened View</h2>"; \
		echo "<p><a href=\"top.svg\">Open standalone SVG</a></p>"; \
		echo "<object type=\"image/svg+xml\" data=\"top.svg\"></object>"; \
		echo "<h2>Hierarchical Views</h2>"; \
		for f in $(HIER_SVG_DIR)/*.svg; do \
			name=$$(basename $$f .svg); \
			echo "<details open>"; \
			echo "<summary><b>$$name</b> (<a href=\"hier/$$name.svg\">open</a>)</summary>"; \
			echo "<object type=\"image/svg+xml\" data=\"hier/$$name.svg\"></object>"; \
			echo "</details>"; \
		done; \
		echo "</body></html>"; \
	} > $(RTLVIEW_DIR)/index.html

# ------------------------------------------------------------
# Directory creation
# ------------------------------------------------------------

$(RTLVIEW_DIR):
	mkdir -p $(RTLVIEW_DIR)

# ------------------------------------------------------------
# Flattened RTL view
# (matches synthesis preprocessing closely)
# ------------------------------------------------------------

rtlview-flat: $(FLAT_SVG)

$(FLAT_DOT): $(VERILOG_FILES) | $(RTLVIEW_DIR)
	yosys -p "\
		read_verilog -sv $(VERILOG_FILES); \
		hierarchy -top $(TOP_MODULE); \
		proc; opt; techmap; opt; clean; \
		show -stretch -width -signed -format dot -colors 42 -prefix $(FLAT_PREFIX) \
	"

$(FLAT_SVG): $(FLAT_DOT)
	dot -Tsvg $< -o $@

# ------------------------------------------------------------
# Hierarchical RTL view
# (single DOT file, module hierarchy preserved)
# ------------------------------------------------------------

rtlview-hier: $(HIER_DOT)

$(HIER_DOT): $(VERILOG_FILES) | $(RTLVIEW_DIR)
	yosys -p "\
		read_verilog -sv $(VERILOG_FILES); \
		hierarchy -top $(TOP_MODULE); \
		proc; opt; \
		show -stretch -width -signed -format dot -colors 42 -prefix $(HIER_PREFIX) \
	"

# ------------------------------------------------------------
# Hierarchical SVG generation (split multi-digraph DOT)
# ------------------------------------------------------------

.PHONY: rtlview-hier-svg
rtlview-hier-svg: $(HIER_DOT)
	@mkdir -p $(HIER_SVG_DIR)
	@mkdir -p $(HIER_DOT_DIR)
	@echo "Splitting hierarchical DOT into per-module DOT files..."

	@awk '\
		/^digraph[[:space:]]+"/ { \
			if (out != "") close(out); \
			name = $$2; \
			gsub(/"/, "", name); \
			out = "$(HIER_DOT_DIR)/" name ".dot"; \
		} \
		{ \
			if (out != "") print > out; \
		} \
	' $(HIER_DOT)

	@echo "Normalizing module filenames..."
	@for f in $(HIER_DOT_DIR)/*.dot; do \
		case "$$f" in \
			*'&#9586;'*) \
				new=$$(echo "$$f" | sed 's|^.*/[^/]*&#9586;|$(HIER_DOT_DIR)/|'); \
				echo "  $$f → $$new"; \
				mv "$$f" "$$new"; \
			;; \
		esac; \
	done

	@echo "Rendering hierarchical SVGs..."
	@for f in $(HIER_DOT_DIR)/*.dot; do \
		echo "  Rendering $$f"; \
		dot -Tsvg $$f -o $(HIER_SVG_DIR)/$$(basename $$f .dot).svg; \
	done

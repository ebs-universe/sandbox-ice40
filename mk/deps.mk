# ============================================================
# mk/deps.mk
#
# Library dependency visualization (Graphviz)
# ============================================================

DEPS_DOT := $(PROJECT_ROOT)/build/deps.dot
DEPS_PNG := $(PROJECT_ROOT)/build/deps.png

.PHONY: deps deps-dot

deps-dot:
	@mkdir -p $(PROJECT_ROOT)/build
	@echo "digraph fpga_libs {" > $(DEPS_DOT)
	@echo "  rankdir=LR;" >> $(DEPS_DOT)
	@echo "  node [shape=box];" >> $(DEPS_DOT)
	@for dep in $(LIB_DEPS); do \
		src=$${dep%%:*}; \
		dst=$${dep##*:}; \
		echo "  \"$$src\" -> \"$$dst\";" >> $(DEPS_DOT); \
	done
	@echo "}" >> $(DEPS_DOT)
	@echo "Wrote $(DEPS_DOT)"

deps: deps-dot
	dot -Tpng $(DEPS_DOT) -o $(DEPS_PNG)
	@echo "Wrote $(DEPS_PNG)"

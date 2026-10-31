# cocotb regression for the CHIMPS-V top-level system.
#
# Run from this directory with the project virtualenv active:
#   source ../.venv/bin/activate
#   make
#
# Override the Python test module when needed:
#   make COCOTB_TEST_MODULES=test_my_module

SIM = ghdl
TOPLEVEL_LANG = vhdl
TOPLEVEL = chimps_v_system

RTL_DIR := $(abspath $(CURDIR)/../../rtl)

# The cocotb tests and the GUI client share the sim/bridge package.
SIM_ROOT := $(abspath $(CURDIR)/..)
export PYTHONPATH := $(SIM_ROOT)$(if $(PYTHONPATH),:$(PYTHONPATH))

# Keep this order identical to scripts/compile-rtl.sh so dependencies are
# analyzed in the same sequence as the VHDL regression.
VHDL_SOURCES = \
	$(RTL_DIR)/chimps_pkg.vhd \
	$(RTL_DIR)/memory_backing_store.vhd \
	$(RTL_DIR)/memory_bus.vhd \
	$(RTL_DIR)/cache_l1.vhd \
	$(RTL_DIR)/pipeline.vhd \
	$(RTL_DIR)/chimps_v_system.vhd

# VHDL-2008 is required for analysis, elaboration, and execution.
GHDL_ARGS = --std=08

# Select the cocotb test module (defaults to the integrated-system smoke test):
#   make COCOTB_TEST_MODULES=server_test
COCOTB_TEST_MODULES ?= test_chimps_v_system

include $(shell cocotb-config --makefiles)/Makefile.sim

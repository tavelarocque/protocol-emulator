# The bench's judging on cocotb recordings of its demos (test_bench_sim.py),
# on the chip-level testbench: test/Makefile and test/tb.v, unchanged, with
# this folder's test module in place of test/test.py.
#
#   make                                   # all five demos
#   make COCOTB_TEST_FILTER=test_bench_nec  # one

HERE := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
TEST := $(abspath $(HERE)/../../../test)

all:
	cd $(TEST) && $(MAKE) COCOTB_TEST_MODULES=test_bench_sim \
	  PYTHONPATH=$(HERE)$(if $(PYTHONPATH),:$(PYTHONPATH)) \
	  $(if $(COCOTB_TEST_FILTER),COCOTB_TEST_FILTER=$(COCOTB_TEST_FILTER))

.PHONY: all

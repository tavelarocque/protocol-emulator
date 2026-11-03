# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
FST ?= -fst # Use more efficient FST format
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = project.v protocol_emulator.v

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				= sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DSIM
VERILOG_SOURCES += $(PDK_ROOT)/ihp-sg13cmos5l/libs.ref/sg13cmos5l_io/verilog/sg13cmos5l_io.v
VERILOG_SOURCES += $(PDK_ROOT)/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/verilog/sg13cmos5l_udp.v
VERILOG_SOURCES += $(PDK_ROOT)/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/verilog/sg13cmos5l_stdcell.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC_DIR)

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.v

# usbhostslave's USB device (third-party, LGPL, test only), compiled first:
# Icarus carries `default_nettype none` from our files into later ones, and
# this code relies on implicit nets.
# In the order its macros need (usbDevice/sim/filelist.icarus upstream).
USB_DEVICE_FILES = \
  dpMem_dc.v \
  fifoRTL.v \
  RxFifoBI.v \
  TxFifoBI.v \
  RxFifo.v \
  TxFifo.v \
  wishBoneBI.v \
  hostSlaveMuxBI.v \
  lineControlUpdate.v \
  processRxBit.v \
  processRxByte.v \
  processTxByte.v \
  readUSBWireData.v \
  siereceiver.v \
  SIETransmitter.v \
  updateCRC5.v \
  updateCRC16.v \
  usbSerialInterfaceEngine.v \
  usbTxWireArbiter.v \
  writeUSBWireData.v \
  USBSlaveControlBI.v \
  endpMux.v \
  fifoMux.v \
  sctxportarbiter.v \
  slaveDirectcontrol.v \
  slaveGetpacket.v \
  slaveRxStatusMonitor.v \
  slaveSendpacket.v \
  slavecontroller.v \
  usbSlaveControl.v \
  usbSlave.v \
  checkLineState.v \
  EP0.v \
  EP1Mouse.v \
  usbDevice.v \
  usbROM.v \
  wishboneArb.v
USB_DEVICE = $(addprefix $(PWD)/usbhostslave/,$(USB_DEVICE_FILES))
VERILOG_SOURCES := $(USB_DEVICE) $(VERILOG_SOURCES)
COMPILE_ARGS += -I$(PWD)/usbhostslave/include -DSIM_COMPILE
TOPLEVEL = tb

# List test modules to run, separated by commas and without the .py suffix:
COCOTB_TEST_MODULES = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

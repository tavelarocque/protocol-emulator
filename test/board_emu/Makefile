# Builds the co-simulation addon (cosim.node) from the chip's RTL, the USB
# device and cosim.cpp, and fetches what the emulator needs. See README.md.

USB = ../usbhostslave
USB_FILES = $(addprefix $(USB)/,$(shell sed -n '/^USB_DEVICE_FILES/,/^$$/p' ../Makefile | grep '\.v' | tr -d '\\'))
NODE_INC ?= $(dir $(shell which node))../include/node
BUILD = build

FIRMWARE = tt-demo-rp2040-v2.0.4.uf2
FIRMWARE_URL = https://github.com/TinyTapeout/tt-micropython-firmware/releases/download/v2.0.4/$(FIRMWARE)
FIRMWARE_SHA256 = 600af466bcafc315fe5414677e442207302be4a0b49f2e8d4388e3519d3dcac3

BOOTROM_URL = https://raw.githubusercontent.com/wokwi/rp2040js/5fbd20508a58b9859758c5cd70b207ba1e0b0150/demo/bootrom.ts
BOOTROM_SHA256 = 99f8a1f813ce3aa9415884de3fb6c5b962d3c6fa0394b05413ad3c7b3c39ec62

all: cosim.node $(BUILD)/$(FIRMWARE) $(BUILD)/bootrom.mjs node_modules

DEVICES = ../spiflash.v ../jtag_tap.v ../swd_dp.v

$(BUILD)/Vboard__ALL.a: board.v $(DEVICES) ../../src/project.v ../../src/protocol_emulator.v
	verilator --cc --no-timing -O3 --Mdir $(BUILD) -Wno-fatal -Wno-lint -Wno-style -Wno-TIMESCALEMOD \
	  -I$(USB)/include -DSIM_COMPILE --top-module board -CFLAGS -fPIC \
	  $(USB_FILES) $(DEVICES) ../../src/project.v ../../src/protocol_emulator.v board.v --build -j 4

cosim.node: cosim.cpp $(BUILD)/Vboard__ALL.a
	g++ -O2 -shared -fPIC -o $@ cosim.cpp -I$(BUILD) -I/usr/share/verilator/include \
	  -I/usr/share/verilator/include/vltstd -I$(NODE_INC) \
	  $(BUILD)/Vboard__ALL.a $(BUILD)/libverilated.a -lpthread

$(BUILD)/$(FIRMWARE):
	mkdir -p $(BUILD)
	curl -sSL -o $@.tmp $(FIRMWARE_URL)
	echo "$(FIRMWARE_SHA256)  $@.tmp" | sha256sum -c - && mv $@.tmp $@

# The RP2040 B1 boot ROM (Raspberry Pi, BSD-3-Clause) as rp2040js ships it
$(BUILD)/bootrom.mjs:
	mkdir -p $(BUILD)
	curl -sSL -o $@.tmp $(BOOTROM_URL)
	echo "$(BOOTROM_SHA256)  $@.tmp" | sha256sum -c - && mv $@.tmp $@

node_modules: package.json
	npm install --no-audit --no-fund
	touch node_modules

clean:
	rm -rf $(BUILD) cosim.node node_modules

.PHONY: all clean

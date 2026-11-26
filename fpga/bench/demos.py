# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
"""The bench's demos: each loads one firmware image into the chip and sends
one known payload over one protocol, taken from a chip-level test that
sigrok already judges (test/test.py). The same code runs on the Pico under
MicroPython (pico_main.py) and against the RTL under cocotb
(sim/test_bench_sim.py), with the host driver unchanged in both.

Each function takes a Chip and load(name), which returns the firmware image
test/<name>.hex. What the recording must decode to is in run_bench.py.

At a 10 MHz chip clock and a 24 MHz analyser, the shortest pulse of each:
  uart  114,943 baud, a bit of 8.7 us: 208 samples
  spi   909 kHz SCK, high 0.5 us: 12 samples
  i2c   98 kHz SCL, a tick of 1.7 us: 40 samples
  nec   37.9 kHz carrier, high 13.2 us: 316 samples
  dmx   250 kbit/s, a bit of 4 us: 96 samples
"""

import protocol_emulator as pe
import more_protocols as more

# test_modbus_rtu: the request in the Modbus specification's example, read
# three holding registers from 0x006B of server 17.
MODBUS_REQUEST = (0x11, 0x03, (0x00, 0x6B, 0x00, 0x03))

# test_max7219: a MAX7219 display driver set up and given two digits.
MAX7219_WRITES = ((0x0C, 0x01), (0x09, 0xFF), (0x0A, 0x08), (0x0B, 0x07),
                  (0x01, 0x05), (0x08, 0x09))

# test_eeprom_24xx: a 24Cxx EEPROM at 0x50.
EEPROM_ADDRESS = 0x50

# test_nec_infrared.
NEC_ADDRESS, NEC_COMMAND = 0x04, 0x08

# test_dmx512.
DMX_PACKETS = ((0x00, 0xFF, 0x55, 0x81, 0x7E), (0x10, 0x20))


def uart(chip, load):
    """The Modbus RTU request on the UART transmitter, P0, 8N1."""
    server, function, payload = MODBUS_REQUEST
    frame = more.modbus_frame(server, function, payload)
    pe.UartTx(chip, load("uart_tx"), divisor=87).write(frame)
    return frame


def spi(chip, load):
    """The MAX7219 writes on the divider-timed SPI controller
    (spi_controller.hex), mode 0: P0 SCK, P1 MOSI, P2 MISO, P3 CS_N. The
    test sends them on spi_fast.hex, whose 5 MHz SCK is high for 100 ns,
    2.4 samples at 24 MHz; this controller with a half-period word of 1
    (as test_avr_isp sets it) takes 11 clocks a bit, SCK high for 5."""
    chip.stop()
    chip.load(load("spi_controller"))
    chip.configure(set_base=0, set_count=1, out_base=1, out_count=3, in_base=2)
    chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL, 3: pe.PUSH_PULL})
    chip.run()
    chip.push(1)
    read = []
    for register, value in MAX7219_WRITES:  # each its own selection
        chip.push(pe.rev8(register))
        chip.push(pe.rev8(value) | (1 << 8))  # bit 8: the last byte, CS_N rises
        read.append(chip.pop())
        read.append(chip.pop())
    return read


def i2c_write_word(byte, stop, restart=False):
    """A TX word of i2c.hex (Firmware.i2c_write_word)."""
    return pe.rev8(byte) | (1 << 8) | (int(stop) << 9) | (int(restart) << 10)


def i2c_read_word(last):
    """A TX word of i2c.hex that reads a byte (Firmware.i2c_read_word)."""
    return 0xFF | (int(last) << 8) | (int(last) << 9)


def i2c(chip, load):
    """test_eeprom_24xx's session on the divider-timed I2C controller
    (i2c.hex): P0 SDA, P1 SCL, open-drain, against an EEPROM at 0x50: a page
    write, a byte write, a read from the address they leave behind, and a
    read from an address of the host's choosing, which takes a repeated
    START. The test runs the bus at 555 kHz (CLKDIV 3); here it is
    standard mode, 98 kHz (CLKDIV 17), for the Pico's I2C target. Returns
    the controller's reports: bits 7:0 the byte as seen on the bus,
    bit-reversed; bit 8 the ACK slot, 0 = ACK."""
    chip.stop()
    chip.load(load("i2c"))
    chip.configure(out_base=0, out_count=1, set_base=0, set_count=1, in_base=0,
                   sideset_base=1, sideset_count=1, timeout_vector=pe.I2C_STUCK,
                   timeout=10000, clkdiv=17)
    chip.set_pin_modes({0: pe.OPEN_DRAIN, 1: pe.OPEN_DRAIN})
    chip.run()
    a = EEPROM_ADDRESS

    def transfer(words):
        reports = []
        for w in words:  # a report comes back for every word
            chip.push(w)
            reports.append(chip.pop())
        return reports

    def write_bytes(data):
        n = len(data)
        return [i2c_write_word(a << 1, False)] + [
            i2c_write_word(b, k == n - 1) for k, b in enumerate(data)]

    def read_bytes(pointer, n):
        return [i2c_write_word(a << 1, False),
                i2c_write_word(pointer, False, True),
                i2c_write_word((a << 1) | 1, False)] + [
                    i2c_read_word(k == n - 1) for k in range(n)]

    reports = transfer(write_bytes([0x10, 0xDE, 0xAD, 0xBE]))
    reports += transfer(write_bytes([0x0F, 0x55]))
    reports += transfer([i2c_write_word((a << 1) | 1, False)] +
                        [i2c_read_word(k == 2) for k in range(3)])
    reports += transfer(read_bytes(0x11, 2))
    return reports


def nec(chip, load):
    """NEC infrared with its 38 kHz carrier on P0, high = LED lit."""
    more.NecTx(chip, load("nec_tx")).send(NEC_ADDRESS, NEC_COMMAND)


def dmx(chip, load):
    """Two DMX512 packets on P0, each a break, a mark after break, the start
    code 0 and the slots, 8N2 at 250 kbit/s."""
    tx = more.DmxTx(chip, load("dmx_tx"))
    for slots in DMX_PACKETS:
        tx.send(list(slots))


PLAY = {"uart": uart, "spi": spi, "i2c": i2c, "nec": nec, "dmx": dmx}

# How long the protocol may still be on the wire after its function
# returns (the FIFOs drain, the NEC frame takes about 68 ms), in milliseconds.
TAIL_MS = {"uart": 20, "spi": 20, "i2c": 20, "nec": 150, "dmx": 20}

# The firmware each demo loads, to copy to the Pico.
IMAGES = {"uart": "uart_tx", "spi": "spi_controller", "i2c": "i2c",
          "nec": "nec_tx", "dmx": "dmx_tx"}

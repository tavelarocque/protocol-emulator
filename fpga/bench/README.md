# FPGA bench: the host side

Everything the Mac and the Pico need to put the chip's firmware on real wires and judge the result, ready before the parts arrive. The Pico runs the unchanged host driver against the bitstream on the Tang Nano 20K; a 24 MHz logic analyser records the eight protocol pins; `run_bench.py` decodes each recording with the sigrok decoder and options of the chip-level test the demo comes from, and compares it with what was sent, as that test does.

Status: not yet run on a board. The judging has been run on recordings made from cocotb simulations of the same demos (below), and nothing else.

| File | Runs on | What it is |
| --- | --- | --- |
| `pico_main.py` | Pico 2, MicroPython | clock, reset, the host port on PIO, one demo |
| `demos.py` | Pico 2 and CPython | the five demos: firmware, configuration, payload |
| `run_bench.py` | Mac | copies the files, captures, runs a demo, judges the capture |
| `sim/test_bench_sim.py`, `sim/Makefile` | Linux or Mac, cocotb | the judging run on simulated recordings, with no hardware |
| `captures/` | | recordings (`.sr`) and decoded output (`.txt`), gitignored |

## Wiring

The table in [`fpga/README.md`](../README.md) connects the Pico and the Tang Nano 20K. The bench adds the analyser, the I2C bus and nothing else.

| From | To | For |
| --- | --- | --- |
| analyser channel 0 to 7 (often labelled CH1 to CH8, or D0 to D7) | P0 to P7: Tang Nano pins 75, 42, 41, 48, 49, 86, 72, 71 | every demo |
| analyser GND | GND | every demo |
| 4.7 kOhm resistor | P0 (pin 75) to 3.3 V | the I2C demo's SDA pull-up |
| 4.7 kOhm resistor | P1 (pin 42) to 3.3 V | the I2C demo's SCL pull-up |
| Pico GP0 (I2C0 SDA) | P0 (pin 75) | the I2C demo's EEPROM |
| Pico GP1 (I2C0 SCL) | P1 (pin 42) | the I2C demo's EEPROM |

The pull-ups and the Pico's GP0 and GP1 can stay connected for the other demos: they drive P0 and P1 push-pull, which the resistors load by under 1 mA, and the Pico does not drive GP0 or GP1 outside the I2C demo. Keep the clock wire from GP7 to pin 77 short, with a ground wire beside it: a 10 MHz edge that rings on a long jumper can clock the chip twice. All three boards go to the Mac by USB.

## What to install on the Mac

    brew install openfpgaloader sigrok-cli
    python3 -m pip install mpremote

These names were checked against Homebrew's formulae and PyPI. `openfpgaloader` is a Homebrew formula (the command is `openFPGALoader`). `sigrok-cli` is a formula at version 0.7.2; it pulls in `libsigrok` 0.5.2, whose formula builds and installs the fx2lafw firmware the analyser needs, and `libsigrokdecode` 0.5.3, which has every decoder these demos use (`uart`, `modbus`, `spi`, `max7219`, `i2c`, `eeprom24xx`, `ir_nec`, `dmx512`). `mpremote` is on PyPI. `run_bench.py` needs only Python 3's standard library.

The Pico 2 needs MicroPython 1.26 or later (the RP2350 build from micropython.org): the I2C demo's EEPROM is `machine.I2CTarget`, which appeared in 1.26.

One correction to the obvious command: sigrok-cli 0.7.2 rejects `--channels D0-D7` ("Invalid channel 'D0'"), so `run_bench.py` lists them, `--channels D0,D1,D2,D3,D4,D5,D6,D7`.

## On the day

1. Put MicroPython on the Pico 2 (hold BOOTSEL, plug it in, copy the `.uf2` to the drive that appears). `mpremote exec "import machine; print(machine.freq())"` should print 150000000.
2. Plug in the analyser and run `sigrok-cli -d fx2lafw --show`. The first time, this loads the analyser's firmware; it should then list channels D0 to D7.
3. Get the bitstream that takes its clock from the Pico: the `fpga` CI run's artifact, or `fpga/build.sh` with the OSS CAD Suite.
4. Wire everything as above with the USB cables out, then plug in the Tang Nano 20K and load the bitstream into its SRAM: `openFPGALoader -b tangnano20k fpga/build/pe_tangnano20k.fs`. The chip waits in reset, its reset pin pulled low inside the FPGA, until the Pico lets it go.
5. `fpga/bench/run_bench.py --dry-run` prints every command it would run. Then `fpga/bench/run_bench.py uart` runs one demo. `pico_main.py` first reads back a register with a known reset value and stops with a message if the chip does not answer, which points at the bitstream, the clock, reset or the host port wiring.
6. `fpga/bench/run_bench.py` runs all five and prints PASS or FAIL for each. `--bitstream fpga/build/pe_tangnano20k.fs` loads the FPGA first, `--no-copy` skips copying to the Pico, `--port` names the Pico's serial port if mpremote finds the wrong one.
7. Look at a recording in PulseView, or judge it again: `fpga/bench/run_bench.py --judge fpga/bench/captures/nec.sr nec`.

For each demo `run_bench.py` starts a 6-second capture at 24 MHz, waits 1.5 s for the analyser to start, runs `pico_main.main("<demo>")` on the Pico with mpremote, and waits for the capture to end. `--seconds` and `--arm` change those two times. The capture goes to `captures/<demo>.sr`, and what the Pico printed, the decoders' output and the verdict to `captures/<demo>.txt`.

## The demos

Each sends the payload of a chip-level test in `test/test.py` and is judged by that test's decoder, options and assertion. Every one needs only the analyser, except the I2C demo, whose EEPROM is the Pico. At the bench's 10 MHz chip clock and the analyser's 24 MHz, the shortest pulse of each is 12 samples or more.

| Demo | Firmware | Test | Payload | Shortest pulse |
| --- | --- | --- | --- | --- |
| `uart` | `uart_tx`, P0 | `test_modbus_rtu` | Modbus RTU: read 3 holding registers from 0x006B of server 17, 114,943 baud | 8.7 us, 208 samples |
| `spi` | `spi_controller`, P0 to P3 | `test_max7219` | six MAX7219 register writes, 909 kHz SCK | 0.5 us, 12 samples |
| `i2c` | `i2c`, P0 and P1 | `test_eeprom_24xx` | 24Cxx EEPROM at 0x50: page write, byte write, current-address read, random read, 98 kHz | 1.7 us, 40 samples |
| `nec` | `nec_tx`, P0 | `test_nec_infrared` | NEC address 0x04, command 0x08, 38 kHz carrier | 13.2 us, 316 samples |
| `dmx` | `dmx_tx`, P0 | `test_dmx512` | two packets: slots 00 FF 55 81 7E, then 10 20 | 4 us, 96 samples |

What the recording must decode to, exactly:

| Demo | sigrok-cli decoder (`-P`) and `-A` | Must read |
| --- | --- | --- |
| `uart` | `uart:tx=tx:baudrate=114943,modbus`, `-A modbus` | `Slave ID: 17`, `Function 3: Read Holding Registers`, `Start at address 0x6B / 30108`, `Read 3 units of data`, `CRC correct`, and nothing else |
| `spi` | `spi:clk=sck:mosi=mosi:cs=cs,max7219`, `-A max7219` | `Shutdown: off`, `Decode: 0b11111111`, `Intensity: 8`, `Scan limit: 8`, `Digit 1: 05`, `Digit 8: 09`, and nothing else |
| `i2c` | `i2c,eeprom24xx`, `-A eeprom24xx`; and `i2c` | of the texts naming an address: `Page write (addr=10, 3 bytes): DE AD BE`, `Byte write (addr=0F, 1 byte): 55`, `Sequential random read (addr=11, 2 bytes): AD BE`; on the bus, one `Start repeat` and four `Stop` |
| `nec` | `ir_nec:polarity=active-high:cd_freq=38000` | of the texts with `: 0x`: `Address: 0x04`, `Address#: 0xFB`, `Command: 0x08`, `Command#: 0xF7` |
| `dmx` | `dmx512`, each packet alone from its break (a low of 92 us or more) | for each packet, `Break` and `MAB` first, the slot values 0 (the start code) then the payload, and no text containing `nvalid` |

**UART.** The UART transmitter is the chip's simplest program, so it is the first thing to try. The payload is the request printed in the Modbus specification, CRC included, so sigrok's Modbus decoder checks every bit of every byte through the CRC. The decoder is told the baud rate and does not measure it, so the chip's clock is checked too.

**SPI.** The MAX7219 decoder reads only MOSI, SCK and CS, so the demo needs no device. The test sends these writes on `spi_fast`, whose 5 MHz SCK is high for 100 ns, 2.4 samples at 24 MHz, too short to record cleanly; the demo sends the same writes on the divider-timed `spi_controller` at a half-period word of 1, as `test_avr_isp` runs it, which gives SCK high for 5 clocks and low for 6. Each write is its own selection, so the decoder also sees CS rise after every 16 bits.

**I2C.** The chip is the controller and the Pico is the EEPROM: `pico_main.py` makes I2C0 a target at 0x50 with 256 bytes of memory, which takes the first byte of a write as the address and counts on from it, as a 24Cxx does. sigrok's EEPROM decoder only names a transfer the device ACKed, so without the Pico every transfer is NACKed and the demo fails. The test runs the bus at 555 kHz; the demo runs it at standard mode, 98 kHz (CLKDIV 17), for the Pico. The I2C controller has no class in the host driver (the test configures it register by register), so `demos.py` does the same with `Chip.configure`. The Pico prints the ACK slot of every byte and the four bytes its memory holds at 0x0F, which should be `55 de ad be`.

**NEC infrared.** The 38 kHz carrier is recorded as the LED's drive, and the decoder takes it out itself (`cd_freq=38000`), checking every mark and space to 5% and each byte against its complement. The frame takes about 68 ms.

**DMX512.** The unusual one: a UART stream framed by time rather than by bytes. Each packet begins with a break, the line held low for at least 92 us, then a mark after break, then the start code and the slots in 8N2 at 250 kbit/s. sigrok's decoder checks the break, the mark and both stop bits of every slot, so this shows the chip's timing as well as its bits. The decoder looks for a second break only after 512 slots, so, as in the test, each packet is decoded alone, from its break.

CAN was left out because a transmitter needs a second node to acknowledge every frame; without one it sends the first frame again after each error until the driver gives up.

## How a recording is judged

The analyser's channel D*k* is the chip's pin P*k*. `run_bench.py` turns the capture into the trace the chip-level test records: only the test's signals, under the test's names and in its order (sigrok-cli gives a decoder named without channel options the channels in order; the I2C decoder reads SCL first), cut to the span in which they change, from 1 ms before the first change to 10 ms after the last. sigrok-cli decodes that with the test's decoder argument, unchanged, `--protocol-decoder-samplenum` and the test's `-A`; its lines are read with the pattern `test/sigrok.py` uses, and compared as the test compares them. The sample numbers in the `.txt` file are those of the cut recording.

## The judging, with no hardware

`sim/test_bench_sim.py` runs each demo's code from `demos.py` against the RTL on the chip-level testbench (`test/tb.v`, `test/Makefile`), through the host driver's `BitBangPort` as `test/test.py` does. It records P0 to P7 as the analyser sees them (a pin the chip does not drive reads high, as the FPGA's pull-up holds it; for I2C the bus wires, with cocotbext-i2c's memory as the EEPROM), resamples the recording to 24 MHz as the analyser would sample the wires, and writes it as a sigrok session file in `captures/sim/`. It then reads that file back through `run_bench.py`'s own reading, cutting and judging, which must pass; plants the fault the chip-level test plants on the wire (scaled to 24 MHz samples) and judges again, which must fail.

    make -C fpga/bench/sim                                   # all five, about 90 s
    make -C fpga/bench/sim COCOTB_TEST_FILTER=test_bench_uart

| Demo | Recording judged | Fault planted | Judged with the fault |
| --- | --- | --- | --- |
| `uart` | PASS | TX held high for one data bit of the register count | FAIL: `Read 1027 units of data`, `CRC should be 116 71` |
| `spi` | PASS | MOSI held high through the last write | FAIL: `Unknown register FF` for `Digit 8: 09` |
| `i2c` | PASS | SDA held low through the first data byte | FAIL: `Page write (addr=10, 3 bytes): 00 AD BE` |
| `nec` | PASS | the carrier blanked for 900 us at the command byte | FAIL: `Address#: 0x7B`, `Command: 0xC2`, no `Command#` |
| `dmx` | PASS | the first stop bit of the last packet's start code held low | FAIL: `Invalid stop bit` |

This shows that the bench's judging is the tests' judging, on a recording sampled as the analyser samples. It does not show what the hardware will do.

## Not checked without hardware

- That sigrok-cli and the fx2lafw firmware keep up with 24 MHz on 8 channels for 6 s on the Mac's USB without losing samples, and that 1.5 s is long enough for the capture to start.
- That MicroPython's PWM gives exactly 10 MHz on GP7 at the Pico 2's 150 MHz. This is from reading `ports/rp2/machine_pwm.c` (a divider of 1, 15 cycles a period); `pico_main.py` prints the frequency the PWM reports and warns if it is not 10 MHz.
- That the clock survives the jumper wire, and that the FPGA's input synchronisers see the host port at the PIO's 10 MHz pace (5 chip clocks a phase).
- That `machine.I2CTarget` on the RP2350 answers as the cocotbext memory does, at 98 kHz.
- `pico_main.py` and `demos.py` under MicroPython: they were read for MicroPython's language, not run on it. `demos.py` runs under CPython in the simulation.

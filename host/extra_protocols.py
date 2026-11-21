# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Drivers for step-and-direction motor drivers, AM2302 / DHT22 and DHT11
# sensors, TDM audio, the TLC5620 DAC, and the codes sent as a stream of
# levels at a fixed rate: Qi packets, EM4100 tags and Morse. Each takes a
# Chip from protocol_emulator.py and a firmware image, as the drivers there
# do.
#
# A third module for the same reason more_protocols.py is a second: the
# Pico's memory. Copy the files you use to the board.

import protocol_emulator as pe


class Stepper:
    """Step and direction (stepper.hex) for a stepper motor driver: STEP
    on pin 0, DIR on pin 1. A tick is [tick_us]; STEP is high for two
    ticks of each step's period."""

    def __init__(self, chip, image, tick_us=1, clock_hz=10_000_000):
        self.chip = chip
        self.position = 0
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=1, out_base=1, out_count=1,
                       threshold=16, out_msb_first=True,
                       clkdiv=clock_hz * tick_us // 1_000_000)
        chip.run()  # STEP is low from the program's first instruction
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL})

    @staticmethod
    def words(steps, period):
        """The TX words for a move of [steps] (negative: backwards; up to
        32768 either way) at [period] ticks a step, 4 or more."""
        if steps == 0 or abs(steps) > 32768 or not 4 <= period <= 65539:
            raise ValueError("steps or period out of range")
        return [(0x8000 if steps > 0 else 0) | (abs(steps) - 1), period - 4]

    def move(self, steps, period):
        """Make [steps] steps at [period] ticks each, and return when the
        last has been made. [position] counts them."""
        for w in self.words(steps, period):
            self.chip.push(w)
        self.chip.pop()
        self.position += steps

    def ramp(self, moves):
        """[(steps, period), ...] one after another, as for speeding up
        and slowing down: the words of the next move are in the FIFO
        before the one under way ends, so there is no pause between them
        beyond six ticks."""
        waiting = 0
        for steps, period in moves:
            for w in self.words(steps, period):
                self.chip.push(w)
            waiting += 1
            if self.chip.try_pop() is not None:
                waiting -= 1
            self.position += steps
        for _ in range(waiting):
            self.chip.pop()


class DhtError(Exception):
    pass


class Dht:
    """AM2302 / DHT22 or DHT11 humidity and temperature sensor (dht.hex)
    on pin 0, open-drain, with the sensor's pull-up."""

    FAIL = 19  # where the firmware goes when the sensor stops answering

    def __init__(self, chip, image, dht11=False, clock_hz=10_000_000):
        self.chip = chip
        self.dht11 = dht11
        chip.stop()
        chip.load(image)
        # A tick is 5 us; a level that lasts 300 us ends a reading.
        chip.configure(set_base=0, set_count=1, in_base=0, threshold=16,
                       in_msb_first=True, auto=2, timeout=60, timeout_vector=self.FAIL,
                       clkdiv=clock_hz // 200_000)
        chip.set_pin_modes({0: pe.OPEN_DRAIN})
        chip.run()

    @staticmethod
    def decode(words, dht11=False):
        """(relative humidity in percent, temperature in degrees Celsius)
        from the four words of a reading."""
        humidity, temperature, checksum, stopped = words
        if stopped:
            raise DhtError("the sensor stopped answering")
        total = (humidity >> 8) + (humidity & 0xFF) + (temperature >> 8) + (temperature & 0xFF)
        if total & 0xFF != checksum:
            raise DhtError("checksum")
        if dht11:  # whole numbers, then tenths
            return ((humidity >> 8) + (humidity & 0xFF) / 10,
                    (temperature >> 8) + (temperature & 0xFF) / 10)
        t = (temperature & 0x7FFF) / 10
        return humidity / 10, -t if temperature & 0x8000 else t

    def read(self):
        """Take a reading. The sensors want two seconds between readings."""
        # The start: the line low for 1.3 ms, or 20 ms for a DHT11, in units
        # of 40 us, less one.
        self.chip.push(499 if self.dht11 else 32)
        return self.decode([self.chip.pop() for _ in range(4)], self.dht11)


class Bitstream:
    """A stream of levels at an exact rate (bitstream.hex) on pin 0: each
    cell is the pin's level for two ticks of [clkdiv] clock cycles. The
    line is low before the first cell, and holds its level whenever the
    host has no more."""

    def __init__(self, chip, image, clkdiv):
        if not 1 <= clkdiv <= 65535:
            raise ValueError("a cell of %d clock cycles is out of range" % (2 * clkdiv))
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(threshold=16, out_msb_first=True, auto=1, clkdiv=clkdiv)
        chip.run()
        while chip.status()["pc"] == 0:  # the program's first instruction puts the line low
            pass
        chip.set_pin_modes({0: pe.PUSH_PULL})

    def send_cells(self, cells, rest=0):
        """Send [cells] (0s and 1s), sixteen to a word; the last word is
        filled out with [rest], the level the line is left at."""
        cells = list(cells)
        cells += [rest] * (-len(cells) % 16)
        for i in range(0, len(cells), 16):
            w = 0
            for c in cells[i:i + 16]:
                w = (w << 1) | c
            self.chip.push(w)


    def flush(self):
        """Return once the firmware has taken every word: sixteen cells or
        fewer are still to go."""
        while self.chip.status()["tx_level"]:
            pass


class Qi(Bitstream):
    """Qi packets as a power receiver sends them to a charger: the signal
    that switches its modulation load, 2 kbit/s."""

    def __init__(self, chip, image, clock_hz=10_000_000):
        super().__init__(chip, image, (clock_hz + 4000) // 8000)  # a cell is 250 us

    @staticmethod
    def length(header):
        """How many bytes of message go with [header]."""
        if header < 0x20:
            return 1
        if header < 0x80:
            return 2 + (header - 32) // 16
        if header < 0xE0:
            return 8 + (header - 128) // 8
        return 20 + (header - 224) // 4

    @staticmethod
    def cells(header, message, preamble=11):
        """A packet, two cells to a bit: the line changes at the start of
        every bit, and in the middle of a 1. [preamble] ones (11 to 25),
        then each byte as a start bit 0, eight bits least significant
        first, odd parity and a stop bit 1: the header, the message and
        their checksum. After the stop bit the line changes once more,
        rests two bit times, and ends low."""
        if len(message) != Qi.length(header):
            raise ValueError("a message of %d bytes goes with this header" % Qi.length(header))
        packet = [header] + list(message)
        checksum = 0
        for b in packet:
            checksum ^= b
        bits = [1] * preamble
        for b in packet + [checksum]:
            data = [(b >> k) & 1 for k in range(8)]
            bits += [0] + data + [1 ^ (sum(data) & 1), 1]
        level, cells = 0, []
        for b in bits:
            first = 1 - level
            level = 1 - first if b else first
            cells += [first, level]
        return cells + [1 - level] * 4 + [0] * 8

    def send(self, header, message):
        self.send_cells(self.cells(header, message))


class Em4100(Bitstream):
    """An EM4100 RFID tag's answer, as the signal that switches a tag's
    load: 64 bits, Manchester coded, each 64 periods of the reader's
    field."""

    def __init__(self, chip, image, field_hz=125_000, clock_hz=10_000_000):
        # A cell is 32 periods of the field.
        super().__init__(chip, image, (16 * clock_hz + field_hz // 2) // field_hz)

    @staticmethod
    def bits(version, number):
        """Nine ones; the 8-bit version and the 32-bit number as ten groups
        of four bits, each followed by its even parity; four column
        parities; a stop bit 0."""
        nibbles = [(version >> 4) & 15, version & 15]
        nibbles += [(number >> k) & 15 for k in range(28, -1, -4)]
        bits = [1] * 9
        for n in nibbles:
            row = [(n >> k) & 1 for k in range(3, -1, -1)]
            bits += row + [sum(row) & 1]
        for k in range(3, -1, -1):
            bits.append(sum((n >> k) & 1 for n in nibbles) & 1)
        return bits + [0]

    def send(self, version, number, repeats=1):
        """The tag's 64 bits, [repeats] times over with no gap, as a tag
        repeats them for as long as it is in the field. A 1 is high then
        low. The line is low again after the last."""
        cells = []
        for b in self.bits(version, number):
            cells += [1, 0] if b else [0, 1]
        for _ in range(repeats):
            self.send_cells(cells)  # 128 cells: whole words
        self.send_cells([0])


MORSE = {
    "a": ".-", "b": "-...", "c": "-.-.", "d": "-..", "e": ".", "f": "..-.", "g": "--.",
    "h": "....", "i": "..", "j": ".---", "k": "-.-", "l": ".-..", "m": "--", "n": "-.",
    "o": "---", "p": ".--.", "q": "--.-", "r": ".-.", "s": "...", "t": "-", "u": "..-",
    "v": "...-", "w": ".--", "x": "-..-", "y": "-.--", "z": "--..", "0": "-----",
    "1": ".----", "2": "..---", "3": "...--", "4": "....-", "5": ".....", "6": "-....",
    "7": "--...", "8": "---..", "9": "----.",
}


class Morse(Bitstream):
    """Morse code, keyed on pin 0: a dot is [unit_ms] long (60 ms is 20
    words a minute)."""

    def __init__(self, chip, image, unit_ms=60, clock_hz=10_000_000):
        # A cell can be 131070 clock cycles at most: a dot is as many
        # cells as it takes.
        cycles = clock_hz * int(unit_ms * 1000 + 0.5) // 1_000_000
        self.repeat = (cycles + 131069) // 131070
        super().__init__(chip, image, cycles // (2 * self.repeat))

    @staticmethod
    def cells(text):
        """One unit to a dot: a dash is three, the gap inside a letter
        one, between letters three and between words seven; seven end the
        text."""
        cells = []
        for word in text.lower().split():
            for letter in word:
                for mark in MORSE[letter]:
                    cells += ([1, 1, 1] if mark == "-" else [1]) + [0]
                cells += [0, 0]
            cells += [0, 0, 0, 0]
        return cells

    def send(self, text):
        self.send_cells([c for c in self.cells(text) for _ in range(self.repeat)])


class TdmTx:
    """TDM audio sender (tdm_tx.hex): BCLK on pin 0, FSYNC on pin 1, DATA
    on pin 2; [slots] 16-bit samples to a frame. FSYNC is high for the
    one bit before each frame's first. BCLK is the clock over 4 x clkdiv."""

    def __init__(self, chip, image, slots, clkdiv=0):
        self.chip = chip
        self.slots = slots
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=2, out_base=2, out_count=1,
                       threshold=16, out_msb_first=True, clkdiv=clkdiv)
        chip.run()  # BCLK and FSYNC are low from the program's first instruction
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL, 2: pe.PUSH_PULL})
        chip.push(slots - 1)

    def write(self, frames):
        """[frames]: lists of [slots] samples. The clock pauses, low,
        whenever the host has no more."""
        for frame in frames:
            if len(frame) != self.slots:
                raise ValueError("a frame is %d samples" % self.slots)
            for sample in frame:
                self.chip.push(sample & 0xFFFF)


class Tlc5620:
    """TLC5620 quad 8-bit DAC (tlc5620.hex): CLK on pin 0, DATA on pin 1,
    LOAD on pin 2, LDAC on pin 3. A tick must be 100 ns or more: the
    default clkdiv is right up to 50 MHz."""

    def __init__(self, chip, image, clkdiv=5):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=1, out_base=1, out_count=1,
                       set_base=2, set_count=2, threshold=16, out_msb_first=True,
                       clkdiv=clkdiv)
        chip.run()
        while chip.status()["pc"] == 0:  # LOAD and LDAC are high after the first instruction
            pass
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL, 2: pe.PUSH_PULL, 3: pe.PUSH_PULL})

    def write(self, dac, value, double=False, update=True):
        """Put [value] (0 to 255) in DAC [dac] (0 to 3)'s latch; [double]
        doubles its output range. With [update] the four outputs take
        their latches' values after it; without, they wait for a write
        that has it, and then change together."""
        if not (0 <= dac <= 3 and 0 <= value <= 255):
            raise ValueError("dac or value out of range")
        self.chip.push((dac << 14) | (int(double) << 13) | (value << 5) | (int(update) << 4))

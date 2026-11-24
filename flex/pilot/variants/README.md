# Two builds of the kit, each without one feature

`no_sideset/` is the chip without side-set. `no_delay/` is the chip without
the per-instruction delay field. Each folder holds three files: `isa.md`
(docs/isa.md edited to describe that chip), `pe_sim.real` (the built
`pe_sim.exe`, byte for byte) and `pe_sim` (a Python 3 wrapper, standard
library only). The two wrappers are one file that differs in a single line,
`FEATURE = "sideset"` or `FEATURE = "delay"`.

## What the wrapper does with a command line

It reads the command line the way pe_sim.real does (subcommand and flag
names may be shortened to any unambiguous prefix, flags may come before or
after the program). Anything that is not an `asm` or a `run` that would get
as far as assembling a program goes to pe_sim.real untouched: `-help`,
`help`, `version`, an unknown or repeated flag, a missing argument, a
program file that cannot be read. So help text, error messages and exit
statuses are the real ones.

For an `asm` or a `run` it copies the program to a temporary file, checks
that copy, and then runs pe_sim.real on the same copy with the caller's
other arguments, so what was checked is what runs. A refusal is one line on
stderr, `pe_sim: refused: this build has no <feature>: <where>`, and exit
status 2. A program that does not assemble is passed through, and
pe_sim.real reports the error.

## The bits it inspects

The word is `[15:13]` op, `[12:9]` a 4-bit field, `[8:0]` operands. With
side-set width n (0 to 3), the top n bits of the field, word bits
`[12 : 13-n]`, are side-set values, and the low 4-n bits, word bits
`[12-n : 9]`, are delay.

The word does not hold n, and that is the one thing that could not be done
from the words alone: `nop side 1` under `.side_set 1` and `nop [8]` are
the same word, f000. The width comes from two places, and the wrapper asks
pe_sim.real for both instead of reading the program for keywords.

- **Declared width** (what the assembler packed, from `.side_set n`). The
  program is assembled once more with the line `nop side 7` added at the
  end. The assembler's answer names n: "side without .side_set" is 0, "side
  value 7 does not fit in N bits" is 1 or 2, no error is 3. A program of
  exactly 256 words has no room for that line; only then is the directive
  read from the source, by the assembler's own rule (a line that, after its
  comment is cut, is the two tokens `.side_set` and a number; the last one
  stands).
- **Configured width** (what the thread unpacks, from `sideset_count`).
  pe_sim.real runs two `nop`s for two cycles with the caller's `-config`,
  followed by `start=0,clkdiv=0,sideset_base=0`, and all eight pins
  push-pull. The pins it drives low are the side-set pins, and their number
  is the width. So the config string is read by pe_sim.real itself (hex,
  `+1`, `1_0`, repeated keys, spaces), not by a copy of its parser.

### no_sideset

- `run` is refused if the configured width is above zero. This is the rule
  that removes the feature: a thread only applies side-set with
  `sideset_count` above zero.
- `asm` and `run` are refused if the declared width is above zero. The
  message names the `.side_set` line and the word bits it claims, for
  example `line 22: ".side_set 1" puts side-set values in bit 12 of every
  word (word 0 = c084)`.
- A program with no `.side_set` keeps all four bits `[12:9]` as delay, as
  before.

### no_delay

- `asm` and `run` are refused if any word has a nonzero bit in `[12-n : 9]`,
  with n the declared width. With no `.side_set` that is all of `[12:9]`.
  The message names the word and its source line, for example
  `word 4 = c200 (line 20: "set pins, 0 [1]") has delay 1`.
- `run` is also refused if any word has a nonzero bit in `[12-c : 9]`, with
  c the configured width. Without this, a program written with
  `.side_set 1` and run with `sideset_count=0` would have its side-set
  values read as delays of 8 cycles.
- The model accepts widths beyond the documented 0 to 3. A configured
  width of 4 leaves no delay bits. For 5 and above the model's shifts are
  out of range, and the wrapper treats all four bits as delay.

## Counts on the 38 examples (`pe_sim asm examples/*.s`)

| Build | Accepted | Refused |
|---|---|---|
| no_sideset | 19 | 19 |
| no_delay | 15 | 23 |

no_sideset refuses dali_tx, i2c, i2c_target, i2s_tx, ir_tx, jtag, mdio,
microwire, nec_tx, nes_pad, ps2_rx, pwm, rc5_tx, spi_fast, stepper, swd,
tdm_tx, tlc5620 and usb. Those are the 19 files with a `.side_set` line;
in each, every instruction carries `side V`. The other 19 have neither.

no_delay accepts bitstream, dali_rx, echo, i2c_controller, i2c_target,
mdio, ps2_rx, pwm, rc5_rx, spi_controller, spi_fast, spi_target, stepper,
uart_rx and wiegand_rx. Those are the 15 files with no `[n]` on any
instruction. The other 23 have between 1 and 23 such lines, all with n from
1 to 15. Every accepted program's words are identical to pe_sim.real's.
None was a doubtful case.

## Other checks

- 71 command lines (help in every form, prefixes, bad flags, bad configs,
  missing files, a program on stdin, CRLF, empty and 256-word programs):
  stdout, stderr and exit status identical to pe_sim.real under both
  wrappers.
- 73 targeted accept and refuse cases (hex and signed `.side_set`, a
  directive overridden by `.side_set 0`, comments that mention the feature,
  `.align` fill, config spellings, mismatched widths): all as intended.
- `run` output identical to pe_sim.real, byte for byte, with real
  arguments: under no_sideset for uart_tx, spi_controller, bitstream,
  i2c_controller, echo and onewire; under no_delay for spi_fast, pwm,
  stepper, mdio, echo, spi_controller and i2c_controller.
- A broken pipe and a `timeout` end the wrapper as they end pe_sim.real,
  and no temporary file is left.

The test scripts are in `../variants_test/` (`difftest.py`,
`refusetest.py`, `runtest.py`, and `edit_isa.py`, which makes both `isa.md`
files from docs/isa.md by exact replacements).

## The UART example in no_delay/isa.md

docs/isa.md has no listing for it, only "a complete 8N1 transmitter in 15
instructions" and the host words. That firmware (examples/uart_tx.s) has
one delay, `set pins, 0 [1]` on the start bit. Without the field the cycle
costs a `nop`, so the document now says 16 instructions and nothing else in
the example changes. This is the program that was checked: it is accepted
by `no_delay/pe_sim`, and its output is identical to uart_tx.s on the real
binary for divisors 4, 5, 10, 16, 87 and 104, five bytes each.

```
        set pins, 1         ; line idles high
        pull                ; OSR <- divisor - 4
        mov y, osr          ; Y = per-bit loop count
next:   pull                ; wait for a byte; line stays high meanwhile
        set pins, 0         ; start bit
        nop                 ; the cycle the delay field gave
        mov x, y
start:  jmp x-- start
bit:    out pins, 1         ; data bit, LSB first
        mov x, y
hold:   jmp x-- hold
        jmp !osre bit       ; until all 8 bits are out
        set pins, 1         ; stop bit
        mov x, y
stop:   jmp x-- stop
        jmp next
```

## What is not closed

The wrapper stands in front of pe_sim.real; it does not replace it. Anyone
who runs `pe_sim.real` directly gets the whole chip.

The removed behaviour can still be had from instructions that stay:

- Without side-set: `out pins, n` and `mov pins` write `out_count` pins at
  once and `set pins` writes up to five, so one instruction can move a
  clock pin and a data pin in the same cycle. With autopull and the clock
  levels packed into the TX words beside the data, a clock edge again costs
  no instruction of its own; it costs FIFO words instead.
- Without delay: a `nop` per idle cycle; a `jmp x--` loop (n + 1 cycles);
  `clkdiv`, which stretches every instruction alike; and
  `wait ... timeout` on a pin that will not change, which idles for
  `timeout` cycles in one instruction and then jumps to `timeout_vector`.

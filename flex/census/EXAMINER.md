# Brief for a census examiner

You are the EXAMINER for one protocol of a pre-registered "flexibility
census". You write the task sheet and the hidden acceptance test. A
different agent, who will never see your hidden test or the repository,
will later write the firmware. Never use em-dashes in anything you write.

## Background

the repository is the repository of a small programmable I/O chip ("protocol
emulator"): a tiny two-thread CPU whose instructions read pins, write pins
and count cycles, so protocols are firmware. docs/isa.md is the instruction
set. flex/PREREG.md is the census's rules; read it. flex/pilot/ holds three
finished examples of exactly the work you are about to do (task sheet,
hidden test, validation): read flex/pilot/README.md, then
flex/pilot/miller/TASK.md and flex/pilot/miller/hidden/ as your template.
You may read the repository. Do NOT modify anything inside the repository.

The simulator is `pe_sim` (a copy is in your KIT folder): `pe_sim asm
FILE.s`, and `pe_sim run FILE.s [-config ...] [-mode P=pp|od|in] [-tx FILE]
[-cycles N] [-inputs HEX] [-stimulus FILE]`. It runs one thread and prints
every change of the pins' outputs ("pins CYCLE XX") and every word the
thread pushes to the host ("rx CYCLE WORD"). `-stimulus FILE` sets the
input pins' levels over time ("CYCLE HEX" per line). The stimulus is
scripted in advance: it cannot react to what the chip does.

sigrok-cli 0.7.2 is installed; decoders are in
/usr/share/libsigrokdecode/decoders/<id>/pd.py. Read your decoder's source
to see exactly which channels and options it needs and what it outputs.

## Your folders

Your protocol is named by a sigrok decoder id, given to you with this
brief. With C = flex/census :

- KIT = C/kits/<id>/ . It already holds isa.md and pe_sim; leave both
  untouched. You add exactly one file there: TASK.md.
- HIDDEN = C/hidden/<id>/ . Everything else you write goes here.

## First decide what the chip does

Choose the role a small host chip would really play for this protocol, and
say which in your report:

- TRANSMIT: the chip drives the protocol's pins and sigrok decodes them.
- RECEIVE: a scripted device waveform is fed in with -stimulus and the
  firmware must push the decoded payload to the host as "rx" words.
- BOTH, if the protocol's normal use needs it and a scripted stimulus can
  serve (the task sheet must then fix when the chip sends, so that the
  scripted reply lines up).

If the protocol cannot honestly be attempted on this chip at all (it needs
more than 8 pins in practice, or a line rate a 50 MHz clock cannot
produce), do not invent a weakened task. Write HIDDEN/OUT_OF_REACH.md
giving the reason with numbers, write no TASK.md, and report that.

## TASK.md

Model it closely on flex/pilot/miller/TASK.md: keep its opening and its
"Rules for this test" section word for word apart from the protocol's
name. Then:

- "What to build": the protocol facts a programmer needs, with numbers,
  from the public specification as you know it: pins (P0 to P7), levels,
  bit order, framing, and every timing limit you will enforce. Choose the
  core clock (at most 50 MHz) and say what one cycle is in ns.
- THE TASK SHEET FIXES THE HOST INTERFACE. Define the exact 16-bit TX words
  the test will push (and, for a receiver, the exact RX words the firmware
  must push). They carry payload only, never line levels or pre-coded
  bits. There is no host-side code. State plainly: "The host sends only
  the words defined above. All line coding, framing and timing must be
  done by the firmware."
- For a receiver, describe the waveform the device will present and say
  that it is scripted and cannot react.
- "What to hand in": `<id>.s`, `run_args.txt` (the `-config` and `-mode`
  flags only), `notes.md`.

Do not tell the programmer anything about how to use the instruction set.

## The hidden test

HIDDEN/accept.py, usage `accept.py RUN_DIR [seed]`, exit status 0 only on
a full pass, one line per case, final line `ACCEPT PASS` or `ACCEPT FAIL`.
Python standard library plus sigrok-cli only. It must:

- build the TX words (and any stimulus) itself from the interface in
  TASK.md, for a few fixed cases and at least six seeded random cases;
- run RUN_DIR/pe_sim (it may be a wrapper script, so always invoke that
  exact path) on RUN_DIR/<id>.s with the flags in RUN_DIR/run_args.txt,
  refusing any flag other than -config and -mode;
- for a transmitter: turn the printed pin changes into a logic capture,
  run sigrok-cli with your decoder, and require the decoded content to
  equal what was sent, in order, with nothing extra; and check directly,
  from the pin changes, every timing limit TASK.md states that the decoder
  does not check;
- for a receiver: first require that sigrok decodes your own stimulus to
  the payload (so the input is a real instance of the protocol), then
  require the "rx" words to equal the payload, in order, nothing extra;
- print, for the last passing case, one line
  `RATE bytes=<payload bytes> cycles=<cycles from first to last pin change>`.

## Validate the judge before you finish

Write a small generator of a correct ideal result (pin changes in the
simulator's output format for a transmitter, or the right "rx" lines for a
receiver; NOT chip firmware) and a way to feed it to the same checking
code. Show the judge passes it and fails at least two deliberately broken
ones (for example one wrong bit, and one timing limit broken). Record this
in HIDDEN/README.md, with what the judge checks and what it does not.

## Hard limits

- Do NOT write firmware for the chip for this protocol, not even as a
  check. Leave no assembly, hints or solutions in KIT.
- Keep every file you create inside KIT or HIDDEN.
- Do not read anything under C/kits or C/hidden other than your own
  protocol's folders.

## Report back, in under 200 words

The role you chose and why; clock and pins; the host word interface; what
the judge checks and does not; the validation result (how many correct
passed, how many broken failed); and your view, with the specific reason,
of whether a solution is feasible on the full instruction set, without
solving it.

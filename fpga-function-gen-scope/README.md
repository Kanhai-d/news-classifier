# FPGA Function Generator and Digital Oscilloscope (ZedBoard)

A basic function generator and a basic digital oscilloscope made fully inside the FPGA.
No extra hardware is needed. You only need the ZedBoard and a VGA monitor.

## What it does

* The function generator makes a sine, square, triangle or sawtooth wave.
* The scope reads that wave, waits for it to go up through the middle level,
  saves 512 samples and draws them on the VGA monitor.
* The 8 LEDs show the generator output.

## Controls

| Control | Function |
| --- | --- |
| SW1 SW0 | Wave: 00 sine, 01 square, 10 triangle, 11 sawtooth |
| SW4 SW3 SW2 | Frequency: 000 100 Hz, 001 200 Hz, 010 500 Hz, 011 1 kHz, 100 2 kHz, 101 5 kHz, 110 10 kHz, 111 20 kHz |
| SW6 SW5 | Time scale: 00 about 0.5 ms on screen, 01 2 ms, 10 8 ms, 11 33 ms |
| SW7 | Not used |
| BTNC (center button) | Reset |
| LD7 to LD0 | The 8 bit generator output |

Tip: for about two cycles on the screen, use 1 kHz with time scale 01, 100 Hz with time scale 11
(a bit over three cycles), or 10 kHz with time scale 00 (about five cycles).

## Folder map

| Folder | What is inside |
| --- | --- |
| `rtl/` | The Verilog design |
| `sim/` | The testbenches |
| `constraints/` | The ZedBoard pin file |
| `scripts/` | Build, simulation and helper scripts |
| `docs/` | Pictures made by the simulation |

### Verilog files

| File | Job |
| --- | --- |
| `top.v` | Connects everything. Makes the 1 MHz sample tick and the 25 MHz pixel tick. |
| `sync2.v` | Two flip flop synchronizer for the switches and the button. |
| `dds.v` | Phase counter and wave maker. |
| `sine_rom.v` | 256 entry sine table (made by `scripts/gen_sine_rom.py`). |
| `scope_capture.v` | The capture FSM: WAIT, CAPTURE, DONE. |
| `sample_ram.v` | 2 banks of 512 samples. One is written while the other is shown. |
| `vga_timing.v` | 640 by 480 at 60 Hz timing. |
| `vga_display.v` | Draws the grid and the trace. |

## How it works

* The generator adds a number (the frequency tuning word) to a 32 bit counter 1 million times a second.
  The top 8 bits of the counter make the wave.
  The output frequency is `ftw * 1 MHz / 2^32`.
* The capture FSM looks at the generator samples. A counter skips samples to change the time scale.
  When the wave crosses 128 going up, the FSM saves 512 samples.
  If no crossing is seen for a long time, it starts anyway so the screen never freezes.
* The FSM writes into one RAM bank. The screen reads the other bank.
  The banks swap once per screen frame, in the blank time, so the trace does not tear.
* The VGA pixel rate is 25 MHz. It is made with a clock enable on the 100 MHz clock, so the whole design uses one clock.

## Run the simulation

Install Icarus Verilog (`sudo apt install iverilog`) and run:

```
bash scripts/run_sim.sh
python3 scripts/ppm_to_png.py build/sim/frame_*.ppm
```

The tests are:

| Test | What it checks |
| --- | --- |
| `tb_dds` | Range and frequency of all four waves |
| `tb_capture` | Saved samples, time scale, bank swap and time out |
| `tb_vga_timing` | Line length, frame length and sync widths |
| `tb_top` | Full design. Saves a VGA frame and checks the trace is complete in all 512 columns |

The simulated screen for each wave is in `docs/` (for example `docs/sim_sine.png`).

## Build and run on the ZedBoard

1. Install Vivado (any recent version with Zynq-7000 support).
2. Check the pins in `constraints/zedboard.xdc` against the official ZedBoard master XDC.
3. Build: `vivado -mode batch -source scripts/build.tcl`
4. Connect the ZedBoard with the JTAG/PROG USB cable and a VGA monitor, then power it on.
5. Program: `vivado -mode batch -source scripts/program.tcl`
   (or use Hardware Manager in the Vivado window and pick `build/vivado/top.bit`).
6. Move the switches and watch the screen.

This design only uses the FPGA part (PL). The ARM processor is not used.

## Things to know

* The generator samples at 1 MHz, so the 20 kHz wave has 50 samples per cycle.
* The scope reads the generator inside the FPGA. It does not measure outside signals.
* The sim and the board show the same picture, but the board result has not been tested in this repository.
  The pin file was written from memory of the ZedBoard documents, so check it before use.

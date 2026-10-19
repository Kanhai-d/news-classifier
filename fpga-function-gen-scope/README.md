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
| SW7 | Slow mode: every frequency becomes 1000 times lower (100 Hz becomes 0.1 Hz), so you can watch the wave on the LEDs |
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
| `tb_top` | Full design. Saves a VGA frame, checks the trace is complete in all 512 columns, and checks the sample tick in normal and slow mode |

The simulated screen for each wave is in `docs/` (for example `docs/sim_sine.png`).

## Simulate in Vivado

1. Open Vivado. Pick Tools > Run Tcl Script and choose `scripts/create_project.tcl`.
   This makes the project `build/vivado_project/zed_scope.xpr` with all files added.
2. Click Run Simulation > Run Behavioral Simulation. The default test is `tb_top`.
   It runs to the end by itself (about 52 ms of sim time, so it can take a few minutes).
3. Read the result in the Tcl Console. It ends with `tb_top PASS`.
4. To run another test, right click it under Simulation Sources and pick Set as Top.
5. The picture `frame.ppm` is saved in `build/vivado_project/zed_scope.sim/sim_1/behav/xsim/`.

## Build and run on the ZedBoard

1. In the same project, click Generate Bitstream. Vivado runs synthesis and implementation first.
2. Set the ZedBoard boot jumpers (JP7 to JP11) to JTAG mode (all to GND). Check that the VADJ jumper J18 is on 1.8 V.
3. Connect the PROG micro USB port to the PC, connect a VGA monitor, and switch the board on.
4. Open Hardware Manager, click Open Target > Auto Connect, then Program Device and pick the bitstream.
5. Move the switches and watch the screen. Turn on SW7 to watch the wave slowly on the LEDs.

You can also build and program from a terminal:
`vivado -mode batch -source scripts/build.tcl` and then `vivado -mode batch -source scripts/program.tcl`.

This design only uses the FPGA part (PL). The ARM processor is not used, so no SDK or Vitis step is needed.

## Things to know

* The generator samples at 1 MHz, so the 20 kHz wave has 50 samples per cycle.
* The scope reads the generator inside the FPGA. It does not measure outside signals.
* The pins and IO standards in `constraints/zedboard.xdc` match Digilent's official Zedboard-Master.xdc.
* The design was checked in simulation and with a 7-series synthesis run (about 500 cells and 1 block RAM).
  It has not yet been run on a real board.
* The monitor gets a 25.0 MHz pixel clock instead of the exact 25.175 MHz. Almost all monitors accept this.

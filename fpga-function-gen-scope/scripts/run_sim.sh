#!/usr/bin/env bash
# Runs every testbench with Icarus Verilog (install it with: sudo apt install iverilog).
# Run from anywhere:  bash scripts/run_sim.sh
set -e
cd "$(dirname "$0")/.."
mkdir -p build/sim
RTL="rtl/sine_rom.v rtl/sync2.v rtl/dds.v rtl/spi_master16.v rtl/sample_ram.v rtl/scope_capture.v rtl/vga_timing.v rtl/vga_display.v rtl/top.v sim/pmod_models.v"
fail=0

for tb in tb_dds tb_spi tb_capture tb_vga_timing; do
    echo "=== $tb ==="
    iverilog -g2005 -Wall -Wno-timescale -o build/sim/$tb.vvp sim/$tb.v $RTL
    vvp -n build/sim/$tb.vvp | tee build/sim/$tb.log
    grep -q "PASS" build/sim/$tb.log || fail=1
done

# Full design. Four wave shapes from the generator (SW6 = 0), then the
# DA2 to AD1 loop (SW6 = 1). A picture is saved for each.
iverilog -g2005 -Wall -Wno-timescale -o build/sim/tb_top.vvp sim/tb_top.v $RTL
for cfg in "14:sine" "15:square" "16:triangle" "17:sawtooth" "54:ad1_sine" "55:ad1_square"; do
    sw=${cfg%%:*}; name=${cfg##*:}
    echo "=== tb_top ($name) ==="
    vvp -n build/sim/tb_top.vvp +SW=$sw +OUT=build/sim/frame_$name.ppm | tee build/sim/tb_top_$name.log
    grep -q "PASS" build/sim/tb_top_$name.log || fail=1
done

if [ $fail -eq 0 ]; then echo "ALL TESTS PASSED"; else echo "SOME TESTS FAILED"; exit 1; fi

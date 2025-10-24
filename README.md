# RISC-V LED Shell on Arty Z7

A compact RISC-V SoC demo with UART or JTAG console control of onboard LEDs.

## ✨ Features
- PicoRV32 softcore CPU
- 16 KB ROM + 16 KB RAM
- UART shell: `on`, `off`, `toggle`, `blink`, `status`
- Optional JTAG-UART (no external dongle)
- Full Vivado automation scripts

---

## 🧱 Build Firmware
```bash
cd fw
make
cp rom_init.mem ../src/

CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
CFLAGS = -Os -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding

firmware.elf: uart_shell_led.c
	$(CC) $(CFLAGS) -o $@ $<
	$(OBJCOPY) -O verilog $@ ../src/rom_init.mem

clean:
	rm -f firmware.elf ../src/rom_init.mem

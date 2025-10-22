#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#define UART_BASE 0x80000000
#define UART_TX     (*(volatile unsigned char*)(UART_BASE + 0))
#define UART_RX     (*(volatile unsigned char*)(UART_BASE + 1))
#define UART_STATUS (*(volatile unsigned char*)(UART_BASE + 2))

#define LED_BASE    0x90000000
#define LED_REG     (*(volatile unsigned char*)(LED_BASE + 0))

void uart_putc(char c) {
    while (UART_STATUS & (1<<1)); // wait tx_busy
    UART_TX = c;
}
char uart_getc() {
    while (!(UART_STATUS & 1));   // wait rx_ready
    char c = UART_RX;
    UART_RX = 0; // clear ready
    return c;
}
void uart_puts(const char *s) {
    while (*s) uart_putc(*s++);
}

void uart_getline(char *buf, int maxlen) {
    int idx = 0;
    while (1) {
        char c = uart_getc();
        if (c == '\r' || c == '\n') {
            uart_putc('\r'); uart_putc('\n');
            buf[idx] = '\0';
            return;
        } else if (c == 8 || c == 127) { // backspace
            if (idx > 0) {
                idx--;
                uart_puts("\b \b");
            }
        } else if (idx < maxlen - 1) {
            buf[idx++] = c;
            uart_putc(c);
        }
    }
}

// Utility
void print_binary(unsigned char v) {
    for (int i = 7; i >= 0; i--) uart_putc((v & (1<<i)) ? '1' : '0');
}

// Command handlers
void cmd_on(int n, unsigned char *leds) {
    if (n>=0 && n<8) *leds |= (1<<n);
    LED_REG = *leds;
}
void cmd_off(int n, unsigned char *leds) {
    if (n>=0 && n<8) *leds &= ~(1<<n);
    LED_REG = *leds;
}
void cmd_toggle(int n, unsigned char *leds) {
    if (n>=0 && n<8) *leds ^= (1<<n);
    LED_REG = *leds;
}
void cmd_blink(unsigned char *leds) {
    unsigned char old = *leds;
    LED_REG = 0xFF;
    for (volatile int i=0;i<300000;i++);
    LED_REG = 0x00;
    for (volatile int i=0;i<300000;i++);
    LED_REG = old;
}
void cmd_status(unsigned char leds) {
    uart_puts("LED state: ");
    print_binary(leds);
    uart_puts("\r\n");
}

void cmd_help() {
    uart_puts("Commands:\r\n");
    uart_puts("  on n      - turn LED n on\r\n");
    uart_puts("  off n     - turn LED n off\r\n");
    uart_puts("  toggle n  - toggle LED n\r\n");
    uart_puts("  blink     - blink all LEDs\r\n");
    uart_puts("  status    - show LED bits\r\n");
}

int main() {
    uart_puts("=== RISC-V LED Shell ===\r\n");
    uart_puts("Type 'help' for commands.\r\n");

    unsigned char leds = 0;
    LED_REG = leds;
    char line[64];

    while (1) {
        uart_puts("> ");
        uart_getline(line, sizeof(line));

        // parse command + optional argument
        char *cmd = strtok(line, " ");
        char *arg = strtok(NULL, " ");
        if (!cmd) continue;

        for (char *p = cmd; *p; ++p) *p = tolower(*p);

        if (!strcmp(cmd, "on")) {
            cmd_on(arg ? atoi(arg) : -1, &leds);
        } else if (!strcmp(cmd, "off")) {
            cmd_off(arg ? atoi(arg) : -1, &leds);
        } else if (!strcmp(cmd, "toggle")) {
            cmd_toggle(arg ? atoi(arg) : -1, &leds);
        } else if (!strcmp(cmd, "blink")) {
            cmd_blink(&leds);
        } else if (!strcmp(cmd, "status")) {
            cmd_status(leds);
        } else if (!strcmp(cmd, "help")) {
            cmd_help();
        } else {
            uart_puts("Unknown command. Type 'help'.\r\n");
        }
    }
}

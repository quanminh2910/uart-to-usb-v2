// uart_core.v — Full-duplex UART for 25 MHz clock & 115200 baud
// Memory-mapped interface:
//   write  -> transmit byte
//   read   -> read received byte (clears ready flag)
//   status -> bit[0]=rx_ready, bit[1]=tx_busy
module uart_core #(
    parameter CLK_FREQ = 25_000_000,
    parameter BAUD     = 115200
)(
    input  wire clk,
    input  wire rstn,

    // CPU interface (simplified)
    input  wire        cpu_wr,     // strobe: write TX reg
    input  wire [1:0]  cpu_addr,   // 0:TX, 1:RX, 2:STATUS
    input  wire [7:0]  cpu_wdata,
    output reg  [7:0]  cpu_rdata,
    output reg         cpu_ack,

    // UART lines
    output wire uart_tx,
    input  wire uart_rx
);

    // ----- Baud tick -----
    localparam integer BAUD_TICK = CLK_FREQ / BAUD;

    // ================================
    // TX logic
    // ================================
    reg [31:0] tx_cnt = 0;
    reg [9:0]  tx_shift = 10'h3FF;
    reg [3:0]  tx_bit = 0;
    reg        tx_busy = 0;
    reg        tx_reg  = 1'b1;
    assign uart_tx = tx_reg;

    always @(posedge clk) begin
        if (!rstn) begin
            tx_busy <= 0; tx_bit <= 0; tx_reg <= 1'b1;
            tx_cnt <= 0;  tx_shift <= 10'h3FF;
        end else begin
            if (tx_busy) begin
                if (tx_cnt >= BAUD_TICK-1) begin
                    tx_cnt <= 0;
                    tx_shift <= {1'b1, tx_shift[9:1]};
                    tx_reg <= tx_shift[0];
                    tx_bit <= tx_bit + 1;
                    if (tx_bit == 9) begin
                        tx_busy <= 0;
                        tx_bit <= 0;
                        tx_reg <= 1'b1;
                    end
                end else
                    tx_cnt <= tx_cnt + 1;
            end
            // start new transmission
            if (cpu_wr && cpu_addr==2'd0 && !tx_busy) begin
                tx_shift <= {1'b1, cpu_wdata, 1'b0};
                tx_busy <= 1; tx_cnt <= 0; tx_bit <= 0;
            end
        end
    end

    // ================================
    // RX logic
    // ================================
    reg [31:0] rx_cnt = 0;
    reg [3:0]  rx_bit = 0;
    reg [7:0]  rx_shift = 0;
    reg        rx_busy = 0;
    reg        rx_ready = 0;
    reg        rx_sample = 1'b1;
    reg [1:0]  rx_sync;

    always @(posedge clk) begin
        if (!rstn) begin
            rx_busy <= 0; rx_ready <= 0; rx_bit <= 0; rx_cnt <= 0;
            rx_sync <= 2'b11;
        end else begin
            rx_sync <= {rx_sync[0], uart_rx};
            if (!rx_busy) begin
                // detect start bit (falling edge)
                if (rx_sync == 2'b10) begin
                    rx_busy <= 1;
                    rx_cnt <= BAUD_TICK + (BAUD_TICK>>1); // 1.5 bit
                    rx_bit <= 0;
                end
            end else begin
                if (rx_cnt == 0) begin
                    rx_cnt <= BAUD_TICK - 1;
                    rx_shift <= {rx_sync[1], rx_shift[7:1]};
                    rx_bit <= rx_bit + 1;
                    if (rx_bit == 8) begin
                        rx_busy <= 0;
                        rx_ready <= 1;
                    end
                end else rx_cnt <= rx_cnt - 1;
            end

            // clear ready on CPU read
            if (cpu_wr && cpu_addr==2'd1)
                rx_ready <= 0;
        end
    end

    // ================================
    // CPU readback
    // ================================
    always @(*) begin
        cpu_rdata = 8'h00;
        case (cpu_addr)
            2'd1: cpu_rdata = rx_shift;
            2'd2: cpu_rdata = {6'b0, tx_busy, rx_ready};
        endcase
    end

    always @(posedge clk) cpu_ack <= cpu_wr; // simple strobe ack

endmodule

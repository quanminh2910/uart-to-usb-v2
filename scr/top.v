`timescale 1ns/1ps
module top(
    input  wire clk_100mhz,
    input  wire rst_btn,
    output wire uart_tx,
    input  wire uart_rx,
    output reg  [7:0] led
);
    wire rstn = ~rst_btn;
    reg [1:0] clkdiv=0;
    always @(posedge clk_100mhz) clkdiv<=clkdiv+1;
    wire clk = clkdiv[1];

    wire mem_valid, mem_ready;
    wire [31:0] mem_addr, mem_wdata, mem_rdata;
    wire [3:0] mem_wstrb;
    
    picorv32 #(.ENABLE_IRQ(0)) cpu(
        .clk(clk), .resetn(rstn),
        .mem_valid(mem_valid), .mem_ready(mem_ready),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb), .mem_rdata(mem_rdata)
    );

    reg [31:0] rom[0:4095]; initial $readmemh("rom_init.mem",rom);
    reg [31:0] ram[0:4095];

    reg [7:0] uart_wdata; reg uart_write; wire [7:0] uart_rdata;
    wire uart_tx_busy, uart_rx_ready;
    //
    wire [7:0] uart_rdata_from_core; 
    wire       uart_ack_from_core; 
    //

`ifdef USE_JTAG_UART
    jtag_uart UART(
        .clk(clk), .rstn(rstn),
        .cpu_wr(uart_write), .cpu_addr(mem_addr[1:0]),
        .cpu_wdata(uart_wdata), .cpu_rdata(uart_rdata_from_core),
        .cpu_ack(uart_ack_from_core), .uart_tx_unused(), .uart_rx_unused(1'b1)
    );
`else
    uart_core #(.CLK_FREQ(25_000_000), .BAUD(115200)) UART(
        .clk(clk), .rstn(rstn),
        .cpu_wr(uart_write), .cpu_addr(mem_addr[1:0]),
        .cpu_wdata(uart_wdata), .cpu_rdata(uart_rdata_from_core),
        .cpu_ack(uart_ack_from_core), .uart_tx(uart_tx), .uart_rx(uart_rx)
    );
`endif

    localparam ROM_BASE=32'h00000000, RAM_BASE=32'h10000000, UART_BASE=32'h80000000, LED_BASE=32'h90000000;
    reg [31:0] rdata; reg ready;
    always @(posedge clk) begin
        ready<=0; uart_write<=0;
        if(mem_valid) begin
            if(mem_addr>=ROM_BASE && mem_addr<ROM_BASE+16'h10000 && !mem_wstrb) begin
                rdata<=rom[mem_addr[13:2]]; ready<=1;
            end else if(mem_addr>=RAM_BASE && mem_addr<RAM_BASE+16'h10000) begin
                if(|mem_wstrb) begin
                    if(mem_wstrb[0]) ram[mem_addr[13:2]][7:0]<=mem_wdata[7:0];
                    if(mem_wstrb[1]) ram[mem_addr[13:2]][15:8]<=mem_wdata[15:8];
                    if(mem_wstrb[2]) ram[mem_addr[13:2]][23:16]<=mem_wdata[23:16];
                    if(mem_wstrb[3]) ram[mem_addr[13:2]][31:24]<=mem_wdata[31:24];
                end else rdata<=ram[mem_addr[13:2]];
                ready<=1;
            end else if(mem_addr[31:16]==UART_BASE[31:16]) begin
                if(|mem_wstrb) begin uart_wdata<=mem_wdata[7:0]; uart_write<=1; end
                rdata <= {24'b0, uart_rdata_from_core}; ready<=1;
            end else if(mem_addr[31:16]==LED_BASE[31:16]) begin
                if(|mem_wstrb) led<=mem_wdata[7:0];
                rdata<={24'b0,led}; ready<=1;
            end else begin rdata<=0; ready<=1; end
        end
    end
    assign mem_ready=ready; assign mem_rdata=rdata;
endmodule

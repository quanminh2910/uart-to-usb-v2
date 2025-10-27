module jtag_uart(
    input  wire clk,
    input  wire rstn,
    input  wire cpu_wr,
    input  wire [1:0] cpu_addr,
    input  wire [7:0] cpu_wdata,
    output reg  [7:0] cpu_rdata,
    output reg        cpu_ack,
    output wire uart_tx_unused,
    input  wire uart_rx_unused
);
    assign uart_tx_unused = 1'b1;
    reg [7:0] tx_fifo[0:15];
    reg [3:0] tx_wptr=0, tx_rptr=0;
    wire tx_empty=(tx_wptr==tx_rptr);

    wire tck, tdi, tdo, shift, update, sel, drck;
    reg [7:0] shreg; reg [2:0] bitcount; reg sending;

    BSCANE2 #(.JTAG_CHAIN(1)) bscan(
        .TCK(tck), .TDI(tdi), .TDO(tdo),
        .SHIFT(shift), .UPDATE(update),
        .SEL(sel), .DRCK(drck),
        .RUNTEST(), .CAPTURE(), .RESET(), .TMS()
    );

    always @(posedge clk) begin
        if(!rstn) begin tx_wptr<=0; tx_rptr<=0; cpu_ack<=0; end
        else begin
            cpu_ack<=0;
            if(cpu_wr && cpu_addr==2'd0) begin
                tx_fifo[tx_wptr]<=cpu_wdata;
                tx_wptr<=tx_wptr+1;
                cpu_ack<=1;
            end
            cpu_rdata<=8'h00;
        end
    end

    always @(posedge tck) begin
        if(sel && shift) begin
            if(!sending && (tx_wptr!=tx_rptr)) begin
                shreg<=tx_fifo[tx_rptr];
                tx_rptr<=tx_rptr+1;
                bitcount<=7; sending<=1;
            end else if(sending) begin
                shreg<={1'b0,shreg[7:1]};
                if(bitcount==0) sending<=0;
                else bitcount<=bitcount-1;
            end
        end
    end

    always @(*) begin
        cpu_rdata=8'h00;
        if(cpu_addr==2'd2) cpu_rdata={6'b0,1'b0,!tx_empty};
    end
endmodule

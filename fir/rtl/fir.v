`timescale 1ns / 1ps
module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
    output  wire                     awready,
    output  wire                     wready,
    input   wire                     awvalid,
    input   wire [(pADDR_WIDTH-1):0] awaddr,
    input   wire                     wvalid,
    input   wire [(pDATA_WIDTH-1):0] wdata,
    output  wire                     arready,
    input   wire                     rready,
    input   wire                     arvalid,
    input   wire [(pADDR_WIDTH-1):0] araddr,
    output  wire                     rvalid,
    output  wire [(pDATA_WIDTH-1):0] rdata,    
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast, 
    output  wire                     ss_tready, 
    input   wire                     sm_tready, 
    output  wire                     sm_tvalid, 
    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    output  wire                     sm_tlast, 
    
    // bram for tap RAM
    output  wire [3:0]               tap_WE,
    output  wire                     tap_EN,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    output  wire [(pADDR_WIDTH-1):0] tap_A,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,

    // bram for data RAM
    output  wire [3:0]               data_WE,
    output  wire                     data_EN,
    output  wire [(pDATA_WIDTH-1):0] data_Di,
    output  wire [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do,

    input   wire                     axis_clk,
    input   wire                     axis_rst_n
);

reg [(pDATA_WIDTH-1):0] length_reg;


reg [(pDATA_WIDTH-1):0] tap_write;
reg [(pDATA_WIDTH-1):0] tap_read;

reg ap_start;
// Axilite 
assign tap_WE = (awvalid & wvalid)? 1'b1 : 1'b0;
assign tap_EN = (awvalid & wvalid) | (arvalid && rready)? 1'b1 : 1'b0;
assign tap_A = (awvalid & wvalid) ? awaddr : (awvalid & wvalid)? araddr : 'd0;
assign tap_Di = tap_write;

assign rdata = tap_read;

always@(posedge axis_clk or negedge axis_rst_n)begin
    if (~axis_rst_n) begin
        tap_write <= 'd0;
        tap_read <= 'd0;
        length_reg <= 'd0;
    end 
    else if (awvalid && wvalid) begin
        // Write operation: Store wdata into data RAM (bram11) using data_WE, data_EN, data_Di, and data_A
        tap_write <= wdata;
        if(awaddr == 'h10) length_reg <= tap_write;
        else length_reg <= length_reg;
    end 
    else if (arvalid && rready) begin
        tap_read <= tap_Do;
    end else begin
        tap_write <= 'd0;
        tap_read <= 'd0;
        length_reg <= 'd0;
    end
end 



endmodule

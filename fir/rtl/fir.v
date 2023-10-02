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

reg [(pDATA_WIDTH-1):0] data_length;



reg ap_start;
// Axilite 
reg [3:0]tap_WE_reg;
assign tap_WE = tap_WE_reg;

reg [(pADDR_WIDTH-1):0] addr_reg;
assign tap_A = (addr_reg);

reg [(pDATA_WIDTH-1):0] tap_write;
assign tap_Di = tap_write;

reg [(pDATA_WIDTH-1):0] tap_read;
assign rdata = tap_read;


reg tap_EN_reg;
assign tap_EN = tap_EN_reg;

reg rvalid_reg;
assign rvalid = rvalid_reg; 
assign wready = wvalid;

reg [2:0] rvalid_count;


always@(posedge axis_clk or negedge axis_rst_n) begin
    if (~axis_rst_n) begin
        tap_write <= 'd0;
        tap_read <= 'd0;
        data_length <= 'd0;
        tap_EN_reg <= 1'b0;
        tap_WE_reg <= 4'b0000;
        rvalid_count <= 3'b000;
    end 
    else if (wvalid) begin
        if(awaddr == 12'h10) data_length <= wdata;
        else  begin
            addr_reg <= awaddr;
            tap_write <= wdata;
            tap_EN_reg <= 1'b1;
            tap_WE_reg <= 4'b1111;
        end
    end 
    else if (rready) begin
        tap_read <= tap_Do;
        tap_EN_reg <= 1'b1;
        tap_WE_reg <= 4'b0000;
        addr_reg <= araddr; 
        rvalid_reg <= 1'b1;
    end else begin
        tap_write <= tap_write;
        tap_read <= 'd0;
        data_length <= data_length;
        tap_EN_reg <= 1'b1;
        tap_WE_reg <= 4'b0000;
        rvalid_count =  3'b000;
    end
end 



endmodule

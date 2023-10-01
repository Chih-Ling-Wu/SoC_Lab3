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

reg tap_WE_reg, tap_EN_reg, tap_Di_reg, tap_A_reg;
assign tap_WE = tap_WE_reg;
assign tap_EN = tap_EN_reg;
assign tap_Di = tap_Di_reg;
assign tap_A = tap_A_reg;

reg wready_reg;
reg rvalid_reg;
reg rdata_reg;

assign rdata = rdata_reg;
assign rvalid = rvalid_reg;
assign wready = wready_reg;


reg ap_start;
// Axilite 
always@(posedge axis_clk or negedge axis_rst_n)begin
    if (~axis_rst_n) begin
        wready_reg <= 1'b0;
        rvalid_reg <= 1'b0;

        tap_WE_reg <= 4'b0000; 
        tap_EN_reg <= 1'b0;
        tap_A_reg <= 'd0;     
        tap_Di_reg <= 'd0;  
        length_reg <= 'd0;
        rdata_reg <= 'd0;
    end 
    else if (awvalid && wvalid) begin
        // Write operation: Store wdata into data RAM (bram11) using data_WE, data_EN, data_Di, and data_A
        wready_reg <= 1'b1;
        tap_WE_reg <= 4'b1111; 
        tap_EN_reg <= 1'b1;
        tap_A_reg <= awaddr;     
        tap_Di_reg <= wdata;     
        if(awaddr == 'h10) length_reg <= wdata;
        else length_reg <= length_reg;
    end 
    else if (arvalid && rready) begin
        // Read operation: Fetch data from data RAM (bram11) based on araddr
        // Use the data_Do port to read data from bram11
        rvalid_reg <= 1'b1;                         // Set rvalid to indicate valid read data
        tap_WE_reg <= 4'b0000; 
        tap_EN_reg <= 1'b1;    
        tap_A_reg <= araddr;   // Set the address for writing
        rdata_reg <= tap_Do;
    end else begin
        wready_reg <= wready_reg;
        rvalid_reg <= rvalid_reg;
        tap_WE_reg <= tap_WE_reg; 
        tap_EN_reg <= tap_EN_reg;
        tap_A_reg <= tap_A_reg ;     
        tap_Di_reg <= tap_Di_reg;  
        length_reg <= length_reg;
        rdata_reg <= rdata_reg;
    end
end 

// ap_start
always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n) begin
        tap_WE_reg <= 4'b0000; 
        tap_EN_reg <= 1'b0;
        tap_A_reg <= 'd0;     
        ap_start <= 1'b0;
    end
    else begin
        tap_WE_reg <= 4'b0000; 
        tap_EN_reg <= 1'b1;    
        tap_A_reg <= 12'h00;   
        ap_start <= tap_Do;  
    end
end

integer i;
reg ss_tready_reg;
assign ss_tready = ss_tready_reg;

always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n) begin
        tap_WE_reg <= 4'b0000; 
        tap_EN_reg <= 1'b0;
        tap_A_reg <= 'd0;  
        ss_tready_reg <= 1'b0;
        i = 0; 
    end 
    else if (ss_tvalid) begin 
        tap_WE_reg <= 4'b1111; 
        tap_EN_reg <= 1'b1;   
        tap_Di_reg <= ss_tdata;  
        tap_A_reg <= 'h30 + i;   
        i = i + 5; 
        if (ss_tlast) ss_tready_reg <= 1'b0;
        else ss_tready_reg <= 1'b1;
    end 
end


endmodule

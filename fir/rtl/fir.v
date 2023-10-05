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



reg [(pDATA_WIDTH-1):0] coef_0;
reg [(pDATA_WIDTH-1):0] coef_1;
reg [(pDATA_WIDTH-1):0] coef_2;
reg [(pDATA_WIDTH-1):0] coef_3;
reg [(pDATA_WIDTH-1):0] coef_4;
reg [(pDATA_WIDTH-1):0] coef_5;
reg [(pDATA_WIDTH-1):0] coef_6;
reg [(pDATA_WIDTH-1):0] coef_7;
reg [(pDATA_WIDTH-1):0] coef_8;
reg [(pDATA_WIDTH-1):0] coef_9;
reg [(pDATA_WIDTH-1):0] coef_10;




// Axilite interfaces //

// Store total length of data
reg [(pDATA_WIDTH-1):0] data_length;


reg [6:0] count;

// Control signals for BRAM
reg tap_EN_reg;
assign tap_EN = tap_EN_reg;
reg [3:0]tap_WE_reg;
assign tap_WE = tap_WE_reg;
reg [(pDATA_WIDTH-1):0] tap_write;
assign tap_Di = tap_write;
reg [(pDATA_WIDTH-1):0] tap_read;
assign rdata = tap_read;
reg [(pADDR_WIDTH-1):0] addr_reg;
assign tap_A = (addr_reg);

// Return control signal
assign rvalid = rready; 
assign wready = wvalid;

always@(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) count <= 'd0;
    else begin
        if(count <= 'd100) count <= count + 1'b1;
        else count <= count;
    end
end
always@* begin
    if (awvalid) begin
        addr_reg = awaddr;
        tap_write = wdata;
        tap_EN_reg = 1'b1;
        tap_WE_reg = 4'b1111;
    end 
    else if (arvalid) begin
        tap_read = tap_Do;
        tap_EN_reg = 1'b1;
        tap_WE_reg = 4'b0000;
        addr_reg = araddr; 
    end 
end 

always@(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) begin
        coef_0 <= 'd0;
        coef_1 <= 'd0;
        coef_2 <= 'd0;
        coef_3 <= 'd0;
        coef_4 <= 'd0;
        coef_5 <= 'd0;
        coef_6 <= 'd0;
        coef_7 <= 'd0;
        coef_8 <= 'd0;
        coef_9 <= 'd0;
        coef_10 <= 'd0;
    end
    else begin
        case (count)
            'd1 : coef_0 <= wdata;
            'd2 : coef_1 <= wdata;
            'd3 : coef_2 <= wdata;
            'd4 : coef_3 <= wdata;
            'd5 : coef_4 <= wdata;
            'd6 : coef_5 <= wdata;
            'd7 : coef_6 <= wdata;
            'd8 : coef_7 <= wdata;
            'd9 : coef_8 <= wdata;
            'd10 : coef_9 <= wdata;
            'd11 : coef_10 <= wdata;
        endcase
    end
end
integer i;
reg [(pDATA_WIDTH-1):0] coef [10:0];
always@(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) begin
        for(i = 0 ;i < 11; i = i + 1)
            coef[i] <= 'd0;
    end
    else begin
        case (count)
            'd1 : coef[0] <= wdata;
            'd2 : coef[1] <= wdata;
            'd3 : coef[2] <= wdata;
            'd4 : coef[3] <= wdata;
            'd5 : coef[4] <= wdata;
            'd6 : coef[5] <= wdata;
            'd7 : coef[6] <= wdata;
            'd8 : coef[7] <= wdata;
            'd9 : coef[8] <= wdata;
            'd10 : coef[9]  <= wdata;
            'd11 : coef[10] <= wdata;
        endcase
    end
end
always@(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) data_length <= 'd0;
    else begin
        if(awvalid) begin
            if(awaddr == 12'h10) data_length <= wdata;
        end
        else data_length <= data_length;
    end
end



reg data_EN_reg;
assign data_EN = data_EN_reg;
reg [3:0]data_WE_reg;
assign data_WE = data_WE_reg;
reg [(pDATA_WIDTH-1):0] data_write;
assign data_Di = data_write;
reg [(pADDR_WIDTH-1):0] data_A_reg;
assign data_A = data_A_reg;

// stream in input
reg [10:0] addr_count;
always @(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) addr_count <= 'd32;
    else begin
        if(count >= 'd50) begin
            if(addr_count <= 'd41) addr_count <= addr_count + 1'b1;
            else addr_count <= 'd32;
        end
    end
end
assign ss_tready = count >= 'd50;
always@* begin
    if(ss_tvalid) begin
        data_write = ss_tdata;
        data_EN_reg = 1'b1;
        data_WE_reg = 4'b1111;
        data_A_reg = addr_count;
    end
end


// Shift register
reg [(pDATA_WIDTH-1):0] shift_1;
reg [(pDATA_WIDTH-1):0] shift_2;
reg [(pDATA_WIDTH-1):0] shift_3;
reg [(pDATA_WIDTH-1):0] shift_4;
reg [(pDATA_WIDTH-1):0] shift_5;
reg [(pDATA_WIDTH-1):0] shift_6;
reg [(pDATA_WIDTH-1):0] shift_7;
reg [(pDATA_WIDTH-1):0] shift_8;
reg [(pDATA_WIDTH-1):0] shift_9;
reg [(pDATA_WIDTH-1):0] shift_10;
reg [(pDATA_WIDTH-1):0] shift_11;



always @(posedge axis_clk or negedge axis_rst_n) begin
    if (~axis_rst_n) begin
        shift_1 <= 'd0;
        shift_2 <= 'd0;
        shift_3 <= 'd0;
        shift_4 <= 'd0;
        shift_5 <= 'd0;
        shift_6 <= 'd0;
        shift_7 <= 'd0;
        shift_8 <= 'd0;
        shift_9 <= 'd0;
        shift_10 <= 'd0;
        shift_11 <= 'd0;
    end else begin
        // Shift data through the register
        if(count >= 'd51) begin
            shift_1 <= data_Do;
            shift_2 <= shift_1;
            shift_3 <= shift_2;
            shift_4 <= shift_3;
            shift_5 <= shift_4;
            shift_6 <= shift_5;
            shift_7 <= shift_6;
            shift_8 <= shift_7;
            shift_9 <= shift_8;
            shift_10 <= shift_9;
            shift_11 <= shift_10;

        end
    end
end
reg [(pDATA_WIDTH-1):0] shift [10:0];
always @(posedge axis_clk or negedge axis_rst_n) begin
    if (~axis_rst_n) begin
        for( i = 0; i < 11; i = i + 1)
            shift[i] <= 'd0;
    end else begin
        // Shift data through the register
        if(count >= 'd51) begin
            shift[0] <= data_Do;
            for(i = 1; i < 11; i = i + 1) 
                shift[i] <= shift[i-1];
        end
    end
end


reg [(pDATA_WIDTH-1):0] accumulate_result;



reg [4:0] mul_count;
// always @(posedge axis_clk or negedge axis_rst_n) begin
//     if(~axis_rst_n) mul_count <= 'd0;
//     else begin
//         accumulate_result <= shift[0]*coef[0] + shift[1]*coef[1] + shift[2]*coef[2] + shift[3]*coef[3] + shift[4]*coef[4] + shift[5]*coef[5] +shift[6]*coef[6] + shift[7]*coef[7] +shift[8]*coef[8] + shift[9]*coef[9]  + shift[10]*coef[10];
//     end
// end

always @(posedge axis_clk or negedge axis_rst_n) begin
    if (~axis_rst_n) begin
        mul_count <= 'd0;
        accumulate_result <= 'd0;
    end
    else begin 
        if(count >= 'd51) begin
            if (mul_count < 'd10) begin
                // Use a single multiplier and adder for MAC operation in 11 cycles
                accumulate_result <= accumulate_result + (shift[mul_count] * coef[mul_count]);
                mul_count <= mul_count + 1'b1;
            end 
            else begin
                accumulate_result <= 'd0;
                mul_count <= 'd0;
            end
        end
    end
end

assign sm_tvalid = count >= 'd53;
reg [(pDATA_WIDTH-1):0] sm_tdata_reg;
assign sm_tdata = accumulate_result;
reg [10:0] output_count;

always @(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) output_count <= 'd0;
    else begin
        if(sm_tvalid) begin
            if(output_count <= data_length) output_count <= output_count + 1'b1;
            else output_count <= 'd0;
        end
    end
    
end
assign sm_tlast = (output_count == 'd600);

endmodule

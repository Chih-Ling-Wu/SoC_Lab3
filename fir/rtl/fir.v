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

reg [10:0] output_count;

// Axilite interfaces //

reg ap_start;
reg ap_idle;
reg ap_done;
reg [(pDATA_WIDTH-1):0] ap_signal;

// Store total length of data
reg [(pDATA_WIDTH-1):0] data_length;

// Control signals for BRAM
reg tap_EN_reg;
assign tap_EN = tap_EN_reg;
reg [3:0]tap_WE_reg;
assign tap_WE = tap_WE_reg;
reg [(pDATA_WIDTH-1):0] tap_write;
assign tap_Di = tap_write;
reg [(pDATA_WIDTH-1):0] tap_read;
assign rdata = araddr == 12'h00 ? ap_signal : tap_read;
reg [(pADDR_WIDTH-1):0] addr_reg;
assign tap_A = (addr_reg);

// Return control signal
assign rvalid = rready; 
assign wready = wvalid;

always@* begin
    if (awvalid) begin
        if(awaddr != 12'h00) begin
            addr_reg = awaddr-12'h20;
            tap_write = wdata;
            tap_EN_reg = 1'b1;
            tap_WE_reg = 4'b1111;
        end
    end 
    else if (arvalid) begin
        if(araddr != 12'h00) begin
            tap_read = tap_Do;
            tap_EN_reg = 1'b1;
            tap_WE_reg = 4'b0000;
            addr_reg = araddr-12'h20; 
        end
    end 
end 

always@(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) data_length <= 'd0;
    else begin
        if(awaddr == 12'h10) data_length <= wdata;
        else data_length <= data_length;
    end
end



// FSM //
parameter IDLE = 2'd0;
parameter LOAD = 2'd1;
parameter MAC  = 2'd2;
parameter DONE  = 2'd3;

reg [1:0] cur_state, next_state;
reg [3:0] count;
reg [3:0] count_next;
reg [10:0] global_count;


always@(posedge axis_clk or negedge axis_rst_n) begin
    if (~axis_rst_n) global_count <= 'd0;
    else begin
        global_count <= global_count <= 'd100 ? global_count + 1'b1 : global_count;
    end
end

//////////////////////////////////////
reg [(pDATA_WIDTH-1):0] coef [Tape_Num-1 : 0];
integer i;

always@(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) begin
        for(i = 0; i < Tape_Num; i = i + 1)
            coef[i] <= 'd0;
    end
    else begin
        case (global_count)
            'd1 : coef[0] <= wdata;
            'd2 : coef[1] <= wdata;
            'd3 : coef[2] <= wdata;
            'd4 : coef[3] <= wdata;
            'd5 : coef[4] <= wdata;
            'd6 : coef[5] <= wdata;
            'd7 : coef[6] <= wdata;
            'd8 : coef[7] <= wdata;
            'd9 : coef[8] <= wdata;
            'd10 : coef[9] <= wdata;
            'd11 : coef[10] <= wdata;
        endcase
    end
end

//////////////////////////////////////////////

always@(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) cur_state <= IDLE;
    else cur_state <= next_state;
end

// counter

always @(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) count <= 'd0;
    else begin
        case (cur_state)
            LOAD : begin
                count <= 'd0;
            end
            MAC : begin
                if(count < Tape_Num) count <= count + 1'b1;
                else count <= 'd0;
            end
            default count <= count;
        endcase
    end
end

always@* begin
    case(cur_state)
        IDLE : next_state = (global_count >= 'd70)? LOAD : IDLE;
        // IDLE : next_state = LOAD;
        // LOAD : next_state = (count == Tape_Num - 1) ? MAC  : LOAD;
        LOAD : next_state = MAC;
        MAC : begin
            if(count == Tape_Num) next_state = LOAD;
            // else if(output_count == data_length) next_state = DONE;
            else next_state = MAC;
        end 
        DONE : next_state = DONE;
    endcase
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

assign ss_tready = (count == 'd0) & (cur_state == LOAD) | ((cur_state == IDLE) & (next_state == LOAD))? 1'b1 : 1'b0;
// assign ss_tready = (count == 'd0) & (cur_state == LOAD) ? 1'b1 : 1'b0;
always@* begin
    if(ss_tready) begin
        data_A_reg = count << 2;
        data_EN_reg = 1'b1;
        data_WE_reg = 4'b1111;
        data_write = ss_tdata;
    end
end


// one multiplier and one adder for fir //
wire [(pDATA_WIDTH-1):0] temp;
wire [(pDATA_WIDTH-1):0] cur_sum;
reg [(pDATA_WIDTH-1):0] prev_sum;
reg [(pDATA_WIDTH-1):0] cur_data;
reg [(pDATA_WIDTH-1):0] cur_coef;

assign temp = cur_data * cur_coef;
assign cur_sum = prev_sum + temp;




// shift register 
reg [(pDATA_WIDTH-1):0] shift [Tape_Num - 1 :0];

always@(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) begin
        for(i = 0; i < Tape_Num; i = i + 1)
            shift[i] <= 'd0;
    end
    else begin
        // if(cur_state == MAC && count == 'd1) begin
        if(cur_state == LOAD) begin
            for(i = 1 ; i < Tape_Num; i = i + 1) begin
                shift[i] <= shift[i-1];
            end
            shift[0] <= data_Do;
        end 
    end
end
always @(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) begin
        cur_data <= 'd0;
        prev_sum <= 'd0;
        cur_coef <= 'd0;
    end
    else begin
        case (cur_state)
            MAC : begin
                cur_data <= shift[count];
                prev_sum <= cur_sum;
                cur_coef <= coef[count];
            end
            default: begin
                cur_data <= 'd0;
                prev_sum <= 'd0;
                cur_coef <= 'd0;
            end
        endcase
    end
end

assign sm_tvalid = ((cur_state == MAC) && (count == 'd11)); 
reg [(pDATA_WIDTH-1):0] sm_tdata_reg;
always @(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) sm_tdata_reg <= 'd0;
    else sm_tdata_reg <= (sm_tvalid)? cur_sum : sm_tdata_reg;
end
assign sm_tdata = sm_tdata_reg;


always @(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) output_count <= 'd0;
    else begin
        if(sm_tvalid) begin
            if(output_count <= data_length) output_count <= output_count + 1'b1;
            else output_count <= output_count;
        end
    end
    
end
assign sm_tlast = (cur_state != IDLE) & (output_count == data_length);

reg ap_start_flag;
always@(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) ap_start_flag <= 1'b0;
    else begin
        if(awaddr == 12'h00) ap_start_flag <= 1'b1;
    end
end

always@(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) ap_start <= 1'b0;
    else begin
        if(awaddr == 12'h00 && ~ap_start_flag) ap_start <= 1'b1;
        else ap_start <= 1'b0;
    end
end

always@(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) ap_done <= 1'b0;
    else begin
        if (output_count == data_length & cur_state != IDLE) ap_done <= 1'b1;
        else ap_done <= ap_done;
    end
end

always@(posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) ap_idle <= 1'b1;
    else begin
        if (output_count == data_length) ap_idle <= 1'b1;
        else if (ap_start) ap_idle <= 1'b0;
        else ap_idle <= ap_idle;
    end
end

always@* begin
    ap_signal[31:0] = {29'b0, ap_idle, ap_done, ap_start};
end
endmodule

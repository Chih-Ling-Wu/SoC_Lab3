`timescale 1ns / 1ps

module fir
#(
    parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num = 11
)
(
    output wire awready,
    output wire wready,
    input wire awvalid,
    input wire [(pADDR_WIDTH-1):0] awaddr,
    input wire wvalid,
    input wire [(pDATA_WIDTH-1):0] wdata,
    output wire arready,
    input wire rready,
    input wire arvalid,
    input wire [(pADDR_WIDTH-1):0] araddr,
    output wire rvalid,
    output wire [(pDATA_WIDTH-1):0] rdata,
    input wire ss_tvalid,
    input wire [(pDATA_WIDTH-1):0] ss_tdata,
    input wire ss_tlast,
    output wire ss_tready,
    input wire sm_tready,
    output wire sm_tvalid,
    output wire [(pDATA_WIDTH-1):0] sm_tdata,
    output wire sm_tlast,
    input wire axis_clk,
    input wire axis_rst_n
);
    // Internal signals and registers
    reg [(pDATA_WIDTH-1):0] shift_reg [0:Tape_Num-1];
    reg [(pDATA_WIDTH-1):0] tap_coefficients [0:Tape_Num-1];
    reg [(pDATA_WIDTH-1):0] result;
    reg [3:0] tap_index;

    // Address map
    localparam pADDR_START = 8'h00;
    localparam pADDR_DONE = 8'h01;
    localparam pADDR_IDLE = 8'h02;
    localparam pADDR_DATA_LENGTH = 8'h10;
    localparam pADDR_TAP_BASE = 8'h20;

    // AXI-Stream to internal signals
    reg internal_valid;
    wire internal_ready;
    assign internal_ready = (sm_tready && rready);
    assign sm_tvalid = internal_valid && internal_ready;
    assign sm_tdata = result;
    assign sm_tlast = ss_tlast;

    // AXI-Lite interface signals
    reg [31:0] axilite_data;
    reg [pADDR_WIDTH-1:0] axilite_addr;
    reg axilite_write;
    reg axilite_read;
    reg [pDATA_WIDTH-1:0] axilite_read_data;
    reg [pDATA_WIDTH-1:0] axilite_coef_data;
    reg i ;
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n) begin
            // Reset logic here
            for (i = 0; i < Tape_Num; i = i + 1) begin
                shift_reg[i] <= 0;
                tap_coefficients[i] <= 0;
            end
            result <= 0;
            tap_index <= 0;
            internal_valid <= 0;
        end else if (internal_ready) begin
            // Update shift_reg with new data
            for (i = Tape_Num-1; i > 0; i = i - 1) begin
                shift_reg[i] <= shift_reg[i-1];
            end
            shift_reg[0] <= wdata;
            
            // Perform FIR filtering using shift_reg and tap_coefficients
            result <= 0;
            for (i = 0; i < Tape_Num; i = i + 1) begin
                result <= result + (shift_reg[i] * tap_coefficients[i]);
            end

            // Set the internal valid flag to indicate data is ready
            internal_valid <= wvalid;
        end
    end

    // AXI-Lite interface logic for coefficient configuration
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n) begin
            axilite_data <= 0;
            axilite_addr <= 0;
            axilite_write <= 0;
            axilite_read <= 0;
            axilite_read_data <= 0;
            axilite_coef_data <= 0;
        end else begin
            // Read/Write logic for AXI-Lite interface
            if (awvalid && awready) begin
                axilite_addr <= awaddr;
                axilite_data <= wdata;
                axilite_write <= 1;
            end
            if (arvalid && arready) begin
                case(axilite_addr)
                    pADDR_TAP_BASE: axilite_read_data <= tap_coefficients[araddr];
                    default: axilite_read_data <= 0;
                endcase
                axilite_read <= 1;
            end
        end
    end

    always @(posedge axis_clk) begin
        // Update tap_coefficients from AXI-Lite writes
        if (axilite_write) begin
            if (axilite_addr >= pADDR_TAP_BASE) begin
                tap_coefficients[axilite_addr - pADDR_TAP_BASE] <= axilite_data;
            end
            axilite_coef_data <= axilite_data;
        end
        // Reset axilite_write
        axilite_write <= 0;
    end

endmodule

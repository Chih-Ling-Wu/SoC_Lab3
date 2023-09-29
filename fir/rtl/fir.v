module fir #(
    parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num = 11
)
(
    // AXI-Stream interfaces
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

    // Custom AXI-Stream interfaces
    output wire ss_tvalid,
    input wire [(pDATA_WIDTH-1):0] ss_tdata,
    input wire ss_tlast,
    input wire ss_tready,
    input wire sm_tready,
    output wire sm_tvalid,
    output wire [(pDATA_WIDTH-1):0] sm_tdata,
    output wire sm_tlast,

    // Clock and reset
    input wire axis_clk,
    input wire axis_rst_n,

    // AXI-Lite interface
    input wire axi_lite_clk,  // AXI-Lite clock
    input wire axi_lite_rst_n, // AXI-Lite reset
    output wire axi_lite_awready,
    input wire axi_lite_awvalid,
    input wire [(pADDR_WIDTH-1):0] axi_lite_awaddr,
    output wire axi_lite_wready,
    input wire axi_lite_wvalid,
    input wire [(pDATA_WIDTH-1):0] axi_lite_wdata,
    output wire axi_lite_bvalid,
    input wire axi_lite_bready,
    output wire axi_lite_arready,
    input wire axi_lite_arvalid,
    input wire [(pADDR_WIDTH-1):0] axi_lite_araddr,
    output wire axi_lite_rvalid,
    output wire [(pDATA_WIDTH-1):0] axi_lite_rdata
);

    // Internal signals and registers
    reg [(pDATA_WIDTH-1):0] shift_reg [0:Tape_Num-1];
    reg [(pDATA_WIDTH-1):0] tap_coefficients [0:Tape_Num-1];
    reg [(pDATA_WIDTH-1):0] result;
    reg [3:0] tap_index;

    // AXI-Stream to internal signals
    reg internal_valid;
    wire internal_ready;
    assign internal_ready = (sm_tready && rready);
    assign ss_tvalid = internal_valid && internal_ready;
    assign sm_tvalid = internal_valid && internal_ready;
    assign sm_tdata = result;
    assign sm_tlast = ss_tlast;

    // AXI-Lite interface
    reg [31:0] axilite_data;
    reg [pADDR_WIDTH-1:0] axilite_addr;
    reg axilite_write;
    reg axilite_read;
    reg [pDATA_WIDTH-1:0] axilite_read_data;
    reg [pDATA_WIDTH-1:0] axilite_coef_data;
    
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n) begin
            // Reset logic here
            for (int i = 0; i < Tape_Num; i = i + 1) begin
                shift_reg[i] <= 0;
                tap_coefficients[i] <= 0;
            end
            result <= 0;
            tap_index <= 0;
            internal_valid <= 0;
        end else if (internal_ready) begin
            // Update shift_reg with new data
            for (int i = Tape_Num-1; i > 0; i = i - 1) begin
                shift_reg[i] <= shift_reg[i-1];
            end
            shift_reg[0] <= wdata;
            
            // Perform FIR filtering using shift_reg and tap_coefficients
            result <= 0;
            for (int i = 0; i < Tape_Num; i = i + 1) begin
                result <= result + (shift_reg[i] * tap_coefficients[i]);
            end

            // Set the internal valid flag to indicate data is ready
            internal_valid <= wvalid;
        end
    end

    // AXI-Lite interface logic for coefficient configuration
    always @(posedge axi_lite_clk or negedge axi_lite_rst_n) begin
        if (!axi_lite_rst_n) begin
            axilite_data <= 0;
            axilite_addr <= 0;
            axilite_write <= 0;
            axilite_read <= 0;
            axilite_read_data <= 0;
            axilite_coef_data <= 0;
        end else begin
            // Read/Write logic for AXI-Lite interface
            if (axi_lite_awvalid && axi_lite_awready) begin
                axilite_addr <= axi_lite_awaddr;
                axilite_data <= axi_lite_wdata;
                axilite_write <= 1;
            end
            if (axi_lite_arvalid && axi_lite_arready) begin
                if (axilite_addr == 5'h00) begin
                    // Register address 0x00 - Control Register
                    if (axi_lite_read) begin
                        axilite_read_data <= {axilite_read_data[2:1], internal_valid};
                    end
                end else if (axilite_addr >= 5'h20 && axilite_addr <= 5'hFF) begin
                    // Registers 0x20-0xFF - Tap Coefficients
                    if (axi_lite_read) begin
                        axilite_read_data <= tap_coefficients[axilite_addr[7:0]];
                    end
                end
                axilite_read <= 1;
            end
        end
    end

    always @(posedge axi_lite_clk) begin
        // Update tap_coefficients from AXI-Lite writes
        if (axilite_write) begin
            tap_coefficients[axilite_addr[7:0]] <= axilite_data;
            axilite_coef_data <= axilite_data;
        end
        // Reset axilite_write
        axilite_write <= 0;
    end

    always @(posedge axi_lite_clk) begin
        // Respond to AXI-Lite reads
        if (axilite_read) begin
            axilite_rdata <= axilite_read_data;
        end
        // Reset axilite_read
        axilite_read <= 0;
    end
endmodule

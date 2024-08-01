`timescale 1ns/1ps
`include "eth_phy_10g_rx_aligner.v"

// 
// .\iverilog.exe -o eth_phy_10g_rx_aligner_tb.vvp eth_phy_10g_rx_aligner_tb.v
// .\vvp eth_phy_10g_rx_aligner_tb.vvp
// .\gtkwave.exe eth_phy_10g_rx_aligner_tb.vcd

module eth_phy_10g_rx_aligner_tb;

    parameter DATA_WIDTH_TB = 64;			
    parameter HDR_WIDTH_TB = 2;			

    reg clk_tb;
    reg rx_rst_tb;

    reg [DATA_WIDTH_TB-1:0] serdes_rx_data_tb;
    reg [HDR_WIDTH_TB-1:0]  serdes_rx_hdr_tb;

    wire [HDR_WIDTH_TB-1:0]   serdes_rx_hdr_align_tb;
    wire [DATA_WIDTH_TB-1:0]  serdes_rx_data_align_tb;
    wire                      aligned_tb;

    eth_phy_10g_rx_aligner #(
        .HDR_WIDTH(HDR_WIDTH_TB),
        .DATA_WIDTH(DATA_WIDTH_TB)
    )

    eth_phy_10g_rx_aligner_inst (
        .clk(clk_tb),
        .rst(rx_rst_tb),
        .i_serdes_rx_hdr(serdes_rx_hdr_tb),
        .i_serdes_rx_data(serdes_rx_data_tb),
        .o_serdes_rx_hdr_align(serdes_rx_hdr_align_tb),
        .o_serdes_rx_data_align(serdes_rx_data_align_tb),
        .o_aligned(aligned_tb)
    );

    // Generación de clock
    always #5 clk_tb <= ~clk_tb; 

    initial begin
        $dumpfile("eth_phy_10g_rx_aligner_tb.vcd");
        $dumpvars(0, eth_phy_10g_rx_aligner_tb);
    end

    always @(posedge clk_tb or posedge rx_rst_tb) begin
        if (rx_rst_tb) begin
            // Resetea serdes_tx_data
            serdes_rx_data_tb <= 64'b0;
            serdes_rx_hdr_tb  <= 2'b0;
        end else begin
            if (serdes_rx_data_align_tb) begin
                serdes_rx_data_tb <= serdes_rx_data_align_tb;
                serdes_rx_hdr_tb  <= serdes_rx_hdr_align_tb;
            end
        end

    end


    initial begin
        serdes_rx_data_tb = 64'b0;
        serdes_rx_hdr_tb  = 2'b0 ;

        clk_tb    = 1'b0;
        rx_rst_tb = 1'b1;

        #500
        @(posedge clk_tb);
        rx_rst_tb = 1'b0;
        @(posedge clk_tb);
        serdes_rx_data_tb = 64'hFFFFFFFF7FFFFFFF;
        serdes_rx_hdr_tb  = 2'b11;
        
        #2000
        $finish;
    end
endmodule

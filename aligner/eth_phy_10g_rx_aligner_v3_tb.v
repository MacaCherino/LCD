`timescale 1ns/1ps


module eth_phy_10g_rx_aligner_v3_tb;

    parameter DATA_WIDTH_TB = 64;			
    parameter HDR_WIDTH_TB = 2;			

    reg clk_tb;
    reg rx_rst_tb;

    reg [DATA_WIDTH_TB-1:0] serdes_rx_data_tb;
    reg [HDR_WIDTH_TB-1:0 ] serdes_rx_hdr_tb;

    wire [HDR_WIDTH_TB-1:0 ]              serdes_rx_hdr_align_tb ; 
    wire [DATA_WIDTH_TB-1:0]              serdes_rx_data_align_tb;
    wire                                  rx_block_lock_tb       ;
    wire                                  serdes_rx_bitslip_tb;

    eth_phy_10g_rx_aligner_v3 #(
        .HDR_WIDTH (HDR_WIDTH_TB),
        .DATA_WIDTH(DATA_WIDTH_TB)
    )

    eth_phy_10g_rx_aligner_v3_inst (
        .o_serdes_rx_hdr_align (serdes_rx_hdr_align_tb ),
        .o_serdes_rx_data_align(serdes_rx_data_align_tb), 
        .o_rx_block_lock       (rx_block_lock_tb       ),
        .o_serdes_rx_bitslip   (serdes_rx_bitslip_tb   ),
        .i_serdes_rx_hdr       (serdes_rx_hdr_tb       ),
        .i_serdes_rx_data      (serdes_rx_data_tb      ),
        .clk                   (clk_tb                 ),
        .rst                   (rx_rst_tb              )
    );

    // Generación de clock
    always #5 clk_tb <= ~clk_tb; 

    always @(posedge clk_tb or posedge rx_rst_tb) begin
        if (rx_rst_tb) begin
            // Resetea serdes_tx_data
            serdes_rx_data_tb <= 64'b0;
            serdes_rx_hdr_tb  <= 2'b0;
        end
    end

    initial begin
        serdes_rx_data_tb = 64'b0;
        serdes_rx_hdr_tb  = 2'b0 ;

        clk_tb    = 1'b1;
        rx_rst_tb = 1'b1;

        #1000
        @(posedge clk_tb);
        rx_rst_tb = 1'b0 ;

        @(posedge clk_tb);
        serdes_rx_data_tb = 64'hFFFFFFFF7FFFFFFF;
        serdes_rx_hdr_tb  = 2'b11               ;
        
        #100000
        @(posedge clk_tb);
        serdes_rx_data_tb = 64'h000000000000002;
        serdes_rx_hdr_tb  = 2'b00              ;
        
        #100000
        
        $finish;
    end
endmodule

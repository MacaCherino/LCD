`timescale 1ns/1ns
`include "eth_phy_10g.v"
// verifica que el block lock se active a los 64 headers validos
// si count_hdr >= 64 se llega a activar block_lock, en caso contrario, no se activa
module tb_hdr_valid_1;

	parameter DATA_WIDTH_TB = 64;			
	parameter CTRL_WIDTH_TB = (DATA_WIDTH_TB/8);	
	parameter HDR_WIDTH_TB = 2;			
	parameter BIT_REVERSE_TB = 0;			
	parameter SCRAMBLER_DISABLE_TB = 0;		
	parameter PRBS31_ENABLE_TB = 1;		
	parameter TX_SERDES_PIPELINE_TB = 0;		
	parameter RX_SERDES_PIPELINE_TB = 0;		
	parameter BITSLIP_HIGH_CYCLES_TB = 1;		
	parameter BITSLIP_LOW_CYCLES_TB = 8;		
	parameter COUNT_125US_TB = 125000/6.4;		

    reg clk_tb;
    reg rx_rst_tb;
    reg tx_rst_tb;

    reg [DATA_WIDTH_TB-1:0] xgmii_txd_tb;
    reg [CTRL_WIDTH_TB-1:0] xgmii_txc_tb;
    wire [DATA_WIDTH_TB-1:0] xgmii_rxd_tb;
    wire [CTRL_WIDTH_TB-1:0] xgmii_rxc_tb;

    wire [DATA_WIDTH_TB-1:0] serdes_tx_data_tb;
    wire [HDR_WIDTH_TB-1:0]  serdes_tx_hdr_tb;
    reg [DATA_WIDTH_TB-1:0] serdes_rx_data_tb;
    reg [HDR_WIDTH_TB-1:0]  serdes_rx_hdr_tb;
    wire serdes_rx_bitslip_tb;
    wire serdes_rx_reset_req_tb;

    wire tx_bad_block_tb;
    wire [6:0] rx_error_count_tb;
    wire rx_bad_block_tb;
    wire rx_sequence_error_tb;
    wire rx_block_lock_tb;
    wire rx_high_ber_tb;
    wire rx_status_tb;

    reg cfg_tx_prbs31_enable_tb;
    reg cfg_rx_prbs31_enable_tb;

	integer count;
	integer count_hdr;

    initial begin
        $dumpfile("tb_hdr_valid_1.vcd");
        $dumpvars(0, tb_hdr_valid_1);
    end

    eth_phy_10g #(
    	.DATA_WIDTH(DATA_WIDTH_TB),
    	.CTRL_WIDTH(CTRL_WIDTH_TB),
    	.HDR_WIDTH(HDR_WIDTH_TB),
    	.BIT_REVERSE(BIT_REVERSE_TB),
    	.SCRAMBLER_DISABLE(SCRAMBLER_DISABLE_TB),
    	.PRBS31_ENABLE(PRBS31_ENABLE_TB),
    	.TX_SERDES_PIPELINE(TX_SERDES_PIPELINE_TB),
    	.RX_SERDES_PIPELINE(RX_SERDES_PIPELINE_TB),
    	.BITSLIP_HIGH_CYCLES(BITSLIP_HIGH_CYCLES_TB),
    	.BITSLIP_LOW_CYCLES(BITSLIP_LOW_CYCLES_TB),
    	.COUNT_125US(COUNT_125US_TB)
	)

	eth_phy_10g_inst (
     	.rx_clk(clk_tb),
    	.rx_rst(rx_rst_tb),
    	.tx_clk(clk_tb),
    	.tx_rst(tx_rst_tb),
    	.xgmii_txd(xgmii_txd_tb),
    	.xgmii_txc(xgmii_txc_tb),
    	.xgmii_rxd(xgmii_rxd_tb),
    	.xgmii_rxc(xgmii_rxc_tb),
    	.serdes_tx_data(serdes_tx_data_tb),
    	.serdes_tx_hdr(serdes_tx_hdr_tb),
    	.serdes_rx_data(serdes_rx_data_tb),
    	.serdes_rx_hdr(serdes_rx_hdr_tb),
    	.serdes_rx_bitslip(serdes_rx_bitslip_tb),
    	.serdes_rx_reset_req(serdes_rx_reset_req_tb),
    	.tx_bad_block(tx_bad_block_tb),
    	.rx_error_count(rx_error_count_tb),
    	.rx_bad_block(rx_bad_block_tb),
    	.rx_sequence_error(rx_sequence_error_tb),
    	.rx_block_lock(rx_block_lock_tb),
    	.rx_high_ber(rx_high_ber_tb),
    	.rx_status(rx_status_tb),
    	.cfg_tx_prbs31_enable(cfg_tx_prbs31_enable_tb),
    	.cfg_rx_prbs31_enable(cfg_rx_prbs31_enable_tb)
    );

    // Generación de clock
    always begin
    	#1 clk_tb <= ~clk_tb; 
    end

	always @(posedge clk_tb or posedge rx_rst_tb) begin
		if (rx_rst_tb) begin
        	// Resetea serdes_tx_data
        	serdes_rx_data_tb <= 64'b0;
    	end else begin
			serdes_rx_data_tb <= serdes_tx_data_tb;
			serdes_rx_hdr_tb <= serdes_tx_hdr_tb;
			if (serdes_rx_hdr_tb == 2'b10) begin
				count_hdr <= count_hdr + 1;
				end
			end
			if (count_hdr == 64) begin
				serdes_rx_hdr_tb <= 2'b00;
				count_hdr <= 0;
			end else begin
				serdes_rx_hdr_tb <= 2'b10;
			end
	end

	always begin
		#10
		case (count)
			0: xgmii_txd_tb = 64'hFFFFFFFFFFFFFFFF;
			1: xgmii_txd_tb = 64'h0;
			2: xgmii_txd_tb = 64'h555555555555555;
			3: xgmii_txd_tb = 64'hAAAAAAAAAAAAA;
			4: xgmii_txd_tb = 64'hFEFEFEFEFEFEFEFE;
			5: xgmii_txd_tb = 64'h0707070707070707;
		endcase
		count = count + 1;
		if (count == 6) begin
			count = 0;
		end
	end

    initial begin
        rx_rst_tb = 1'b1;
        tx_rst_tb = 1'b1;
        #10;
        rx_rst_tb = 1'b0;
        tx_rst_tb = 1'b0;
		clk_tb = 1'b0;
		cfg_tx_prbs31_enable_tb <= 0;
    	cfg_rx_prbs31_enable_tb <= 0;
    	xgmii_txc_tb = 8'h00;
		xgmii_txd_tb = 64'hFFFFFFFFFFFFFFFF;
		count = 1;
		count_hdr = 1;

		#200
		$finish;
    end
endmodule

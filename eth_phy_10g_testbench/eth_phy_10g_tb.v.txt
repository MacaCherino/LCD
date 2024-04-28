`timescale 1ns/1ns
`include "eth_phy_10g.v"

module eth_phy_10g_tb;

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

    	initial begin
        	$dumpfile("eth_phy_10g_tb.vcd");
        	$dumpvars(0, eth_phy_10g_tb);
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

    	initial begin
    		tx_rst_tb <= 1'b0;
    		rx_rst_tb <= 1'b0;
		clk_tb <= 1'b0;
		cfg_tx_prbs31_enable_tb <= 0;
    		cfg_rx_prbs31_enable_tb <= 0;
    		xgmii_txd_tb = 64'hF04B30211070A806;
    		xgmii_txc_tb = 8'h00;
		serdes_rx_data_tb=64'hC519054182D01A3B;
    		serdes_rx_hdr_tb = 2'b10;
    		#10;
	
		$display("--------------------PRIMERA TRANSMISION--------------------");
		$display("xgmii_txd = %h", xgmii_txd_tb);
    		$display("xgmii_txc = %h", xgmii_txc_tb);
    		$display("serdes_rx_data = %h", serdes_rx_data_tb);
    		$display("serdes_rx_hdr = %b", serdes_rx_hdr_tb);
    		$display("cfg_tx_prbs31_enable = %h", cfg_tx_prbs31_enable_tb);
		$display("cfg_rx_prbs31_enable = %h", cfg_rx_prbs31_enable_tb);
    		
    		if (rx_bad_block_tb || rx_sequence_error_tb || rx_high_ber_tb || tx_bad_block_tb || rx_block_lock_tb || rx_error_count_tb) begin
			if (rx_bad_block_tb) begin
				$display("-> Error en rx_bad_block");
			end if (rx_sequence_error_tb) begin
				$display("-> Error en rx_sequence_error");
			end if (rx_high_ber_tb) begin
				$display("-> Error en rx_high_ber");
			end if (tx_bad_block_tb) begin
				$display("-> Error en tx_bad_block");
			end if (rx_block_lock_tb) begin
				$display("-> Error en rx_block_lock");
			end if (rx_error_count_tb) begin
				$display("-> Error en rx_error_count");
			end
    		end else begin
        		$display("-> Transmision Exitosa."); // Deberia ser exitosa
    		end
		
		#200
		$display("--------------------SEGUNDA TRANSMISION--------------------");
		$display("xgmii_txd = %h", xgmii_txd_tb);
    		$display("xgmii_txc = %h", xgmii_txc_tb);
    		$display("serdes_rx_data = %h", serdes_rx_data_tb);
    		$display("serdes_rx_hdr = %b", serdes_rx_hdr_tb);
    		$display("cfg_tx_prbs31_enable = %h", cfg_tx_prbs31_enable_tb);
		$display("cfg_rx_prbs31_enable = %h", cfg_rx_prbs31_enable_tb);
		$display("Se envian los mismos datos durante 200 conmutaciones del clock para producir un overflow");

    		if (rx_bad_block_tb || rx_sequence_error_tb || rx_high_ber_tb || tx_bad_block_tb || rx_block_lock_tb || rx_error_count_tb) begin
			if (rx_bad_block_tb) begin
				$display("-> Error en rx_bad_block");	
			end if (rx_sequence_error_tb) begin
				$display("-> Error en rx_sequence_error");
			end if (rx_high_ber_tb) begin
				$display("-> Error en rx_high_ber");
			end if (tx_bad_block_tb) begin
				$display("-> Error en tx_bad_block");	
			end if (rx_block_lock_tb) begin
				$display("-> Error en rx_block_lock");	// Tiene este error
			end if (rx_error_count_tb) begin
				$display("-> Error en rx_error_count");
			end
    		end else begin
        		$display("-> Transmision Exitosa.");
    		end
		
		tx_rst_tb <= 1'b1;
    		rx_rst_tb <= 1'b1;
		#5;
		tx_rst_tb <= 1'b0;
    		rx_rst_tb <= 1'b0;

    		serdes_rx_hdr_tb = 2'b00;
		#10;

		$display("--------------------TERCERA TRANSMISION--------------------");
		$display("xgmii_txd = %h", xgmii_txd_tb);
    		$display("xgmii_txc = %h", xgmii_txc_tb);
    		$display("serdes_rx_data = %h", serdes_rx_data_tb);
    		$display("serdes_rx_hdr = %b (Encabezado Invalido)", serdes_rx_hdr_tb);
    		$display("cfg_tx_prbs31_enable = %h", cfg_tx_prbs31_enable_tb);
		$display("cfg_rx_prbs31_enable = %h", cfg_rx_prbs31_enable_tb);

    		if (rx_bad_block_tb || rx_sequence_error_tb || rx_high_ber_tb || tx_bad_block_tb || rx_block_lock_tb || rx_error_count_tb) begin
			if (rx_bad_block_tb) begin
				$display("-> Error en rx_bad_block");	// Tiene este error
			end if (rx_sequence_error_tb) begin
				$display("-> Error en rx_sequence_error");
			end if (rx_high_ber_tb) begin
				$display("-> Error en rx_high_ber");	
			end if (tx_bad_block_tb) begin
				$display("-> Error en tx_bad_block");
			end if (rx_block_lock_tb) begin
				$display("-> Error en rx_block_lock");
			end if (rx_error_count_tb) begin
				$display("-> Error en rx_error_count");
			end
    		end else begin
        		$display("-> Transmision Exitosa.");
    		end
		
		#100;
		$display("--------------------CUARTA TRANSMISION--------------------");
		$display("xgmii_txd = %h", xgmii_txd_tb);
    		$display("xgmii_txc = %h", xgmii_txc_tb);
    		$display("serdes_rx_data = %h", serdes_rx_data_tb);
    		$display("serdes_rx_hdr = %b (Encabezado Invalido)", serdes_rx_hdr_tb);
    		$display("cfg_tx_prbs31_enable = %h", cfg_tx_prbs31_enable_tb);
		$display("cfg_rx_prbs31_enable = %h", cfg_rx_prbs31_enable_tb);
		$display("Se envian los mismos datos con encabezado invalido durante 100 conmutaciones del clock para producir alta BER");

    		if (rx_bad_block_tb || rx_sequence_error_tb || rx_high_ber_tb || tx_bad_block_tb || rx_block_lock_tb || rx_error_count_tb) begin
			if (rx_bad_block_tb) begin
				$display("-> Error en rx_bad_block");	// Tiene este error
			end if (rx_sequence_error_tb) begin
				$display("-> Error en rx_sequence_error");
			end if (rx_high_ber_tb) begin
				$display("-> Error en rx_high_ber");	// Tiene este error
			end if (tx_bad_block_tb) begin
				$display("-> Error en tx_bad_block");	
			end if (rx_block_lock_tb) begin
				$display("-> Error en rx_block_lock");
			end if (rx_error_count_tb) begin
				$display("-> Error en rx_error_count");
			end
    		end else begin
        		$display("-> Transmision Exitosa.");
    		end

		tx_rst_tb <= 1'b1;
    		rx_rst_tb <= 1'b1;
		#5;
		tx_rst_tb <= 1'b0;
    		rx_rst_tb <= 1'b0;
		
		serdes_rx_hdr_tb = 2'b10;
		xgmii_txc_tb = 8'h0F;
		#10;
		
		$display("--------------------QUINTA TRANSMISION--------------------");
		$display("xgmii_txd = %h", xgmii_txd_tb);
    		$display("xgmii_txc = %h", xgmii_txc_tb);
    		$display("serdes_rx_data = %h", serdes_rx_data_tb);
    		$display("serdes_rx_hdr = %b", serdes_rx_hdr_tb);
    		$display("cfg_tx_prbs31_enable = %h", cfg_tx_prbs31_enable_tb);
		$display("cfg_rx_prbs31_enable = %h", cfg_rx_prbs31_enable_tb);

    		if (rx_bad_block_tb || rx_sequence_error_tb || rx_high_ber_tb || tx_bad_block_tb || rx_block_lock_tb || rx_error_count_tb) begin
			if (rx_bad_block_tb) begin
				$display("-> Error en rx_bad_block");
			end if (rx_sequence_error_tb) begin
				$display("-> Error en rx_sequence_error");
			end if (rx_high_ber_tb) begin
				$display("-> Error en rx_high_ber");
			end if (tx_bad_block_tb) begin
				$display("-> Error en tx_bad_block");	// Tiene este error
			end if (rx_block_lock_tb) begin
				$display("-> Error en rx_block_lock");
			end if (rx_error_count_tb) begin
				$display("-> Error en rx_error_count");
			end
    		end else begin
        		$display("-> Transmision Exitosa.");
    		end
		
		tx_rst_tb <= 1'b1;
    		rx_rst_tb <= 1'b1;
		#5;
		tx_rst_tb <= 1'b0;
    		rx_rst_tb <= 1'b0;

		xgmii_txc_tb = 8'h00;
		cfg_rx_prbs31_enable_tb <= 1;
		#10;

		$display("--------------------SEXTA TRANSMISION--------------------");
		$display("xgmii_txd = %h", xgmii_txd_tb);
    		$display("xgmii_txc = %h", xgmii_txc_tb);
    		$display("serdes_rx_data = %h", serdes_rx_data_tb);
    		$display("serdes_rx_hdr = %b", serdes_rx_hdr_tb);
    		$display("cfg_tx_prbs31_enable = %h", cfg_tx_prbs31_enable_tb);
		$display("cfg_rx_prbs31_enable = %h", cfg_rx_prbs31_enable_tb);

    		if (rx_bad_block_tb || rx_sequence_error_tb || rx_high_ber_tb || tx_bad_block_tb || rx_block_lock_tb || rx_error_count_tb) begin
			if (rx_bad_block_tb) begin
				$display("-> Error en rx_bad_block");
			end if (rx_sequence_error_tb) begin
				$display("-> Error en rx_sequence_error");	
			end if (rx_high_ber_tb) begin
				$display("-> Error en rx_high_ber");
			end if (tx_bad_block_tb) begin
				$display("-> Error en tx_bad_block");
			end if (rx_block_lock_tb) begin
				$display("-> Error en rx_block_lock");
			end if (rx_error_count_tb) begin
				$display("-> Error en rx_error_count");	// Tiene este error
			end
    		end else begin
        		$display("-> Transmision Exitosa.");
    		end

		tx_rst_tb <= 1'b1;
    		rx_rst_tb <= 1'b1;
		#5;
		tx_rst_tb <= 1'b0;
    		rx_rst_tb <= 1'b0;
		
		serdes_rx_hdr_tb = 2'b01;
		cfg_rx_prbs31_enable_tb <= 0;
		#100;

		$display("--------------------SEPTIMA TRANSMISION--------------------");
		$display("xgmii_txd = %h", xgmii_txd_tb);
    		$display("xgmii_txc = %h", xgmii_txc_tb);
    		$display("serdes_rx_data = %h", serdes_rx_data_tb);
    		$display("serdes_rx_hdr = %b", serdes_rx_hdr_tb);
    		$display("cfg_tx_prbs31_enable = %h", cfg_tx_prbs31_enable_tb);
		$display("cfg_rx_prbs31_enable = %h", cfg_rx_prbs31_enable_tb);
		$display("Se envian los mismos datos con encabezado de control durante 100 conmutaciones del clock para producir error de secuencia");

    		if (rx_bad_block_tb || rx_sequence_error_tb || rx_high_ber_tb || tx_bad_block_tb || rx_block_lock_tb || rx_error_count_tb) begin
			if (rx_bad_block_tb) begin
				$display("-> Error en rx_bad_block");	// Tiene este error
			end if (rx_sequence_error_tb) begin
				$display("-> Error en rx_sequence_error");	// Tiene este error
			end if (rx_high_ber_tb) begin
				$display("-> Error en rx_high_ber");
			end if (tx_bad_block_tb) begin
				$display("-> Error en tx_bad_block");
			end if (rx_block_lock_tb) begin
				$display("-> Error en rx_block_lock");
			end if (rx_error_count_tb) begin
				$display("-> Error en rx_error_count");	
			end
    		end else begin
        		$display("-> Exitosa.");
    		end
    		$finish;
    	end
endmodule

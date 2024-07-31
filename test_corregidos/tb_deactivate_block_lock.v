`timescale 1ns/1ps
`include "eth_phy_10g.v"
// verifica que el block lock se desactive si se mandan mas de 16 headers invalidos
// si count_inv_hdr >= 16 se llega a desactivar block_lock, en caso contrario, permanece activo
module tb_deactivate_block_lock;

	parameter DATA_WIDTH_TB          = 64 ;			
	parameter CTRL_WIDTH_TB          = (DATA_WIDTH_TB/8);	
	parameter HDR_WIDTH_TB           = 2  ;			
	parameter BIT_REVERSE_TB         = 0  ;			
	parameter SCRAMBLER_DISABLE_TB   = 0  ;		
	parameter PRBS31_ENABLE_TB       = 1  ;		
	parameter TX_SERDES_PIPELINE_TB  = 0  ;		
	parameter RX_SERDES_PIPELINE_TB  = 0  ;		
	parameter BITSLIP_HIGH_CYCLES_TB = 1  ;		
	parameter BITSLIP_LOW_CYCLES_TB  = 8  ;		
	parameter COUNT_125US_TB         = 125;	

	reg rx_clk_tb;
	reg tx_clk_tb;
	reg rx_rst_tb;
	reg tx_rst_tb;

	reg  [DATA_WIDTH_TB-1:0] xgmii_txd_tb;
	reg  [CTRL_WIDTH_TB-1:0] xgmii_txc_tb;
	wire [DATA_WIDTH_TB-1:0] xgmii_rxd_tb;
	wire [CTRL_WIDTH_TB-1:0] xgmii_rxc_tb;

	wire [DATA_WIDTH_TB-1:0] serdes_tx_data_tb     ;
	wire [HDR_WIDTH_TB-1:0 ] serdes_tx_hdr_tb      ;
	reg  [DATA_WIDTH_TB-1:0] serdes_rx_data_tb     ;
	reg  [HDR_WIDTH_TB-1:0 ] serdes_rx_hdr_tb      ;
	wire                     serdes_rx_bitslip_tb  ;
	wire                     serdes_rx_reset_req_tb;

	wire       tx_bad_block_tb     ;
	wire [6:0] rx_error_count_tb   ;
	wire       rx_bad_block_tb     ;
	wire       rx_sequence_error_tb;
	wire       rx_block_lock_tb    ;
	wire       rx_high_ber_tb      ;
	wire       rx_status_tb        ;

	reg cfg_tx_prbs31_enable_tb;
	reg cfg_rx_prbs31_enable_tb;

	integer count        ;
	integer count_hdr    ;
    integer count_inv_hdr;

    initial begin
        $dumpfile("tb_deactivate_block_lock.vcd");
        $dumpvars(0, tb_deactivate_block_lock);
    end

    eth_phy_10g #(
        .DATA_WIDTH         (DATA_WIDTH_TB         ),
        .CTRL_WIDTH         (CTRL_WIDTH_TB         ),
        .HDR_WIDTH          (HDR_WIDTH_TB          ),
        .BIT_REVERSE        (BIT_REVERSE_TB        ),
        .SCRAMBLER_DISABLE  (SCRAMBLER_DISABLE_TB  ),
        .PRBS31_ENABLE      (PRBS31_ENABLE_TB      ),
        .TX_SERDES_PIPELINE (TX_SERDES_PIPELINE_TB ),
        .RX_SERDES_PIPELINE (RX_SERDES_PIPELINE_TB ),
        .BITSLIP_HIGH_CYCLES(BITSLIP_HIGH_CYCLES_TB),
        .BITSLIP_LOW_CYCLES (BITSLIP_LOW_CYCLES_TB ),
        .COUNT_125US        (COUNT_125US_TB        )
    )

    eth_phy_10g_inst (
        .rx_clk              (rx_clk_tb              ),
        .rx_rst              (rx_rst_tb              ),
        .tx_clk              (tx_clk_tb              ),
        .tx_rst              (tx_rst_tb              ),
        .xgmii_txd           (xgmii_txd_tb           ),
        .xgmii_txc           (xgmii_txc_tb           ),
        .xgmii_rxd           (xgmii_rxd_tb           ),
        .xgmii_rxc           (xgmii_rxc_tb           ),
        .serdes_tx_data      (serdes_tx_data_tb      ),
        .serdes_tx_hdr       (serdes_tx_hdr_tb       ),
        .serdes_rx_data      (serdes_rx_data_tb      ),
        .serdes_rx_hdr       (serdes_rx_hdr_tb       ),
        .serdes_rx_bitslip   (serdes_rx_bitslip_tb   ),
        .serdes_rx_reset_req (serdes_rx_reset_req_tb ),
        .tx_bad_block        (tx_bad_block_tb        ),
        .rx_error_count      (rx_error_count_tb      ),
        .rx_bad_block        (rx_bad_block_tb        ),
        .rx_sequence_error   (rx_sequence_error_tb   ),
        .rx_block_lock       (rx_block_lock_tb       ),
        .rx_high_ber         (rx_high_ber_tb         ),
        .rx_status           (rx_status_tb           ),
        .cfg_tx_prbs31_enable(cfg_tx_prbs31_enable_tb),
        .cfg_rx_prbs31_enable(cfg_rx_prbs31_enable_tb)
    );

    // Generacion de clock
    always #5 tx_clk_tb <= ~tx_clk_tb; 
    always #5 rx_clk_tb <= ~rx_clk_tb; 

	always @(posedge rx_clk_tb or posedge rx_rst_tb) begin
		if (rx_rst_tb) begin

            serdes_rx_data_tb <= 64'b0;
            serdes_rx_hdr_tb  <= 2'b0 ;
		    count_hdr         <= 0    ;
            count_inv_hdr     <= 0    ;

    	end else begin

			serdes_rx_data_tb <= serdes_tx_data_tb;
            serdes_rx_hdr_tb  <= serdes_tx_hdr_tb ;

            if (serdes_rx_hdr_tb == 2'b10 || serdes_rx_hdr_tb == 2'b01) begin
				count_hdr <= count_hdr + 1;
                if ((count_hdr >= 200) && (count_inv_hdr <= 15) && ((count_hdr+count_inv_hdr) % 3)) begin    // cambiando la condicion de count_inv_hdr se activa o no el block_lock
                    serdes_rx_hdr_tb <= 2'b00;                                          // la condicion count_hdr es para comprobar que no es necesario que los header invalidos sean consecutivos
                    count_inv_hdr <= count_inv_hdr + 1;
                end
            end
            
		end

	end

    always @(posedge tx_clk_tb) begin
        if (!tx_rst_tb) begin

            count <= count + 1;
            if (count == 6) begin
				count <= 0;
			end

			case (count)
				0: xgmii_txd_tb <= 64'hFFFFFFFFFFFFFFFF;
				1: xgmii_txd_tb <= 64'h0;
				2: xgmii_txd_tb <= 64'h5555555555555555;
				3: xgmii_txd_tb <= 64'hAAAAAAAAAAAAAAAA;
				4: xgmii_txd_tb <= 64'hFEFEFEFEFEFEFEFE;
				5: xgmii_txd_tb <= 64'h0707070707070707;
			endcase
			#50;
        end
	end

    always @(posedge tx_rst_tb) begin
        @(posedge tx_clk_tb);
        count        <= 0;
        xgmii_txc_tb <= 8'h00;
        xgmii_txd_tb <= 64'hFFFFFFFFFFFFFFFF;
    end


    // Configuracion inicial de Tx
    initial begin
        cfg_tx_prbs31_enable_tb = 0;

        tx_clk_tb    = 1'b0;
        tx_rst_tb    = 1'b1;

        xgmii_txc_tb = 8'h00;
		xgmii_txd_tb = 64'hFFFFFFFFFFFFFFFF;

        #1000;
		@(posedge tx_clk_tb);
        tx_rst_tb = 1'b0;

    end

    // Configuracion inicial de Rx
    initial begin

    	cfg_rx_prbs31_enable_tb = 0;
	    
		rx_clk_tb    = 1'b0;
        rx_rst_tb    = 1'b1;

		serdes_rx_data_tb = 64'h0;
		serdes_rx_hdr_tb  = 2'b0;

        #1000;
		@(posedge rx_clk_tb);
        rx_rst_tb = 1'b0;
	    
    end

    // Configuracion inicial general
    initial begin
        count            = 0;   // Contador para iterar patron de xgmii_txd
        count_hdr        = 0;   // Contador de encabezados validos
        count_inv_hdr    = 0;   // Contador de encabezados invalidos

        #10000
        @(posedge rx_clk_tb);
        rx_rst_tb = 1'b1;
        #1000
        @(posedge rx_clk_tb);
        rx_rst_tb = 1'b0;
        #5000
        @(posedge tx_clk_tb);
        tx_rst_tb = 1'b1;
        #5000
        @(posedge tx_clk_tb);
        tx_rst_tb = 1'b0;
        #10000
        $finish;
    end

endmodule
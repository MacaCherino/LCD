/*

Copyright (c) 2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * 10G Ethernet PHY aligner
 */
module eth_phy_10g_rx_aligner
#(
    parameter HDR_WIDTH  = 2,
    parameter DATA_WIDTH = 64
)
(
    input  wire                   clk,
    input  wire                   rst,

    /*
     * SERDES interface
     */
    input  wire [HDR_WIDTH-1:0 ]  i_serdes_rx_hdr ,
    input  wire [DATA_WIDTH-1:0]  i_serdes_rx_data,

    output wire [HDR_WIDTH-1:0 ]  o_serdes_rx_hdr_align ,
    output wire [DATA_WIDTH-1:0]  o_serdes_rx_data_align, 
    output wire                   o_aligned

);

localparam [1:0]
    SYNC_DATA = 2'b10,
    SYNC_CTRL = 2'b01;

reg [5:0]            sh_count_reg        , sh_count_next        ;
reg [3:0]            sh_invalid_count_reg, sh_invalid_count_next;
reg [DATA_WIDTH-1:0] serdes_rx_data_reg  , serdes_rx_data_next  ;
reg [HDR_WIDTH-1:0 ] serdes_rx_hdr_reg   , serdes_rx_hdr_next   ;
reg                  aligned_reg         , aligned_next         ;

always @* begin
    sh_count_next         = sh_count_reg        ;
    sh_invalid_count_next = sh_invalid_count_reg;

    serdes_rx_data_next   = serdes_rx_data_reg  ;
    serdes_rx_hdr_next    = serdes_rx_hdr_reg   ;

    aligned_next          = aligned_reg         ;

    if (i_serdes_rx_hdr == SYNC_CTRL || i_serdes_rx_hdr == SYNC_DATA) begin
        // valid header
        sh_count_next = sh_count_reg + 1;

        if (&sh_count_reg) begin
            // valid count overflow, reset
            sh_count_next         = 0;
            sh_invalid_count_next = 0;
            if (!sh_invalid_count_reg) begin
                aligned_next = 1'b1;
            end
        end
    end else begin
        // invalid header
        sh_count_next         = sh_count_reg + 1        ;
        sh_invalid_count_next = sh_invalid_count_reg + 1;
        if (!aligned_reg || &sh_invalid_count_reg) begin
            // invalid count overflow, lost alignenment
            sh_count_next         = 6'b0;
            sh_invalid_count_next =  'd0;
            aligned_next          = 1'b0;

            // shift one bit
            serdes_rx_data_next = {i_serdes_rx_data[DATA_WIDTH-2:0],i_serdes_rx_hdr [HDR_WIDTH-1 ]};  // el ultimo bit deberia ser el primero de la siguiente trama pero para probar voy a considerar que es el primero del hdr
            serdes_rx_hdr_next  = {i_serdes_rx_hdr [0]             ,i_serdes_rx_data[DATA_WIDTH-1]};
        end else if (&sh_count_reg) begin
            // valid count overflow, reset
            sh_count_next         = 0;
            sh_invalid_count_next = 0;
        end
    end
end

always @(posedge clk) begin

    if (rst) begin
        sh_count_reg         <= 6'b0 ;
        sh_invalid_count_reg <= 4'b0 ;
        serdes_rx_hdr_reg    <= 2'b0 ;
        serdes_rx_data_reg   <= 64'b0;
        aligned_reg          <= 1'b0 ;
    end else begin
        sh_count_reg         <= sh_count_next        ;
        sh_invalid_count_reg <= sh_invalid_count_next;
        serdes_rx_hdr_reg    <= serdes_rx_hdr_next   ;
        serdes_rx_data_reg   <= serdes_rx_data_next  ;
        aligned_reg          <= aligned_next         ;
    end
end

assign o_serdes_rx_hdr_align  = serdes_rx_hdr_reg ;
assign o_serdes_rx_data_align = serdes_rx_data_reg;
assign o_aligned              = aligned_reg       ;

endmodule

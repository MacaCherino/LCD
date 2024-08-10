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
module eth_phy_10g_rx_aligner_v3
#(
    parameter HDR_WIDTH  = 2,
    parameter DATA_WIDTH = 64
)
(

    output wire [HDR_WIDTH  - 1 : 0] o_serdes_rx_hdr_align ,
    output wire [DATA_WIDTH - 1 : 0] o_serdes_rx_data_align, 
    output wire                      o_rx_block_lock       ,
    output wire                      o_serdes_rx_bitslip   ,

    input  wire [HDR_WIDTH  - 1 : 0] i_serdes_rx_hdr       ,
    input  wire [DATA_WIDTH - 1 : 0] i_serdes_rx_data      ,

    input  wire                      clk                   ,
    input  wire                      rst

);

localparam [1:0]
    SYNC_DATA = 2'b10,
    SYNC_CTRL = 2'b01;

localparam [2:0]
    LOCK_INIT  = 3'b000,
    RESET_CNT  = 3'b001,
    TEST_SH    = 3'b010,
    VALID_SH   = 3'b011,
    INVALID_SH = 3'b100,
    GOOD       = 3'b101,
    SLIP       = 3'b110;

localparam [6 : 0] TOTAL_WIDTH = DATA_WIDTH + HDR_WIDTH;


reg [5                 : 0] sh_count_reg         ;
reg [3                 : 0] sh_invalid_count_reg ;
reg [DATA_WIDTH    - 1 : 0] serdes_rx_data_reg   ;
reg [HDR_WIDTH     - 1 : 0] serdes_rx_hdr_reg    ;
reg [2                 : 0] state_reg            ;
reg                         rx_block_lock_reg    ;
reg                         serdes_rx_bitslip_reg;
reg [6                 : 0] bitslip_count_reg    ;
reg [TOTAL_WIDTH   - 1 : 0] serdes_rx_reg        ;
reg [TOTAL_WIDTH   - 1 : 0] serdes_rx_prev_reg   ;
reg [TOTAL_WIDTH*2 - 1 : 0] serdes_rx_two_reg    ;

always @(*) begin
    case(state_reg)

        LOCK_INIT: begin
            rx_block_lock_reg     = 1'b0                                            ;
            sh_count_reg          = 6'b0                                            ;
            sh_invalid_count_reg  = 4'b0                                            ;
            bitslip_count_reg     = 7'b0                                            ;
            serdes_rx_bitslip_reg = 1'b0                                            ;
            serdes_rx_prev_reg    = 64'b0                                           ;
            serdes_rx_reg         = {i_serdes_rx_hdr    , i_serdes_rx_data}         ;
            serdes_rx_two_reg     = {serdes_rx_prev_reg , serdes_rx_reg   }         ;
        end

        RESET_CNT: begin
            rx_block_lock_reg     = rx_block_lock_reg                               ;
            sh_count_reg          = 6'b0                                            ;
            sh_invalid_count_reg  = 4'b0                                            ;
            bitslip_count_reg     = bitslip_count_reg                               ;
            serdes_rx_bitslip_reg = 1'b0                                            ;
            serdes_rx_prev_reg    = serdes_rx_reg                                   ;
            serdes_rx_reg         = {i_serdes_rx_hdr    , i_serdes_rx_data}         ;
            serdes_rx_two_reg     = {serdes_rx_prev_reg , serdes_rx_reg   }         ;
        end

        TEST_SH: begin
            rx_block_lock_reg     = rx_block_lock_reg                               ;
            sh_count_reg          = sh_count_reg                                    ;
            sh_invalid_count_reg  = sh_invalid_count_reg                            ;
            bitslip_count_reg     = bitslip_count_reg                               ;
            serdes_rx_bitslip_reg = serdes_rx_bitslip_reg                           ;
            serdes_rx_prev_reg    = serdes_rx_reg                                   ;
            serdes_rx_reg         = {i_serdes_rx_hdr    , i_serdes_rx_data}         ;
            serdes_rx_two_reg     = {serdes_rx_prev_reg , serdes_rx_reg   }         ;
        end

        VALID_SH: begin
            rx_block_lock_reg     = rx_block_lock_reg                               ;
            sh_count_reg          = sh_count_reg + 1                                ;
            sh_invalid_count_reg  = sh_invalid_count_reg                            ;
            bitslip_count_reg     = bitslip_count_reg                               ;
            serdes_rx_bitslip_reg = serdes_rx_bitslip_reg                           ;
            serdes_rx_prev_reg    = serdes_rx_reg                                   ;
            serdes_rx_reg         = {i_serdes_rx_hdr    , i_serdes_rx_data}         ;
            serdes_rx_two_reg     = {serdes_rx_prev_reg , serdes_rx_reg   }         ;
        end

        INVALID_SH: begin
            rx_block_lock_reg     = rx_block_lock_reg                               ;
            sh_count_reg          = sh_count_reg + 1                                ;
            sh_invalid_count_reg  = sh_invalid_count_reg + 1                        ;
            bitslip_count_reg     = bitslip_count_reg                               ;
            serdes_rx_bitslip_reg = serdes_rx_bitslip_reg                           ;
            serdes_rx_prev_reg    = serdes_rx_reg                                   ;
            serdes_rx_reg         = {i_serdes_rx_hdr    , i_serdes_rx_data}         ;
            serdes_rx_two_reg     = {serdes_rx_prev_reg , serdes_rx_reg   }         ;
        end

        GOOD: begin
            rx_block_lock_reg     = 1'b1                                            ;
            sh_count_reg          = sh_count_reg                                    ;
            sh_invalid_count_reg  = sh_invalid_count_reg                            ;
            bitslip_count_reg     = bitslip_count_reg                               ;
            serdes_rx_bitslip_reg = serdes_rx_bitslip_reg                           ;
            serdes_rx_prev_reg    = serdes_rx_reg                                   ;
            serdes_rx_reg         = {i_serdes_rx_hdr    , i_serdes_rx_data}         ;
            serdes_rx_two_reg     = {serdes_rx_prev_reg , serdes_rx_reg   }         ;
        end

        SLIP: begin
            rx_block_lock_reg     = 1'b0                                            ;
            sh_count_reg          = sh_count_reg                                    ;
            sh_invalid_count_reg  = sh_invalid_count_reg                            ;
            bitslip_count_reg     = bitslip_count_reg + 1                           ;
            serdes_rx_bitslip_reg = 1'b1                                            ;
            serdes_rx_prev_reg    = serdes_rx_reg                                   ;
            serdes_rx_reg         = {i_serdes_rx_hdr    , i_serdes_rx_data}         ;
            serdes_rx_two_reg     = {serdes_rx_prev_reg , serdes_rx_reg   }         ;
        end

        default: begin
            rx_block_lock_reg     = 1'b0                                            ;
            sh_count_reg          = 6'b0                                            ;
            sh_invalid_count_reg  = 4'b0                                            ;
            bitslip_count_reg     = 7'b0                                            ;
            serdes_rx_bitslip_reg = 1'b0                                            ;
            serdes_rx_prev_reg    = {i_serdes_rx_hdr , i_serdes_rx_data}            ;
            serdes_rx_reg         = {i_serdes_rx_hdr , i_serdes_rx_data}            ;
        end
    endcase
end

always @(posedge clk) begin

    if (rst) begin

        state_reg             <= LOCK_INIT;
        serdes_rx_hdr_reg     <= 2'b0     ;
        serdes_rx_data_reg    <= 64'b0    ;
        

    end else begin
        serdes_rx_hdr_reg     <= serdes_rx_two_reg[bitslip_count_reg +: HDR_WIDTH];
        serdes_rx_data_reg    <= serdes_rx_two_reg[bitslip_count_reg +: DATA_WIDTH];
        case(state_reg)

            LOCK_INIT: begin
                state_reg <= RESET_CNT;
            end

            RESET_CNT: begin
                state_reg <= TEST_SH;
            end

            TEST_SH: begin
                if (serdes_rx_hdr_reg == SYNC_CTRL || serdes_rx_hdr_reg == SYNC_DATA) begin
                    state_reg <= VALID_SH;
                end else begin
                    state_reg <= INVALID_SH;
                end
            end

            VALID_SH: begin
                if (&sh_count_reg) begin
                    if (sh_invalid_count_reg == 0) begin
                        state_reg <= GOOD;
                    end else begin
                        state_reg <= RESET_CNT;
                    end
                end else begin
                    state_reg <= TEST_SH;
                end
            end

            INVALID_SH: begin
                if (&sh_invalid_count_reg || !rx_block_lock_reg) begin
                    state_reg <= SLIP;
                end else begin
                    if (&sh_count_reg) begin
                        state_reg <= RESET_CNT;
                    end else begin
                        state_reg <= TEST_SH;
                    end
                end
            end

            GOOD: begin
                state_reg <= RESET_CNT;
            end

            SLIP: begin
                state_reg <= RESET_CNT;
            end

            default: begin
                state_reg <= LOCK_INIT;
            end

        endcase
    end
end

assign o_serdes_rx_hdr_align  = serdes_rx_hdr_reg    ;
assign o_serdes_rx_data_align = serdes_rx_data_reg   ;
assign o_rx_block_lock        = rx_block_lock_reg    ;
assign o_serdes_rx_bitslip    = serdes_rx_bitslip_reg;

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.05.2026 12:23:30
// Design Name: 
// Module Name: apb_spi
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module apb_spi
(
    input  logic        PCLK,
    input  logic        PRESETn,

    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic        PWRITE,

    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,

    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR,

    output logic        sclk,
    output logic        mosi,
    input  logic        miso,
    output logic        cs
);

localparam SPI_ADDR = 32'h0000_0000;

logic [31:0] tx_reg;
logic [31:0] rx_reg;

logic [31:0] tx_shift;
logic [31:0] rx_shift;

logic [5:0] bit_cnt;

typedef enum logic [1:0]
{
    IDLE,
    TRANSFER,
    DONE
} spi_state_t;

spi_state_t state;

always_ff @(posedge PCLK or negedge PRESETn)
begin
    if(!PRESETn)
    begin
        tx_reg   <= 0;
        rx_reg   <= 0;

        tx_shift <= 0;
        rx_shift <= 0;

        bit_cnt  <= 0;

        state    <= IDLE;

        sclk     <= 0;
        mosi     <= 0;
        cs       <= 1;
    end
    else
    begin

        //----------------------------------
        // APB WRITE = START SPI
        //----------------------------------
        if(PSEL && PENABLE && PWRITE &&
           PADDR == SPI_ADDR &&
           state == IDLE)
        begin

            tx_reg   <= PWDATA;

            tx_shift <= PWDATA;
            rx_shift <= 0;

            bit_cnt  <= 0;

            cs       <= 0;

            state    <= TRANSFER;

        end

        //----------------------------------
        // SPI FSM
        //----------------------------------
        case(state)

            IDLE:
            begin
                sclk <= 0;
                cs   <= 1;
            end

            TRANSFER:
            begin

                sclk <= ~sclk;

                if(sclk == 0)
                begin

                    mosi <= tx_shift[31];

                    tx_shift <=
                    {
                        tx_shift[30:0],
                        1'b0
                    };

                    rx_shift <=
                    {
                        rx_shift[30:0],
                        miso
                    };

                    if(bit_cnt == 31)
                        state <= DONE;
                    else
                        bit_cnt <= bit_cnt + 1;

                end

            end

            DONE:
            begin

                cs   <= 1;
                sclk <= 0;

                rx_reg <= rx_shift;

                state <= IDLE;

            end

        endcase

    end
end

//----------------------------------
// APB READ
//----------------------------------

always_comb
begin

    PRDATA = 32'h0;

    if(PSEL && !PWRITE)
    begin

        if(PADDR == SPI_ADDR)
            PRDATA = rx_reg;
        else
            PRDATA = 32'hDEADBEEF;

    end

end

assign PREADY  = 1'b1;

assign PSLVERR =
       (PSEL && PENABLE && (PADDR != SPI_ADDR));

endmodule

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

    // local_addr from apb_top maps SPI_TXDATA_ADDR (32'h0002_0000) down to zero
    localparam SPI_ADDR = 32'h0000_0000;

    logic [31:0] tx_reg;
    logic [31:0] rx_reg;

    logic [31:0] tx_shift;
    logic [31:0] rx_shift;

    logic [5:0]  bit_cnt;

    typedef enum logic [1:0]
    {
        IDLE,
        TRANSFER,
        DONE
    } spi_state_t;

    spi_state_t state;

    //=====================================================
    // SPI ENGINE & APB REGISTER WRITE
    //=====================================================
    always_ff @(posedge PCLK or negedge PRESETn)
    begin
        if(!PRESETn)
        begin
            tx_reg   <= 32'h0;
            rx_reg   <= 32'h0;
            tx_shift <= 32'h0;
            rx_shift <= 32'h0;
            bit_cnt  <= 6'd0;
            state    <= IDLE;
            sclk     <= 1'b0;
            mosi     <= 1'b0;
            cs       <= 1'b1;
        end
        else
        begin
            case(state)

                IDLE:
                begin
                    sclk <= 1'b0;
                    cs   <= 1'b1;

                    // Trigger the SPI engine only on a valid write setup/access phase
                    if(PSEL && PENABLE && PWRITE && (PADDR == SPI_ADDR)) 
                    begin
                        tx_reg   <= PWDATA;
                        tx_shift <= PWDATA;
                        rx_shift <= 32'h0;
                        bit_cnt  <= 6'd0;
                        cs       <= 1'b0; // Drop chip-select to start physical transfer
                        state    <= TRANSFER;
                    end
                end

                TRANSFER:
                begin
                    sclk <= ~sclk; // Toggle SPI Clock

                    // Sample/Shift on falling edges of our internal generated sclk logic
                    if(sclk == 1'b0)
                    begin
                        mosi <= tx_shift[31];

                        tx_shift <= {tx_shift[30:0], 1'b0};
                        rx_shift <= {rx_shift[30:0], miso};

                        if(bit_cnt == 6'd31)
                            state <= DONE;
                        else
                            bit_cnt <= bit_cnt + 1'b1;
                    end
                end

                DONE:
                begin
                    cs     <= 1'b1; // Pull CS high
                    sclk   <= 1'b0;
                    rx_reg <= rx_shift; // Save captured word to readable register
                    state  <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

    //=====================================================
    // APB READ COMBINATIONAL LOGIC
    //=====================================================
    always_comb
    begin
        PRDATA = 32'h0;
        if(PSEL && !PWRITE)
        begin
            if(PADDR == SPI_ADDR)
                PRDATA = rx_reg;
            else
                PRDATA = 32'hDEADBEEF; // Unmapped read target inside peripheral
        end
    end

    //=====================================================
    // APB STATUS / PROTOCOL HANDSHAKE SIGNALS
    //=====================================================
    
    // PREADY must stay high when IDLE so the master can execute its write instantly. 
    // If the master attempts to access the core mid-transfer, it forces wait states until IDLE.
    assign PREADY = (state == IDLE) ? 1'b1 : !(PSEL && PENABLE);

    // Assert protocol error if master attempts to access outside register range
    assign PSLVERR = (PSEL && PENABLE && (PADDR != SPI_ADDR));

endmodule

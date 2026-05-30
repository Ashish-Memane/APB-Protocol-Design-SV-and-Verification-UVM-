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
    logic        tx_valid; // Handshake flag indicating new data is ready to shift

    logic [31:0] tx_shift;
    logic [31:0] rx_shift;
    logic [5:0]  bit_cnt;

    typedef enum logic [1:0] { IDLE, TRANSFER, DONE } spi_state_t;
    spi_state_t state;

    //=====================================================
    // PHASE 1: APB BUS REGISTER LATCHING (Synchronous Interface)
    //=====================================================
    always_ff @(posedge PCLK or negedge PRESETn)
    begin
        if(!PRESETn) begin
            tx_reg   <= 32'h0;
            tx_valid <= 1'b0;
        end
        else begin
            // Clear valid flag once the SPI engine accepts the payload
            if (state == IDLE && tx_valid) begin
                tx_valid <= 1'b0;
            end

            // Capture incoming bus data immediately on a valid APB Access cycle
            if(PSEL && PENABLE && PWRITE && (PADDR == SPI_ADDR) && PREADY) begin
                tx_reg   <= PWDATA;
                tx_valid <= 1'b1;
            end
        end
    end

    //=====================================================
    // PHASE 2: SPI SERIAL ENGINE FSM (Background Processor)
    //=====================================================
    always_ff @(posedge PCLK or negedge PRESETn)
    begin
        if(!PRESETn)
        begin
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
                    mosi <= 1'b0;

                    // Start shifting only when a fresh register write is captured
                    if(tx_valid) begin
                        tx_shift <= tx_reg;
                        rx_shift <= 32'h0;
                        bit_cnt  <= 6'd0;
                        cs       <= 1'b0; 
                        state    <= TRANSFER;
                    end
                end

                TRANSFER:
                begin
                    sclk <= ~sclk;

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
                    cs     <= 1'b1;
                    sclk   <= 1'b0;
                    rx_reg <= rx_shift; 
                    state  <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    //=====================================================
    // PHASE 3: APB OUTPUT HANDSHAKE ROUTING
    //=====================================================
    always_comb
    begin
        PRDATA = 32'h0;
        if(PSEL && !PWRITE) begin
            if(PADDR == SPI_ADDR)
                PRDATA = rx_reg;
            else
                PRDATA = 32'hDEADBEEF;
        end
    end

    // Assert backpressure (PREADY=0) if a transaction is already active 
    // or if a newly written data payload is currently queued for shifting.
    assign PREADY = (state == IDLE && !tx_valid) ? 1'b1 : 1'b0;

    assign PSLVERR = (PSEL && PENABLE && (PADDR != SPI_ADDR));

endmodule

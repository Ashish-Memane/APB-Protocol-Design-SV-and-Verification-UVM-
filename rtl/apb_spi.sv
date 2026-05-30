`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ashish Memane
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

    //==================================================
    // APB INTERFACE
    //==================================================

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

    //==================================================
    // SPI INTERFACE
    //==================================================

    output logic sclk,
    output logic mosi,
    input  logic miso,
    output logic cs

);

    //==================================================
    // REGISTER MAP
    //==================================================

    localparam TXDATA_ADDR  = 32'h0000_0000;
    localparam RXDATA_ADDR  = 32'h0000_0004;
    localparam STATUS_ADDR  = 32'h0000_0008;
    localparam CONTROL_ADDR = 32'h0000_000C;

    //==================================================
    // INTERNAL REGISTERS
    //==================================================

    logic [31:0] tx_reg;
    logic [31:0] rx_reg;
    logic [31:0] status_reg;
    logic [31:0] control_reg;

    //--------------------------------------------------
    // STATUS BITS
    //--------------------------------------------------
    // status_reg[0] = busy
    // status_reg[1] = transfer_done
    //--------------------------------------------------

    //==================================================
    // SPI FSM
    //==================================================

    typedef enum logic [1:0]
    {
        IDLE,
        START,
        TRANSFER,
        DONE
    } spi_state_t;

    spi_state_t spi_state;

    //==================================================
    // SHIFT REGISTERS
    //==================================================

    logic [31:0] tx_shift_reg;
    logic [31:0] rx_shift_reg;

    logic [5:0] bit_count;

    //==================================================
    // APB HANDSHAKE
    //==================================================

    logic apb_write;

    assign apb_write =
            PSEL    &&
            PENABLE &&
            PWRITE  &&
            PREADY;

    //==================================================
    // MAIN LOGIC
    //==================================================

    always_ff @(posedge PCLK or negedge PRESETn)
    begin

        if(!PRESETn)
        begin

            //------------------------------------------
            // REGISTERS
            //------------------------------------------

            tx_reg      <= 32'h0;
            rx_reg      <= 32'h0;

            status_reg  <= 32'h0;
            control_reg <= 32'h0;

            //------------------------------------------
            // SHIFT REGISTERS
            //------------------------------------------

            tx_shift_reg <= 32'h0;
            rx_shift_reg <= 32'h0;

            //------------------------------------------
            // COUNTER
            //------------------------------------------

            bit_count <= 6'd0;

            //------------------------------------------
            // FSM
            //------------------------------------------

            spi_state <= IDLE;

            //------------------------------------------
            // SPI SIGNALS
            //------------------------------------------

            sclk <= 1'b0;
            mosi <= 1'b0;
            cs   <= 1'b1;

        end
        else
        begin

            //------------------------------------------
            // APB WRITE
            //------------------------------------------

            if(apb_write)
            begin

                case(PADDR)

                    //----------------------------------
                    // TX DATA REGISTER
                    //----------------------------------

                    TXDATA_ADDR:
                    begin

                        tx_reg <= PWDATA;

                    end

                    //----------------------------------
                    // CONTROL REGISTER
                    //----------------------------------

                    CONTROL_ADDR:
                    begin

                        control_reg <= PWDATA;

                        //----------------------------------
                        // START TRANSFER
                        //----------------------------------

                        if(PWDATA[0] && (spi_state == IDLE))
                        begin

                            //----------------------------------
                            // LOAD SHIFT REGISTERS
                            //----------------------------------

                            tx_shift_reg <= tx_reg;
                            rx_shift_reg <= 32'h0;

                            //----------------------------------
                            // RESET COUNTER
                            //----------------------------------

                            bit_count <= 6'd0;

                            //----------------------------------
                            // STATUS
                            //----------------------------------

                            status_reg[0] <= 1'b1;
                            status_reg[1] <= 1'b0;

                            //----------------------------------
                            // START FSM
                            //----------------------------------

                            spi_state <= START;

                        end

                    end

                    default:
                    begin
                        // DO NOTHING
                    end

                endcase

            end

            //------------------------------------------
            // SPI FSM
            //------------------------------------------

            case(spi_state)

                //--------------------------------------
                // IDLE
                //--------------------------------------

                IDLE:
                begin

                    sclk <= 1'b0;
                    cs   <= 1'b1;

                end

                //--------------------------------------
                // START
                //--------------------------------------

                START:
                begin

                    //----------------------------------
                    // ASSERT CHIP SELECT
                    //----------------------------------

                    cs <= 1'b0;

                    //----------------------------------
                    // MOVE TO TRANSFER
                    //----------------------------------

                    spi_state <= TRANSFER;

                end

                //--------------------------------------
                // TRANSFER
                //--------------------------------------

                TRANSFER:
                begin

                    //----------------------------------
                    // TOGGLE CLOCK
                    //----------------------------------

                    sclk <= ~sclk;

                    //----------------------------------
                    // SHIFT ON RISING EDGE
                    //----------------------------------

                    if(sclk == 1'b0)
                    begin

                        //----------------------------------
                        // DRIVE MOSI
                        //----------------------------------

                        mosi <= tx_shift_reg[31];

                        //----------------------------------
                        // SHIFT TX LEFT
                        //----------------------------------

                        tx_shift_reg <=
                        {
                            tx_shift_reg[30:0],
                            1'b0
                        };

                        //----------------------------------
                        // SAMPLE MISO
                        //----------------------------------

                        rx_shift_reg <=
                        {
                            rx_shift_reg[30:0],
                            miso
                        };

                        //----------------------------------
                        // BIT COUNT
                        //----------------------------------

                        if(bit_count == 6'd31)
                        begin

                            spi_state <= DONE;

                        end
                        else
                        begin

                            bit_count <= bit_count + 1'b1;

                        end

                    end

                end

                //--------------------------------------
                // DONE
                //--------------------------------------

                DONE:
                begin

                    //----------------------------------
                    // DEASSERT CHIP SELECT
                    //----------------------------------

                    cs <= 1'b1;

                    //----------------------------------
                    // STOP CLOCK
                    //----------------------------------

                    sclk <= 1'b0;

                    //----------------------------------
                    // STORE RX DATA
                    //----------------------------------

                    rx_reg <= rx_shift_reg;

                    //----------------------------------
                    // STATUS
                    //----------------------------------

                    status_reg[0] <= 1'b0;
                    status_reg[1] <= 1'b1;

                    //----------------------------------
                    // CLEAR START BIT
                    //----------------------------------

                    control_reg[0] <= 1'b0;

                    //----------------------------------
                    // RETURN TO IDLE
                    //----------------------------------

                    spi_state <= IDLE;

                end

            endcase

        end

    end

    //==================================================
    // APB READ LOGIC
    //==================================================

    always_comb
    begin

        PRDATA = 32'h0;

        if(PSEL && !PWRITE)
        begin

            case(PADDR)

                TXDATA_ADDR:
                    PRDATA = tx_reg;

                RXDATA_ADDR:
                    PRDATA = rx_reg;

                STATUS_ADDR:
                    PRDATA = status_reg;

                CONTROL_ADDR:
                    PRDATA = control_reg;

                default:
                    PRDATA = 32'hDEADBEEF;

            endcase

        end

    end

    //==================================================
    // APB READY
    //==================================================

    always_comb
    begin

        //----------------------------------------------
        // DEFAULT READY
        //----------------------------------------------

        PREADY = 1'b1;

        //----------------------------------------------
        // STALL DURING SPI TRANSFER
        //----------------------------------------------

        if((spi_state == START) ||
           (spi_state == TRANSFER))
        begin

            PREADY = 1'b0;

        end

    end

    //==================================================
    // APB ERROR
    //==================================================

    always_comb
    begin

        PSLVERR = 1'b0;

        if(PSEL && PENABLE)
        begin

            case(PADDR)

                TXDATA_ADDR,
                RXDATA_ADDR,
                STATUS_ADDR,
                CONTROL_ADDR:
                    PSLVERR = 1'b0;

                default:
                    PSLVERR = 1'b1;

            endcase

        end

    end

endmodule

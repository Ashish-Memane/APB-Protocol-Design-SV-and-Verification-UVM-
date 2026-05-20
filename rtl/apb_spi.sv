//////////////////////////////////////////////////////////////////////////////////
// Company: NA
// Engineer: Ashish Memane
// 
// Create Date: 19.05.2026 12:26:29
// Design Name: 
// Module Name: apb_spi
// Project Name: ABP_PROTOCOL_DESIGN
// Target Devices: 
// Tool Versions: VIVADO
// Description: APB_SPI
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module apb_spi (

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
    // 32-BIT SHIFT REGISTERS
    //==================================================

    logic [31:0] tx_shift_reg;
    logic [31:0] rx_shift_reg;

    logic [5:0] bit_count;

    //==================================================
    // APB WRITE + SPI FSM
    //==================================================

    always_ff @(posedge PCLK or negedge PRESETn)
    begin

        if (!PRESETn)
        begin

            tx_reg       <= 32'h0;
            rx_reg       <= 32'h0;

            status_reg   <= 32'h0;
            control_reg  <= 32'h0;

            tx_shift_reg <= 32'h0;
            rx_shift_reg <= 32'h0;

            bit_count    <= 6'd0;

            spi_state    <= IDLE;

            //------------------------------------------
            // DEFAULT SPI LINES
            //------------------------------------------

            sclk         <= 1'b0;
            mosi         <= 1'b0;
            cs           <= 1'b1;

        end
        else
        begin

            //--------------------------------------------------
            // CLEAR TRANSFER_DONE WHEN NEW START OCCURS
            //--------------------------------------------------

            if (control_reg[0])
                status_reg[1] <= 1'b0;

            //--------------------------------------------------
            // APB WRITE
            //--------------------------------------------------

            if (PSEL && PENABLE && PWRITE)
            begin

                case (PADDR)

                    //------------------------------------------
                    // TX DATA REGISTER
                    //------------------------------------------

                    TXDATA_ADDR:
                    begin

                        tx_reg <= PWDATA;

                    end

                    //------------------------------------------
                    // CONTROL REGISTER
                    //------------------------------------------

                    CONTROL_ADDR:
                    begin

                        control_reg <= PWDATA;

                        //--------------------------------------
                        // START TRANSFER
                        //--------------------------------------

                        if (PWDATA[0])
                        begin

                            //----------------------------------
                            // LOAD FULL 32-BIT DATA
                            //----------------------------------

                            tx_shift_reg <= tx_reg;

                            rx_shift_reg <= 32'h0;

                            bit_count <= 6'd0;

                            spi_state <= START;

                            //----------------------------------
                            // BUSY FLAG
                            //----------------------------------

                            status_reg[0] <= 1'b1;

                        end

                    end

                    default:
                    begin
                        // DO NOTHING
                    end

                endcase

            end

            //--------------------------------------------------
            // SPI FSM
            //--------------------------------------------------

            case (spi_state)

                //----------------------------------------------
                // IDLE
                //----------------------------------------------

                IDLE:
                begin

                    sclk <= 1'b0;
                    cs   <= 1'b1;

                end

                //----------------------------------------------
                // START
                //----------------------------------------------

                START:
                begin

                    //------------------------------------------
                    // ASSERT CHIP SELECT
                    //------------------------------------------

                    cs <= 1'b0;

                    spi_state <= TRANSFER;

                end

                //----------------------------------------------
                // TRANSFER
                //----------------------------------------------

                TRANSFER:
                begin

                    //------------------------------------------
                    // TOGGLE SPI CLOCK
                    //------------------------------------------

                    sclk <= ~sclk;

                    //------------------------------------------
                    // SHIFT ON RISING EDGE
                    //------------------------------------------

                    if (sclk == 1'b0)
                    begin

                        //--------------------------------------
                        // DRIVE MOSI
                        //--------------------------------------

                        mosi <= tx_shift_reg[31];

                        //--------------------------------------
                        // SHIFT TX LEFT
                        //--------------------------------------

                        tx_shift_reg <=
                        {
                            tx_shift_reg[30:0],
                            1'b0
                        };

                        //--------------------------------------
                        // SAMPLE MISO
                        //--------------------------------------

                        rx_shift_reg <=
                        {
                            rx_shift_reg[30:0],
                            miso
                        };

                        //--------------------------------------
                        // BIT COUNTER
                        //--------------------------------------

                        if (bit_count == 6'd31)
                        begin

                            spi_state <= DONE;

                        end
                        else
                        begin

                            bit_count <= bit_count + 1'b1;

                        end

                    end

                end

                //----------------------------------------------
                // DONE
                //----------------------------------------------

                DONE:
                begin

                    //------------------------------------------
                    // DEASSERT CHIP SELECT
                    //------------------------------------------

                    cs <= 1'b1;

                    //------------------------------------------
                    // STOP CLOCK
                    //------------------------------------------

                    sclk <= 1'b0;

                    //------------------------------------------
                    // STORE RECEIVED DATA
                    //------------------------------------------

                    rx_reg <= rx_shift_reg;

                    //------------------------------------------
                    // STATUS FLAGS
                    //------------------------------------------

                    status_reg[0] <= 1'b0;

                    status_reg[1] <= 1'b1;

                    //------------------------------------------
                    // CLEAR START BIT
                    //------------------------------------------

                    control_reg[0] <= 1'b0;

                    //------------------------------------------
                    // RETURN TO IDLE
                    //------------------------------------------

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

        PRDATA = 32'h00000000;

        if (PSEL && !PWRITE)
        begin

            case (PADDR)

                //----------------------------------------------
                // TXDATA
                //----------------------------------------------

                TXDATA_ADDR:
                begin

                    PRDATA = tx_reg;

                end

                //----------------------------------------------
                // RXDATA
                //----------------------------------------------

                RXDATA_ADDR:
                begin

                    PRDATA = rx_reg;

                end

                //----------------------------------------------
                // STATUS
                //----------------------------------------------

                STATUS_ADDR:
                begin

                    PRDATA = status_reg;

                end

                //----------------------------------------------
                // CONTROL
                //----------------------------------------------

                CONTROL_ADDR:
                begin

                    PRDATA = control_reg;

                end

                //----------------------------------------------
                // INVALID ADDRESS
                //----------------------------------------------

                default:
                begin

                    PRDATA = 32'hDEADBEEF;

                end

            endcase

        end

    end

    //==================================================
    // APB READY
    //==================================================

    assign PREADY = 1'b1;

    //==================================================
    // APB ERROR
    //==================================================

    always_comb
    begin

        PSLVERR = 1'b0;

        if (PSEL && PENABLE)
        begin

            case (PADDR)

                TXDATA_ADDR,
                RXDATA_ADDR,
                STATUS_ADDR,
                CONTROL_ADDR:
                begin

                    PSLVERR = 1'b0;

                end

                default:
                begin

                    PSLVERR = 1'b1;

                end

            endcase

        end

    end

endmodule

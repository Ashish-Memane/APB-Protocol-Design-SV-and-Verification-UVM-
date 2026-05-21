`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ashish Memane
// 
// Create Date: 18.05.2026 21:43:46
// Design Name: 
// Module Name: apb_uart
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: TESTBENCH FOR ABP_TOP
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module apb_uart
(
    //--------------------------------------------------
    // APB INTERFACE
    //--------------------------------------------------

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

    //--------------------------------------------------
    // UART INTERFACE
    //--------------------------------------------------

    output logic tx,
    input  logic rx
);

    //--------------------------------------------------
    // REGISTER MAP
    //--------------------------------------------------

    localparam TXDATA_ADDR = 32'h0000_0000;
    localparam RXDATA_ADDR = 32'h0000_0004;
    localparam STATUS_ADDR = 32'h0000_0008;

    //--------------------------------------------------
    // INTERNAL REGISTERS
    //--------------------------------------------------

    logic [31:0] tx_reg;
    logic [31:0] rx_reg;
    logic [31:0] status_reg;

    //--------------------------------------------------
    // STATUS REGISTER
    //--------------------------------------------------
    // status_reg[0] -> tx_busy
    // status_reg[1] -> rx_valid
    //--------------------------------------------------

    //--------------------------------------------------
    // UART STATES
    //--------------------------------------------------

    typedef enum logic [1:0]
    {
        IDLE,
        START,
        DATA,
        STOP
    } uart_state_t;

    uart_state_t tx_state;
    uart_state_t rx_state;

    //--------------------------------------------------
    // TX LOGIC
    //--------------------------------------------------

    logic [31:0] tx_shift_reg;
    logic [5:0] tx_count;

    logic       tx_start;

    //--------------------------------------------------
    // RX LOGIC
    //--------------------------------------------------

    logic [31:0] rx_shift_reg;
    logic [5:0] rx_count;

    //--------------------------------------------------
    // APB WRITE LOGIC
    //--------------------------------------------------

    always_ff @(posedge PCLK or negedge PRESETn)
    begin

        if(!PRESETn)
        begin

            tx_reg       <= 32'h0;
            tx_shift_reg <= 32'h00;

            tx_start     <= 1'b0;

        end
        else
        begin

            tx_start <= 1'b0;

            //------------------------------------------
            // VALID APB WRITE
            //------------------------------------------

            if(PSEL && PENABLE && PWRITE)
            begin

                case(PADDR)

                    //----------------------------------
                    // TXDATA REGISTER
                    //----------------------------------

                    TXDATA_ADDR:
                    begin

                        //--------------------------------
                        // STORE APB DATA
                        //--------------------------------

                        tx_reg <= PWDATA;

                        //--------------------------------
                        // LOAD UART BYTE
                        //--------------------------------

                        tx_shift_reg <= PWDATA[31:0];

                        //--------------------------------
                        // START UART TX
                        //--------------------------------

                        tx_start <= 1'b1;

                    end

                endcase

            end

        end

    end

    //--------------------------------------------------
    // UART TX FSM
    //--------------------------------------------------

    always_ff @(posedge PCLK or negedge PRESETn)
    begin

        if(!PRESETn)
        begin

            tx <= 1'b1;

            tx_state <= IDLE;

            tx_count <= 6'd0;

            status_reg[0] <= 1'b0;

        end
        else
        begin

            case(tx_state)

                //--------------------------------------
                // IDLE
                //--------------------------------------

                IDLE:
                begin

                    tx <= 1'b1;

                    if(tx_start)
                    begin

                        tx_count <= 6'd0;

                        tx_state <= START;

                        status_reg[0] <= 1'b1;

                    end

                end

                //--------------------------------------
                // START BIT
                //--------------------------------------

                START:
                begin

                    tx <= 1'b0;

                    tx_state <= DATA;

                end

                //--------------------------------------
                // DATA BITS
                //--------------------------------------

                DATA:
                begin

                    //----------------------------------
                    // UART SENDS LSB FIRST
                    //----------------------------------

                    tx <= tx_shift_reg[0];

                    //----------------------------------
                    // SHIFT RIGHT
                    //----------------------------------

                    tx_shift_reg <=
                    {
                        1'b0,
                        tx_shift_reg[31:1]
                    };

                    //----------------------------------
                    // BIT COUNT
                    //----------------------------------

                    if(tx_count == 32'd31)
                    begin

                        tx_state <= STOP;

                    end
                    else
                    begin

                        tx_count <= tx_count + 1'b1;

                    end

                end

                //--------------------------------------
                // STOP BIT
                //--------------------------------------

                STOP:
                begin

                    tx <= 1'b1;

                    tx_state <= IDLE;

                    //----------------------------------
                    // CLEAR BUSY
                    //----------------------------------

                    status_reg[0] <= 1'b0;

                end

            endcase

        end

    end

    //--------------------------------------------------
    // UART RX FSM
    //--------------------------------------------------

    always_ff @(posedge PCLK or negedge PRESETn)
    begin

        if(!PRESETn)
        begin

            rx_state <= IDLE;

            rx_shift_reg <= 32'h0000_0000;
            rx_count <= 6'd0;

            rx_reg <= 32'h0;

            status_reg[1] <= 1'b0;

        end
        else
        begin

            case(rx_state)

                //--------------------------------------
                // IDLE
                //--------------------------------------

                IDLE:
                begin

                    //----------------------------------
                    // DETECT START BIT
                    //----------------------------------

                    if(rx == 1'b0)
                    begin

                        rx_count <= 6'd0;

                        rx_state <= DATA;

                    end

                end

                //--------------------------------------
                // RECEIVE DATA
                //--------------------------------------

                DATA:
                begin

                    //----------------------------------
                    // RECEIVE LSB FIRST
                    //----------------------------------

                    rx_shift_reg <=
                    {
                        rx,
                        rx_shift_reg[31:1]
                    };

                    //----------------------------------
                    // COUNT BITS
                    //----------------------------------

                    if(rx_count == 32'd31)
                    begin

                        rx_state <= STOP;

                    end
                    else
                    begin

                        rx_count <= rx_count + 1'b1;

                    end

                end

                //--------------------------------------
                // STOP BIT
                //--------------------------------------

                STOP:
                begin

                    //----------------------------------
                    // STORE RECEIVED BYTE
                    //----------------------------------

                    rx_reg[31:0] <= rx_shift_reg;

                    //----------------------------------
                    // RX VALID
                    //----------------------------------

                    status_reg[1] <= 1'b1;

                    rx_state <= IDLE;

                end

            endcase

        end

    end

    //--------------------------------------------------
    // APB READ LOGIC
    //--------------------------------------------------

    always_comb
    begin

        PRDATA = 32'h00000000;

        if(PSEL && !PWRITE)
        begin

            case(PADDR)

                //--------------------------------------
                // TXDATA
                //--------------------------------------

                TXDATA_ADDR:
                    PRDATA = tx_reg;

                //--------------------------------------
                // RXDATA
                //--------------------------------------

                RXDATA_ADDR:
                    PRDATA = rx_reg;

                //--------------------------------------
                // STATUS
                //--------------------------------------

                STATUS_ADDR:
                    PRDATA = status_reg;

                //--------------------------------------
                // INVALID ADDRESS
                //--------------------------------------

                default:
                    PRDATA = 32'hDEADBEEF;

            endcase

        end

    end

    //--------------------------------------------------
    // APB READY
    //--------------------------------------------------

    assign PREADY = 1'b1;

    //--------------------------------------------------
    // APB ERROR
    //--------------------------------------------------

    always_comb
    begin

        PSLVERR = 1'b0;

        if(PSEL && PENABLE)
        begin

            case(PADDR)

                TXDATA_ADDR,
                RXDATA_ADDR,
                STATUS_ADDR:
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


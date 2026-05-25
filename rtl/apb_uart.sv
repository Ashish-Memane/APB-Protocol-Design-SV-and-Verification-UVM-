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
    // UART
    //--------------------------------------------------

    output logic tx,
    input logic rx
);

    //--------------------------------------------------
    // ADDRESS MAP
    //--------------------------------------------------

    localparam TXDATA_ADDR = 32'h0000_0000;
    localparam RXDATA_ADDR = 32'h0000_0004;
    localparam STATUS_ADDR = 32'h0000_0008;

    //--------------------------------------------------
    // REGISTERS
    //--------------------------------------------------

    logic [31:0] tx_reg;
    logic [31:0] rx_reg;
    logic [31:0] status_reg;

    //--------------------------------------------------
    // STATUS
    //--------------------------------------------------
    // status_reg[0] = tx_busy
    // status_reg[1] = rx_valid
    //--------------------------------------------------

    //--------------------------------------------------
    // UART TX FSM
    //--------------------------------------------------

    typedef enum logic [1:0]
    {
        IDLE,
        START,
        DATA,
        STOP
    } uart_state_t;

    uart_state_t tx_state;

    //--------------------------------------------------
    // TX LOGIC
    //--------------------------------------------------

    logic [31:0] tx_shift_32;
    logic [7:0]  tx_shift_8;

    logic [2:0]  bit_count;
    logic [1:0]  byte_count;

    logic        tx_start;
    
    //--------------------------------------------------
    // RX LOGIC
    //--------------------------------------------------
    
    logic [31:0] rx_shift_32;
    logic [7:0]  rx_shift_8;
    
    logic [2:0]  rx_bit_count;
    logic [1:0]  rx_byte_count;
    
    uart_state_t rx_state;
    
    //--------------------------------------------------
    // APB WRITE
    //--------------------------------------------------

    always_ff @(posedge PCLK or negedge PRESETn)
    begin

        if(!PRESETn)
        begin

            tx_reg   <= 32'h0;
            tx_start <= 1'b0;

        end
        else
        begin

            tx_start <= 1'b0;

            if(PSEL && PENABLE && PWRITE)
            begin

                case(PADDR)

                    TXDATA_ADDR:
                    begin

                        tx_reg   <= PWDATA;
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

            tx_shift_32 <= 32'h0;
            tx_shift_8  <= 8'h00;

            bit_count  <= 3'd0;
            byte_count <= 2'd0;

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

                        //----------------------------------
                        // LOAD 32-BIT DATA
                        //----------------------------------

                        tx_shift_32 <= tx_reg;

                        //----------------------------------
                        // LOAD FIRST BYTE
                        //----------------------------------

                        tx_shift_8 <= tx_reg[7:0];

                        //----------------------------------
                        // RESET COUNTERS
                        //----------------------------------

                        bit_count  <= 3'd0;
                        byte_count <= 2'd0;

                        //----------------------------------
                        // BUSY
                        //----------------------------------

                        status_reg[0] <= 1'b1;

                        //----------------------------------
                        // START TX
                        //----------------------------------

                        tx_state <= START;

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
                // SEND 8 DATA BITS
                //--------------------------------------

                DATA:
                begin

                    //----------------------------------
                    // SEND LSB FIRST
                    //----------------------------------

                    tx <= tx_shift_8[0];

                    //----------------------------------
                    // SHIFT RIGHT
                    //----------------------------------

                    tx_shift_8 <=
                    {
                        1'b0,
                        tx_shift_8[7:1]
                    };

                    //----------------------------------
                    // BIT COUNTER
                    //----------------------------------

                    if(bit_count == 3'd7)
                    begin

                        bit_count <= 3'd0;

                        tx_state <= STOP;

                    end
                    else
                    begin

                        bit_count <= bit_count + 1'b1;

                    end

                end

                //--------------------------------------
                // STOP BIT
                //--------------------------------------

                STOP:
                begin

                    tx <= 1'b1;

                    //----------------------------------
                    // ALL 4 BYTES SENT?
                    //----------------------------------

                    if(byte_count == 2'd3)
                    begin

                        //--------------------------------
                        // DONE
                        //--------------------------------

                        status_reg[0] <= 1'b0;

                        tx_state <= IDLE;

                    end
                    else
                    begin

                        //--------------------------------
                        // NEXT BYTE
                        //--------------------------------

                        byte_count <= byte_count + 1'b1;

                        //--------------------------------
                        // SHIFT 32-BIT REGISTER
                        //--------------------------------

                        tx_shift_32 <=
                        {
                            8'h00,
                            tx_shift_32[31:8]
                        };

                        //--------------------------------
                        // LOAD NEXT BYTE
                        //--------------------------------

                        tx_shift_8 <= tx_shift_32[15:8];

                        //--------------------------------
                        // NEXT FRAME
                        //--------------------------------

                        tx_state <= START;

                    end

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
    
            //rx <= 1'b1;
    
            rx_state <= IDLE;
    
            rx_shift_32 <= 32'h0;
            rx_shift_8  <= 8'h00;
    
            rx_bit_count  <= 3'd0;
            rx_byte_count <= 2'd0;
    
            rx_reg <= 32'h0;
    
            status_reg[1] <= 1'b0;
    
        end
        else
        begin
    
            //------------------------------------------
            // CLEAR RX VALID AFTER ONE CYCLE
            //------------------------------------------
    
            status_reg[1] <= 1'b0;
    
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
    
                        rx_bit_count <= 3'd0;
    
                        rx_shift_8 <= 8'h00;
    
                        rx_state <= DATA;
    
                    end
    
                end
    
                //--------------------------------------
                // RECEIVE 8 DATA BITS
                //--------------------------------------
    
                DATA:
                begin
    
                    //----------------------------------
                    // SHIFT IN SERIAL DATA
                    //----------------------------------
    
                    rx_shift_8 <=
                    {
                        rx,
                        rx_shift_8[7:1]
                    };
    
                    //----------------------------------
                    // BIT COUNTER
                    //----------------------------------
    
                    if(rx_bit_count == 3'd7)
                    begin
    
                        rx_bit_count <= 3'd0;
    
                        rx_state <= STOP;
    
                    end
                    else
                    begin
    
                        rx_bit_count <= rx_bit_count + 1'b1;
    
                    end
    
                end
    
                //--------------------------------------
                // STOP BIT
                //--------------------------------------
    
                STOP:
                begin
    
                    //----------------------------------
                    // STORE BYTE INTO 32-BIT REGISTER
                    //----------------------------------
    
                    rx_shift_32 <=
                    {
                        rx_shift_8,
                        rx_shift_32[31:8]
                    };
    
                    //----------------------------------
                    // ALL 4 BYTES RECEIVED?
                    //----------------------------------
    
                    if(rx_byte_count == 2'd3)
                    begin
    
                        //--------------------------------
                        // STORE FINAL RX DATA
                        //--------------------------------
    
                        rx_reg <=
                        {
                            rx_shift_8,
                            rx_shift_32[31:8]
                        };
    
                        //--------------------------------
                        // RX VALID
                        //--------------------------------
    
                        status_reg[1] <= 1'b1;
    
                        //--------------------------------
                        // RESET BYTE COUNT
                        //--------------------------------
    
                        rx_byte_count <= 2'd0;
    
                    end
                    else
                    begin
    
                        rx_byte_count <= rx_byte_count + 1'b1;
    
                    end
    
                    //----------------------------------
                    // RETURN TO IDLE
                    //----------------------------------
    
                    rx_state <= IDLE;
    
                end
    
            endcase
    
        end
    
    end

    //--------------------------------------------------
    // APB READ
    //--------------------------------------------------

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
                    PSLVERR = 1'b0;

                default:
                    PSLVERR = 1'b1;

            endcase

        end

    end

endmodule


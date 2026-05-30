`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ashish Memane
// 
// Create Date: 18.05.2026 17:39:56
// Design Name: 
// Module Name: apb_gpio
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

module apb_gpio
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
    // GPIO INTERFACE
    //--------------------------------------------------

    input  logic [31:0] gpio_in,
    output logic [31:0] gpio_out,
    output logic [31:0] gpio_dir
);

    //--------------------------------------------------
    // ADDRESS MAP
    //--------------------------------------------------

    localparam GPIO_OUT_ADDR = 32'h0000_0000;
    localparam GPIO_IN_ADDR  = 32'h0000_0004;
    localparam GPIO_DIR_ADDR = 32'h0000_0008;
    localparam STATUS_ADDR   = 32'h0000_000C;

    //--------------------------------------------------
    // INTERNAL REGISTERS
    //--------------------------------------------------

    logic [31:0] gpio_out_reg;
    logic [31:0] gpio_dir_reg;
    logic [31:0] status_reg;

    //--------------------------------------------------
    // STATUS BITS
    //--------------------------------------------------
    // status_reg[0] = busy
    //--------------------------------------------------

    //--------------------------------------------------
    // GPIO FSM
    //--------------------------------------------------

    typedef enum logic [1:0]
    {
        IDLE,
        BUSY
    } gpio_state_t;

    gpio_state_t state;

    //--------------------------------------------------
    // DELAY COUNTER
    //--------------------------------------------------

    logic [1:0] delay_cnt;

    //--------------------------------------------------
    // APB WRITE + GPIO FSM
    //--------------------------------------------------

    always_ff @(posedge PCLK or negedge PRESETn)
    begin

        if(!PRESETn)
        begin

            gpio_out_reg <= 32'h0;
            gpio_dir_reg <= 32'h0;

            status_reg   <= 32'h0;

            delay_cnt    <= 2'd0;

            state        <= IDLE;

        end
        else
        begin

            case(state)

                //--------------------------------------
                // IDLE
                //--------------------------------------

                IDLE:
                begin

                    status_reg[0] <= 1'b0;

                    //----------------------------------
                    // APB WRITE
                    //----------------------------------

                    if(PSEL && PENABLE && PWRITE)
                    begin

                        case(PADDR)

                            //----------------------------------
                            // GPIO OUTPUT
                            //----------------------------------

                            GPIO_OUT_ADDR:
                            begin

                                gpio_out_reg <= PWDATA;

                                //--------------------------------
                                // START BUSY
                                //--------------------------------

                                status_reg[0] <= 1'b1;

                                delay_cnt <= 2'd2;

                                state <= BUSY;

                            end

                            //----------------------------------
                            // GPIO DIRECTION
                            //----------------------------------

                            GPIO_DIR_ADDR:
                            begin

                                gpio_dir_reg <= PWDATA;

                                //--------------------------------
                                // START BUSY
                                //--------------------------------

                                status_reg[0] <= 1'b1;

                                delay_cnt <= 2'd2;

                                state <= BUSY;

                            end

                        endcase

                    end

                end

                //--------------------------------------
                // BUSY
                //--------------------------------------

                BUSY:
                begin

                    status_reg[0] <= 1'b1;

                    //----------------------------------
                    // DELAY
                    //----------------------------------

                    if(delay_cnt == 0)
                    begin

                        status_reg[0] <= 1'b0;

                        state <= IDLE;

                    end
                    else
                    begin

                        delay_cnt <= delay_cnt - 1'b1;

                    end

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

                GPIO_OUT_ADDR:
                    PRDATA = gpio_out_reg;

                GPIO_IN_ADDR:
                    PRDATA = gpio_in;

                GPIO_DIR_ADDR:
                    PRDATA = gpio_dir_reg;

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

    always_comb
    begin

        PREADY = 1'b1;

        //----------------------------------------------
        // STALL APB DURING GPIO BUSY
        //----------------------------------------------

        if(PSEL && PENABLE && status_reg[0])
        begin

            PREADY = 1'b0;

        end

    end

    //--------------------------------------------------
    // APB ERROR
    //--------------------------------------------------

    always_comb
    begin

        PSLVERR = 1'b0;

        if(PSEL && PENABLE)
        begin

            case(PADDR)

                GPIO_OUT_ADDR,
                GPIO_IN_ADDR,
                GPIO_DIR_ADDR,
                STATUS_ADDR:
                    PSLVERR = 1'b0;

                default:
                    PSLVERR = 1'b1;

            endcase

        end

    end

    //--------------------------------------------------
    // OUTPUT ASSIGNMENTS
    //--------------------------------------------------

    assign gpio_out = gpio_out_reg;
    assign gpio_dir = gpio_dir_reg;

endmodule

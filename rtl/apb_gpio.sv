//////////////////////////////////////////////////////////////////////////////////
// Company: NA
// Engineer: Ashish Memane
// 
// Create Date: 19.05.2026 12:26:29
// Design Name: 
// Module Name: apb_gpio
// Project Name: ABP_PROTOCOL_DESIGN
// Target Devices: 
// Tool Versions: VIVADO
// Description: APB_GPIO
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module apb_gpio (

    //==================================================
    // APB INTERFACE SIGNALS
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
    // GPIO INTERFACE SIGNALS
    //==================================================

    input  logic [31:0] gpio_in,
    output logic [31:0] gpio_out,
    output logic [31:0] gpio_dir

);

    //==================================================
    // INTERNAL REGISTERS
    //==================================================

    logic [31:0] gpio_out_reg;
    logic [31:0] gpio_dir_reg;

    //==================================================
    // ADDRESS MAP
    //==================================================
    //
    // 0x00 : GPIO_OUT
    // 0x04 : GPIO_IN
    // 0x08 : GPIO_DIR
    //
    //==================================================

    localparam GPIO_OUT_ADDR = 32'h0000_0000;
    localparam GPIO_IN_ADDR  = 32'h0000_0004;
    localparam GPIO_DIR_ADDR = 32'h0000_0008;

    //==================================================
    // APB WRITE OPERATION
    //==================================================

    always_ff @(posedge PCLK or negedge PRESETn)
    begin

        if (!PRESETn)
        begin

            gpio_out_reg <= 32'h0000_0000;
            gpio_dir_reg <= 32'h0000_0000;

        end
        else if (PSEL && PENABLE && PWRITE)
        begin

            case (PADDR)

                //------------------------------------------
                // GPIO OUTPUT REGISTER
                //------------------------------------------

                GPIO_OUT_ADDR:
                begin

                    gpio_out_reg <= PWDATA;

                end

                //------------------------------------------
                // GPIO DIRECTION REGISTER
                //------------------------------------------

                GPIO_DIR_ADDR:
                begin

                    gpio_dir_reg <= PWDATA;

                end

                default:
                begin
                    // DO NOTHING
                end

            endcase

        end

    end

    //==================================================
    // APB READ OPERATION
    //==================================================

    always_comb
    begin

        //----------------------------------------------
        // DEFAULT
        //----------------------------------------------

        PRDATA = 32'h0000_0000;

        //----------------------------------------------
        // APB READ
        //----------------------------------------------

        if (PSEL && !PWRITE)
        begin

            case (PADDR)

                //------------------------------------------
                // GPIO OUTPUT REGISTER
                //------------------------------------------

                GPIO_OUT_ADDR:
                begin

                    PRDATA = gpio_out_reg;

                end

                //------------------------------------------
                // GPIO INPUT REGISTER
                //------------------------------------------

                GPIO_IN_ADDR:
                begin

                    PRDATA = gpio_in;

                end

                //------------------------------------------
                // GPIO DIRECTION REGISTER
                //------------------------------------------

                GPIO_DIR_ADDR:
                begin

                    PRDATA = gpio_dir_reg;

                end

                //------------------------------------------
                // INVALID ADDRESS
                //------------------------------------------

                default:
                begin

                    PRDATA = 32'hDEADBEEF;

                end

            endcase

        end

    end

    //==================================================
    // GPIO OUTPUT ASSIGNMENTS
    //==================================================

    assign gpio_out = gpio_out_reg;

    assign gpio_dir = gpio_dir_reg;

    //==================================================
    // APB READY SIGNAL
    //==================================================

    assign PREADY = 1'b1;

    //==================================================
    // APB ERROR SIGNAL
    //==================================================

    always_comb
    begin

        PSLVERR = 1'b0;

        if (PSEL && PENABLE)
        begin

            case (PADDR)

                GPIO_OUT_ADDR,
                GPIO_IN_ADDR,
                GPIO_DIR_ADDR:
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

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ashish Memane
// 
// Create Date: 18.05.2026 17:39:56
// Design Name: gpio interface
// Module Name: gpio_interface
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
// gpio interface
interface gpio_interface(input logic PCLK, input logic PRESETn);


    logic [31:0] gpio_in;

    logic [31:0] gpio_out;
    logic [31:0] gpio_dir;

    //--------------------------------------------------
    // GPIO DRIVER CLOCKING BLOCK
    //--------------------------------------------------

    clocking gpio_drv_cb @(posedge PCLK);

        default input #1 output #1;

        //----------------------------------------------
        // DRIVE EXTERNAL GPIO INPUTS
        //----------------------------------------------

        output gpio_in;

        //----------------------------------------------
        // APB STATUS
        //----------------------------------------------

        //----------------------------------------------
        // DUT GPIO OUTPUTS
        //----------------------------------------------

        input gpio_out;
        input gpio_dir;

    endclocking : gpio_drv_cb

    //--------------------------------------------------
    // GPIO MONITOR CLOCKING BLOCK
    //--------------------------------------------------

    clocking gpio_mon_cb @(posedge PCLK);

        default input #1 output #1;

        //----------------------------------------------
        // APB SIGNALS
        //----------------------------------------------

        //----------------------------------------------
        // GPIO SIGNALS
        //----------------------------------------------

        input gpio_in;
        input gpio_out;
        input gpio_dir;

    endclocking : gpio_mon_cb

    //--------------------------------------------------
    // MODPORTS
    //--------------------------------------------------

    modport GPIO_DRV_MP (clocking gpio_drv_cb);

    modport GPIO_MON_MP (clocking gpio_mon_cb);

endinterface : gpio_interface

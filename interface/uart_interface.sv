//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ashish Memane
// 
// Create Date: 18.05.2026 17:39:56
// Design Name: uart interface
// Module Name: uart_interface
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
// uart interface
interface uart_interface(input logic PCLK, input logic PRESETn);

    //--------------------------------------------------
    // UART SIDE
    //--------------------------------------------------

    logic tx;
    logic rx;

    //--------------------------------------------------
    // UART DRIVER CLOCKING BLOCK
    //--------------------------------------------------

    clocking uart_drv_cb @(posedge PCLK);

        default input #1 output #1;

        //----------------------------------------------
        // UART RX STIMULUS
        //----------------------------------------------

        output rx;

        //----------------------------------------------
        // MONITORING
        //----------------------------------------------

        input tx;

    endclocking : uart_drv_cb

    //--------------------------------------------------
    // UART MONITOR CLOCKING BLOCK
    //--------------------------------------------------

    clocking uart_mon_cb @(posedge PCLK);

        default input #1 output #1;

        //----------------------------------------------
        // UART PINS
        //----------------------------------------------

        input rx;
        input tx;

        //----------------------------------------------
        // APB SIGNALS
        //----------------------------------------------

    endclocking : uart_mon_cb

    //--------------------------------------------------
    // MODPORTS
    //--------------------------------------------------

    modport UART_DRV_MP (clocking uart_drv_cb);

    modport UART_MON_MP (clocking uart_mon_cb);

endinterface : uart_interface


module top;

        // importing the packages
        import uvm_pkg::*;
        import apb_protocol_pkg::*;

        // including the macros
        `include "uvm_macros.svh"

        // clock declaration
        bit PCLK;

        // reset signal declaraion
        logic PRESETn;

        // interface instantiation
        apb_interface  apb_inf(PCLK, PRESETn);
        uart_interface uart_inf(PCLK, PRESETn);
        spi_interface  spi_inf(PCLK, PRESETn);
        gpio_interface gpio_inf(PCLK, PRESETn);

        // dut instantiation
        apb_top dut
        (
                        // master signals
                        .PCLK(PCLK),
                        .PRESETn(PRESETn),

                        .start(apb_inf.start),
                        .rw(apb_inf.rw),

                        .addr(apb_inf.addr),
                        .wdata(apb_inf.wdata),

                        .rdata(apb_inf.rdata),
                        .done(apb_inf.done),
                        .err(apb_inf.err),

                        // uart signals
                        .rx(uart_inf.rx),
                        .tx(uart_inf.tx),

                        // spi signals
                        .miso(spi_inf.miso),
                        .mosi(spi_inf.mosi),
                        .sclk(spi_inf.sclk),
                        .cs(spi_inf.cs),

                        // gpio signals
                        .gpio_in(gpio_inf.gpio_in),
                        .gpio_out(gpio_inf.gpio_out),
                        .gpio_dir(gpio_inf.gpio_dir)
        );


        // clock generation
        initial begin

                PCLK = 0;

                forever #5 PCLK = ~PCLK;

        end

        // reset generation
        initial begin

                PRESETn = 1'b0;

                repeat(5) @(posedge PCLK);

                PRESETn = 1'b1;

        end

        // setting virtual interfaces
        initial begin

                `ifdef VCS
                $fsdbDumpvars(0,top);
                `endif

                uvm_config_db#(virtual apb_interface)::set(null,"*","apb_interface",apb_inf);
                uvm_config_db#(virtual uart_interface)::set(null,"*","uart_interface",uart_inf);
                uvm_config_db#(virtual spi_interface)::set(null,"*","spi_interface",spi_inf);
                uvm_config_db#(virtual gpio_interface)::set(null,"*","gpio_interface",gpio_inf);

                // run the test
                run_test();

        end

endmodule

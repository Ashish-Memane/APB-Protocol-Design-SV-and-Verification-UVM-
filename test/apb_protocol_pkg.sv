package apb_protocol_pkg;

        int no_of_transactions = 10;

        // importing the uvm pkg
        import uvm_pkg::*;

        // include uvm macros
        `include "uvm_macros.svh"

        // tb files

        // config object
        `include "apb_agent_config.sv"
        `include "spi_agent_config.sv"
        `include "uart_agent_config.sv"
        `include "gpio_agent_config.sv"
        `include "apb_env_config.sv"

        // apb master
        `include "apb_xtn.sv"
        `include "apb_seqr.sv"
        `include "apb_seqs.sv"
        `include "apb_driver.sv"
        `include "apb_monitor.sv"
        `include "apb_agent.sv"
        `include "apb_agent_top.sv"

        // uart slave
        `include "uart_xtn.sv"
        `include "uart_seqr.sv"
        `include "uart_seqs.sv"
        `include "uart_driver.sv"
        `include "uart_monitor.sv"
        `include "uart_agent.sv"

        // spi slave
        `include "spi_xtn.sv"
        `include "spi_seqr.sv"
        `include "spi_seqs.sv"
        `include "spi_driver.sv"
        `include "spi_monitor.sv"
        `include "spi_agent.sv"

        // gpio slave
        `include "gpio_xtn.sv"
        `include "gpio_seqr.sv"
        `include "gpio_seqs.sv"
        `include "gpio_driver.sv"
        `include "gpio_monitor.sv"
        `include "gpio_agent.sv"

        // slave top
        `include "slave_agent_top.sv"

        // tb
        `include "apb_virtual_seqr.sv"
        `include "apb_virtual_seqs.sv"

        `include "scoreboard.sv"

        // env
        `include "apb_env.sv"

        // test
        `include "apb_vtest_lib.sv"

endpackage : apb_protocol_pkg

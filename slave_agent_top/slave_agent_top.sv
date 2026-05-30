// class slave agent top including agents of uart, spi, gpio
class slave_agent_top extends uvm_env;

        // factory registration
        `uvm_component_utils(slave_agent_top)

        // slave agent handles
        uart_agent uart_agt_h;
        spi_agent spi_agt_h;
        gpio_agent gpio_agt_h;

        // constructor
        function new(string name = "slave_agent_top", uvm_component parent);
                super.new(name,parent);
        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                uart_agt_h = uart_agent::type_id::create("uart_agt_h",this);
                spi_agt_h = spi_agent::type_id::create("spi_agt_h", this);
                gpio_agt_h = gpio_agent::type_id::create("gpio_agt_h", this);

        endfunction : build_phase

endclass : slave_agent_top

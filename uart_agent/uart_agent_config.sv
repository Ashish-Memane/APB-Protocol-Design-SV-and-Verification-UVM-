// uart agent config
class uart_agent_config extends uvm_object;

        // factory registration
        `uvm_object_utils(uart_agent_config)

        // interface declaration
        virtual uart_interface uart_vif;

        uvm_active_passive_enum is_active;

        int uart_mon_pkt_count = 0;

        // construction
        function new(string name = "uart_agent_config");
                super.new(name);
        endfunction : new

endclass : uart_agent_config

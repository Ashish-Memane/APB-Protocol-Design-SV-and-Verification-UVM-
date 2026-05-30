// gpio agent config object

class gpio_agent_config extends uvm_object;

        // factory registration
        `uvm_object_utils(gpio_agent_config)

        // interface declaration
        virtual gpio_interface gpio_vif;

        uvm_active_passive_enum is_active;

        int gpio_mon_pkt_count = 0;

        // constructor
        function new(string name = "gpio_agent_config");
                super.new(name);
        endfunction : new

endclass : gpio_agent_config

// spi config object
class spi_agent_config extends uvm_object;

        // factory registration
        `uvm_object_utils(spi_agent_config)

        // interface declaration
        virtual spi_interface spi_vif;

        uvm_active_passive_enum is_active;

        int spi_mon_pkt_count = 0;

        // constructor
        function new(string name = "spi_agent_config");
                super.new(name);
        endfunction : new

endclass : spi_agent_config

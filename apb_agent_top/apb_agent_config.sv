// apb config object
class apb_agent_config extends uvm_object;

        // factory registration
        `uvm_object_utils(apb_agent_config)

        // virtual interface declaration
        virtual apb_interface apb_vif;

        // passive active enum
        uvm_active_passive_enum is_active = UVM_ACTIVE;

        int apb_drv_pkt_count = 0;
        int apb_mon_pkt_count = 0;

        // constructor
        function new(string name = "apb_agent_config");
                super.new(name);
        endfunction : new

endclass : apb_agent_config

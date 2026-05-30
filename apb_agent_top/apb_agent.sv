// apb agent class
class apb_agent extends uvm_agent;

        // factory registration
        `uvm_component_utils(apb_agent)

        // config object
        apb_agent_config m_cfg;

        // component handles
        apb_driver drv_h;
        apb_monitor mon_h;
        apb_seqr seqr_h;

        // constructor
        function new (string name = "apb_agent", uvm_component parent);
                super.new(name, parent);
        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                // get the config object
                if(!uvm_config_db#(apb_agent_config)::get(this,"","apb_agent_config",m_cfg))
                        `uvm_fatal(get_type_name,"Cannot get the config object");

                // construct the component
                mon_h = apb_monitor::type_id::create("mon_h", this);

                if (m_cfg.is_active == UVM_ACTIVE) begin

                        drv_h = apb_driver::type_id::create("drv_h", this);
                        seqr_h = apb_seqr::type_id::create("seqr_h", this);
                end

        endfunction : build_phase

        // connect phase
        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);

                if (m_cfg.is_active == UVM_ACTIVE)
                        drv_h.seq_item_port.connect(seqr_h.seq_item_export);
        endfunction : connect_phase

endclass : apb_agent

// gpio agent class

class gpio_agent extends uvm_agent;

        // factory registraion
        `uvm_component_utils(gpio_agent)

        // config object handle
        gpio_agent_config m_cfg;

        // component handles
        gpio_driver drv_h;
        gpio_monitor mon_h;
        gpio_seqr seqr_h;

        // constructor
        function new(string name = "gpio_agent", uvm_component parent);
                super.new(name,parent);
        endfunction : new

        // build_phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                // get config object
                if(!uvm_config_db#(gpio_agent_config)::get(this,"","gpio_agent_config",m_cfg))
                        `uvm_fatal(get_type_name(),"Cannot get the gpio config object")

                // creating the components
                mon_h = gpio_monitor::type_id::create("mon_h",this);

                if(m_cfg.is_active == UVM_ACTIVE) begin
                        drv_h = gpio_driver::type_id::create("drv_h", this);
                        seqr_h = gpio_seqr::type_id::create("seqr_h", this);
                end

        endfunction : build_phase

        // connect phase
        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);

                if(m_cfg.is_active == UVM_ACTIVE)
                        drv_h.seq_item_port.connect(seqr_h.seq_item_export);

        endfunction : connect_phase

endclass : gpio_agent

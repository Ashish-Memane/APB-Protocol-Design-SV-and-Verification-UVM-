// spi agent class
class spi_agent extends uvm_agent;

        // factory registraion
        `uvm_component_utils(spi_agent)

        // component handles
        spi_driver drv_h;
        spi_monitor mon_h;
        spi_seqr seqr_h;

        // config object
        spi_agent_config m_cfg;

        // constructor
        function new(string name = "spi_agent", uvm_component parent);
                super.new(name, parent);
        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                // get the config object
                if(!uvm_config_db#(spi_agent_config)::get(this,"","spi_agent_config", m_cfg))
                        `uvm_fatal(get_type_name(),"Cannot get the spi config object")

                // creating the components
                mon_h = spi_monitor::type_id::create("mon_h", this);

                if(m_cfg.is_active == UVM_ACTIVE) begin

                        drv_h = spi_driver::type_id::create("drv_h",this);
                        seqr_h = spi_seqr::type_id::create("seqr_h",this);

                end

        endfunction : build_phase

        // connect phase
        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);

                if(m_cfg.is_active == UVM_ACTIVE)
                        drv_h.seq_item_port.connect(seqr_h.seq_item_export);

        endfunction : connect_phase

endclass : spi_agent

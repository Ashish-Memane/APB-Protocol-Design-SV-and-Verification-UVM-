// uart agent
class uart_agent extends uvm_agent;

        // factory registration
        `uvm_component_utils(uart_agent)

        // config object
        uart_agent_config m_cfg;

        // component handles
        uart_driver drv_h;
        uart_monitor mon_h;
        uart_seqr seqr_h;

        // constructor
        function new(string name = "uart_agent", uvm_component parent);
                super.new(name, parent);
        endfunction : new

        // build_phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                if(!uvm_config_db#(uart_agent_config)::get(this,"","uart_agent_config",m_cfg))
                        `uvm_fatal(get_type_name(),"Cannot get the uart config object")

                // monitor
                mon_h = uart_monitor::type_id::create("uart_monitor", this);

                // active agent
                if(m_cfg.is_active == UVM_ACTIVE) begin

                        drv_h = uart_driver::type_id::create("drv_h", this);
                        seqr_h = uart_seqr::type_id::create("seqr_h", this);
                end

        endfunction : build_phase

        // connect phase
        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);

                if(m_cfg.is_active == UVM_ACTIVE)
                        drv_h.seq_item_port.connect(seqr_h.seq_item_export);

        endfunction : connect_phase

endclass : uart_agent

// class env
class apb_env extends uvm_env;

        // factory registration
        `uvm_component_utils(apb_env)

        // env config
        apb_env_config m_tb_cfg;

        // component handles
        scoreboard sb_h;
        apb_agent_top apb_agt_top_h;
        slave_agent_top slave_agt_top_h;

        // virtual seqr
        apb_virtual_seqr v_seqr_h;

        // constructor
        function new(string name = "apb_env", uvm_component parent);
                super.new(name,parent);
        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                // getting the env object
                if(!uvm_config_db#(apb_env_config)::get(this,"","apb_env_config", m_tb_cfg))
                        `uvm_fatal(get_type_name(),"Cannot get the config object")

                // scoreboard
                if(m_tb_cfg.has_scoreboard == 1)
                        sb_h = scoreboard::type_id::create("sb_h", this);

                // virtual seqr
                if(m_tb_cfg.has_v_seqr == 1)
                        v_seqr_h = apb_virtual_seqr::type_id::create("v_seqr_h", this);

                // apb_agent top
                if(m_tb_cfg.has_master_agt_top == 1) begin
                        apb_agt_top_h = apb_agent_top::type_id::create("apb_agt_top_h", this);

                        // setting the apb agent top config object into the env config object
                        uvm_config_db#(apb_agent_config)::set(this,"*","apb_agent_config",m_tb_cfg.apb_m_cfg);
                end

                // slave agent top
                if(m_tb_cfg.has_slave_agt_top == 1) begin
                        slave_agt_top_h = slave_agent_top::type_id::create("slave_agt_top_h", this);

                        // setting the slave agent config objects into the env config object
                        uvm_config_db#(uart_agent_config)::set(this,"*","uart_agent_config", m_tb_cfg.uart_m_cfg);

                        uvm_config_db#(spi_agent_config)::set(this,"*","spi_agent_config", m_tb_cfg.spi_m_cfg);

                        uvm_config_db#(gpio_agent_config)::set(this,"*","gpio_agent_config", m_tb_cfg.gpio_m_cfg);

                end

        endfunction : build_phase

        // connect phase
        function void connect_phase(uvm_phase phase);
           super.connect_phase(phase);

        if(m_tb_cfg.has_v_seqr && v_seqr_h != null) begin

                 if(apb_agt_top_h != null && apb_agt_top_h.agt_h != null)
                         v_seqr_h.apb_seqr_h = apb_agt_top_h.agt_h.seqr_h;

        if(slave_agt_top_h != null) begin

                 if(slave_agt_top_h.uart_agt_h != null)
                    v_seqr_h.uart_seqr_h = slave_agt_top_h.uart_agt_h.seqr_h;

                 if(slave_agt_top_h.spi_agt_h != null)
                    v_seqr_h.spi_seqr_h = slave_agt_top_h.spi_agt_h.seqr_h;

                 if(slave_agt_top_h.gpio_agt_h != null)
                    v_seqr_h.gpio_seqr_h = slave_agt_top_h.gpio_agt_h.seqr_h;

         end

        end

        if(m_tb_cfg.has_scoreboard == 1) begin
           apb_agt_top_h.agt_h.mon_h.monitor_port.connect(sb_h.apb_fifo.analysis_export);
           slave_agt_top_h.uart_agt_h.mon_h.uart_ap.connect(sb_h.uart_fifo.analysis_export);
           slave_agt_top_h.spi_agt_h.mon_h.spi_ap.connect(sb_h.spi_fifo.analysis_export);
           slave_agt_top_h.gpio_agt_h.mon_h.gpio_ap.connect(sb_h.gpio_fifo.analysis_export);
        end

        endfunction

endclass : apb_env

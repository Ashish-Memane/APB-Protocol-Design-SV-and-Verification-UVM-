// apb agent top
class apb_agent_top extends uvm_env;

        // factory registraion
        `uvm_component_utils(apb_agent_top)

        // agent handle
        apb_agent agt_h;

        // apb  config
        apb_agent_config m_cfg;

        // constructor
        function new(string name = "apb_agent_top", uvm_component parent);
                super.new(name,parent);
        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                // get the config object
                if(!uvm_config_db#(apb_agent_config)::get(this,"","apb_agent_config",m_cfg))
                        `uvm_fatal(get_type_name(),"Cannot get the apb config object")

                // create the agent
                agt_h = apb_agent::type_id::create("agt_h",this);

        endfunction : build_phase

endclass : apb_agent_top

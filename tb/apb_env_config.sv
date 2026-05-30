// env config class
class apb_env_config extends uvm_object;

        // factory regisration
        `uvm_object_utils(apb_env_config)

        // declaring the properties
        int has_scoreboard = 1;
        int has_v_seqr = 1;
        int has_master_agt_top = 1;
        int has_slave_agt_top = 1;

        // the master and slave agent config object (setting in env config class from env)
        apb_agent_config apb_m_cfg;

        uart_agent_config uart_m_cfg;
        spi_agent_config spi_m_cfg;
        gpio_agent_config gpio_m_cfg;

        // constructor
        function new(string name = "apb_env_config");
                super.new(name);
        endfunction : new

endclass : apb_env_config

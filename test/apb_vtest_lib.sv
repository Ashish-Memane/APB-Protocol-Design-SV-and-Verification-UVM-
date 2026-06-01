// test class library
class apb_base_test extends uvm_test;

	// factory registration
	`uvm_component_utils(apb_base_test)

	// env handle 
	apb_env env_h;

	// config handle
	apb_env_config m_cfg;

	apb_agent_config apb_cfg;
	uart_agent_config uart_cfg;
	spi_agent_config spi_cfg;
	gpio_agent_config gpio_cfg;

	// constructor
	function new(string name = "apb_base_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

	// build phase
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		// env config object
		m_cfg = apb_env_config::type_id::create("m_cfg");

		// apb config object
		apb_cfg = apb_agent_config::type_id::create("apb_cfg");

		// uart config object
		uart_cfg = uart_agent_config::type_id::create("uart_cfg");

		// spi config object
		spi_cfg = spi_agent_config::type_id::create("spi_cfg");

		// gpio config object
		gpio_cfg = gpio_agent_config::type_id::create("gpio_cfg");

		// assigning the config object
		m_cfg.apb_m_cfg = apb_cfg;
		
		m_cfg.uart_m_cfg = uart_cfg;
	
		m_cfg.spi_m_cfg = spi_cfg;

		m_cfg.gpio_m_cfg = gpio_cfg;	


		// creating env
		env_h = apb_env::type_id::create("env_h", this);

		// agent configuration
		apb_cfg.is_active = UVM_ACTIVE;
		uart_cfg.is_active = UVM_ACTIVE;
		spi_cfg.is_active = UVM_ACTIVE;
		gpio_cfg.is_active = UVM_ACTIVE;

		m_cfg.has_scoreboard = 1;
		m_cfg.has_v_seqr = 1;
		m_cfg.has_master_agt_top = 1;
		m_cfg.has_slave_agt_top = 1;

		// assigning the virtual interfaces
		if(!uvm_config_db#(virtual apb_interface)::get(this,"","apb_interface",apb_cfg.apb_vif))
			`uvm_fatal(get_type_name(),"Cannot get the virtual interface")


		if(!uvm_config_db#(virtual uart_interface)::get(this,"","uart_interface",uart_cfg.uart_vif))	
			`uvm_fatal(get_type_name(),"Cannot get the virtual interface")
		
		if(!uvm_config_db#(virtual spi_interface)::get(this,"","spi_interface",spi_cfg.spi_vif))
			`uvm_fatal(get_type_name(),"Cannot get the virtual interface")
	
		if(!uvm_config_db#(virtual gpio_interface)::get(this,"","gpio_interface",gpio_cfg.gpio_vif))	
			`uvm_fatal(get_type_name(),"Cannot get the virtual interface")



		// setting the env config object
		uvm_config_db#(apb_env_config)::set(this,"*","apb_env_config",m_cfg);		

	endfunction : build_phase


	// end of elaboration phase
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
		
		// print topology
		uvm_top.print_topology();
	
	endfunction : end_of_elaboration_phase

	virtual task run_phase(uvm_phase phase);
        // 1. Raise objection at the test layer to hold the simulation canvas open
        phase.raise_objection(this, "Launching UART Read Test Track");
        
        // 2. Set your native UVM 1.1d drain cushion 
        // This gives the slow serial monitor plenty of time to finish shifting bit 10
        phase.phase_done.set_drain_time(this, 1500ns);

        // 3. Start your main virtual sequence or environment sequence
        // m_vseq.start(env_h.v_seqr_h);
        
        // 4. Drop the objection immediately after your sequences complete their execution
        phase.drop_objection(this, "UART Read Test Track Executions Complete");
	endtask : run_phase


	function void phase_ready_to_end(uvm_phase phase);
                super.phase_ready_to_end(phase);
                
                // We only apply this structural delay block to the active running path
                if (phase.get_name() == "run") begin
                        
			phase.phase_done.set_drain_time(this, 1000ns);
                        
                        `uvm_info("TEST_BASE", "Sequence loop items processed. Securing a 1000ns drain window.", UVM_LOW)
                end
        endfunction : phase_ready_to_end



endclass : apb_base_test

//===============================================================================================
// TC04
// uart write test

class apb_write_uart_test extends apb_base_test;

	// factory registration
	`uvm_component_utils(apb_write_uart_test)

	// virtual seq handle
	apb_write_uart_vseq v_seq_h;
	
	// constructor
	function new(string name = "apb_write_uart_test", uvm_component parent);
		super.new(name, parent);
	endfunction : new

	// run phase
	task run_phase(uvm_phase phase);
		
		// raise objection	
		phase.raise_objection(this);
		
		v_seq_h = apb_write_uart_vseq::type_id::create("v_seq_h");

		v_seq_h.start(env_h.v_seqr_h);

		#5000;

		// drop objecttion
		phase.drop_objection(this);
		
	endtask : run_phase

endclass : apb_write_uart_test

//==============================================================================================
// TC02
// gpio write test

class apb_write_gpio_test extends apb_base_test;

	// factory registration
	`uvm_component_utils(apb_write_gpio_test)

	// virtual seq handle
	apb_write_gpio_vseq v_seq_h;
	
	// constructor
	function new(string name = "apb_write_gpio_test", uvm_component parent);
		super.new(name, parent);
	endfunction : new

	// run phase
	task run_phase(uvm_phase phase);
		
		// raise objection	
		phase.raise_objection(this);
		
		v_seq_h = apb_write_gpio_vseq::type_id::create("v_seq_h");

		v_seq_h.start(env_h.v_seqr_h);

		// drop objecttion
		phase.drop_objection(this);
		
	endtask : run_phase

endclass : apb_write_gpio_test

//===============================================================================================
// TC06
// spi write test

class apb_write_spi_test extends apb_base_test;

	// factory registration
	`uvm_component_utils(apb_write_spi_test)

	// virtual seq handle
	apb_write_spi_vseq v_seq_h; 
	
	// constructor
	function new(string name = "apb_write_spi_test", uvm_component parent);
		super.new(name, parent);
	endfunction : new

	// run phase
	task run_phase(uvm_phase phase);
		
		// raise objection	
		phase.raise_objection(this);
		
		v_seq_h = apb_write_spi_vseq::type_id::create("v_seq_h");

		v_seq_h.start(env_h.v_seqr_h);

		// drop objecttion
		phase.drop_objection(this);
		
	endtask : run_phase

endclass : apb_write_spi_test


//===============================================================================================
// TC05
// uart read test

class apb_read_uart_test extends apb_base_test;

	// factory registration
	`uvm_component_utils(apb_read_uart_test)

	// virtual seq handle
	apb_read_uart_vseq v_seq_h;
	
	// constructor
	function new(string name = "apb_read_uart_test", uvm_component parent);
		super.new(name, parent);
	endfunction : new

	// run phase
	task run_phase(uvm_phase phase);
		
		// raise objection	
		phase.raise_objection(this);
		
		v_seq_h = apb_read_uart_vseq::type_id::create("v_seq_h");

		v_seq_h.start(env_h.v_seqr_h);

		#500;

		// drop objecttion
		phase.drop_objection(this);
		
	endtask : run_phase

endclass : apb_read_uart_test

//===================================================================================================
// TC07 apb spi read test
class apb_read_spi_test extends apb_base_test;

	// factory registraion
	`uvm_component_utils(apb_read_spi_test)

	// virtual seq handle
	apb_read_spi_vseq v_seq_h;

	// constructor
	function new(string name = "apb_read_spi_test", uvm_component parent);
		super.new(name, parent);
	endfunction : new

	// task run phase
	task run_phase(uvm_phase phase);
	
		// raise objection
		phase.raise_objection(this);

		v_seq_h = apb_read_spi_vseq::type_id::create("v_seq_h", this);

		v_seq_h.start(env_h.v_seqr_h);

		// drop objection
		phase.drop_objection(this);	

	endtask : run_phase
	

endclass : apb_read_spi_test

//===================================================================================================
//TC03 apb read gpio test
class apb_read_gpio_test extends apb_base_test;

	// factory registration
	`uvm_component_utils(apb_read_gpio_test)

	// virtual seq handle
	apb_read_gpio_vseq v_seq_h;
	
	// constructor
	function new(string name = "apb_read_gpio_test", uvm_component parent);
		super.new(name,parent);
	endfunction : new


	// task run phase
	task run_phase(uvm_phase phase);

		// raise objection
		phase.raise_objection(this);

		v_seq_h = apb_read_gpio_vseq::type_id::create("v_seq_h", this);

		v_seq_h.start(env_h.v_seqr_h);

		// drop objection
		phase.drop_objection(this);

	endtask 


endclass : apb_read_gpio_test




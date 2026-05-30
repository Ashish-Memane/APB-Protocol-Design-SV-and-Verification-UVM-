// gpio monitor class
class gpio_monitor extends uvm_monitor;

        // factory registration
        `uvm_component_utils(gpio_monitor)

        // virtual interface
        virtual gpio_interface vif;

        // analysis port to scoreboard
        uvm_analysis_port #(gpio_xtn) gpio_ap;

        // transaction handle
        gpio_xtn xtn_h;

        // constructor
        function new(string name = "gpio_monitor", uvm_component parent);
                super.new(name, parent);
                gpio_ap = new("gpio_ap", this);
        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);
                if(!uvm_config_db#(virtual gpio_interface)::get(this,"","gpio_interface",vif))
                        `uvm_fatal(get_type_name(),"Cannot get gpio interface")
        endfunction : build_phase

        // run phase
        task run_phase(uvm_phase phase);

                // Storage variables to keep track of the last seen stable values
                logic [31:0] prev_gpio_in;
                logic [31:0] prev_gpio_out;
                logic [31:0] prev_gpio_dir;

                // Wait for reset to clear safely
                wait(vif.PRESETn === 1'b1);
                @(vif.gpio_mon_cb);

                // Initialize tracking variables with default post-reset states
                prev_gpio_in  = vif.gpio_mon_cb.gpio_in;
                prev_gpio_out = vif.gpio_mon_cb.gpio_out;
                prev_gpio_dir = vif.gpio_mon_cb.gpio_dir;

                forever begin
                        // Step with the clocking block edge
                        @(vif.gpio_mon_cb);

                        // CHANGE-DETECTION CONDITION:
                        // Only trigger if a signal actually updates its value!
                        if ((vif.gpio_mon_cb.gpio_in  !== prev_gpio_in)  ||
                            (vif.gpio_mon_cb.gpio_out !== prev_gpio_out) ||
                            (vif.gpio_mon_cb.gpio_dir !== prev_gpio_dir))
                        begin

                                // Create a brand fresh transaction object
                                xtn_h = gpio_xtn::type_id::create("xtn_h");

                                // Capture the current states
                                xtn_h.gpio_in  = vif.gpio_mon_cb.gpio_in;
                                xtn_h.gpio_out = vif.gpio_mon_cb.gpio_out;
                                xtn_h.gpio_dir = vif.gpio_mon_cb.gpio_dir;

                                // Broadcast the transaction item to the scoreboard
                                gpio_ap.write(xtn_h);

                                `uvm_info("GPIO_MONITOR", $sformatf("GPIO Activity Detected! IN=%h OUT=%h DIR=%h",
                                          xtn_h.gpio_in, xtn_h.gpio_out, xtn_h.gpio_dir), UVM_LOW)

                                // Update the memory history registers to prevent re-triggering
                                prev_gpio_in  = vif.gpio_mon_cb.gpio_in;
                                prev_gpio_out = vif.gpio_mon_cb.gpio_out;
                                prev_gpio_dir = vif.gpio_mon_cb.gpio_dir;
                        end
                end
        endtask : run_phase

endclass : gpio_monitor

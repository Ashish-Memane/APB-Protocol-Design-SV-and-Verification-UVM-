// class gpio monitor
class gpio_monitor extends uvm_monitor;

        // factory registration
        `uvm_component_utils(gpio_monitor)

        // virtual interface
        virtual gpio_interface vif;

        // analysis port
        uvm_analysis_port #(gpio_xtn) gpio_ap;

        // transaction handle
        gpio_xtn xtn_h;

        // constructor
        function new(string name = "gpio_monitor", uvm_component parent);
                super.new(name,parent);

                gpio_ap = new("gpio_ap", this);

        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                if(!uvm_config_db#(virtual gpio_interface)::get(this,"","gpio_interface",vif))
                        `uvm_fatal(get_type_name(),"Cannot get the gpio interface")

        endfunction : build_phase

        // run phase
        task run_phase(uvm_phase phase);

                forever begin
                        collect_gpio();
                end

        endtask : run_phase

        // task collect gpio
        task collect_gpio();

                // create instance
                xtn_h = gpio_xtn::type_id::create("xtn_h");

                // sample signals
                @(vif.gpio_mon_cb);

                xtn_h.gpio_in = vif.gpio_mon_cb.gpio_in;

                xtn_h.gpio_out = vif.gpio_mon_cb.gpio_out;

                xtn_h.gpio_dir = vif.gpio_mon_cb.gpio_dir;

                // send to sb
                gpio_ap.write(xtn_h);

/*               `uvm_info("GPIO_MON",
                          $sformatf("GPIO_IN = %0h GPIO_OUT = %0h GPIO_DIR = %0h",
                                    xtn_h.gpio_in,
                                    xtn_h.gpio_out,
                                    xtn_h.gpio_dir),
                          UVM_LOW)
*/
        endtask : collect_gpio

endclass : gpio_monitor

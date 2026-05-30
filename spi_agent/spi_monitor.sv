// spi monitor class
class spi_monitor extends uvm_monitor;

        // factory registration
        `uvm_component_utils(spi_monitor)

        // virtual interface
        virtual spi_interface vif;

        // analysis port
        uvm_analysis_port #(spi_xtn) spi_ap;

        // transaction handle
        spi_xtn xtn_h;

        // constructor
        function new(string name = "spi_monitor", uvm_component parent);
                super.new(name, parent);
                spi_ap = new("spi_ap", this);
        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);
                if(!uvm_config_db#(virtual spi_interface)::get(this,"","spi_interface",vif))
                        `uvm_fatal(get_type_name(),"Cannot get spi interface")
        endfunction : build_phase

        // run phase
        task run_phase(uvm_phase phase);
                forever begin
                        collect_spi_data();
                end
        endtask : run_phase


        // task to collect spi data
        task collect_spi_data();
                int i;
                logic [31:0] mosi_data;
                logic [31:0] miso_data;

                // 1. Use the raw interface signal with the system clock (PCLK)
                // to accurately catch the CS falling edge before SCLK begins pulsing.
                while (vif.cs !== 1'b0) begin
                    @(posedge vif.PCLK);
                end

                `uvm_info("SPI_MON","CS LOW DETECTED",UVM_LOW)

                // create transaction
                xtn_h = spi_xtn::type_id::create("xtn_h");

                // 2. Sample all 32 bits precisely on the posedge sclk via your clocking block
                for(i=31; i>=0; i--)
                begin
                        @(vif.spi_mon_cb);
                        mosi_data[i] = vif.spi_mon_cb.mosi;
                        miso_data[i] = vif.spi_mon_cb.miso;
                end

                // Fill transaction
                xtn_h.tx_data = mosi_data;
                xtn_h.rx_data = miso_data;

                // send to scoreboard
                spi_ap.write(xtn_h);

                `uvm_info("SPI_MON", $sformatf("SPI PACKET COLLECTED: MOSI = %0h  MISO = %0h", mosi_data, miso_data), UVM_LOW)

                // 3. Cleanly wait for the transfer window to close using PCLK
                while (vif.cs === 1'b0) begin
                    @(posedge vif.PCLK);
                end
                `uvm_info("SPI_MON","CS HIGH DETECTED",UVM_LOW)

        endtask : collect_spi_data

endclass : spi_monitor

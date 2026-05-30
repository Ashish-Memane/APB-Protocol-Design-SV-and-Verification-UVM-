// spi monitor class
class spi_monitor extends uvm_monitor;

        // factory registraio
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

                // get virtual interface
                if(!uvm_config_db#(virtual spi_interface)::get(this,"","spi_interface",vif))
                        `uvm_fatal(get_type_name(),"Cannot get spi interface")

        endfunction : build_phase

        // run phase
        task run_phase(uvm_phase phase);

                forever begin
                        collect_spi_data();
                end

        endtask : run_phase


        task collect_spi_data();

    int i;

    logic [31:0] mosi_data;
    logic [31:0] miso_data;

    xtn_h = spi_xtn::type_id::create("xtn_h");

    //------------------------------------------
    // WAIT FOR CHIP SELECT
    //------------------------------------------

    wait(vif.spi_mon_cb.cs == 1'b0);

    //------------------------------------------
    // SAMPLE 32-BIT TRANSFER
    //------------------------------------------

    for(i = 31; i >= 0; i--)
    begin

        @(vif.spi_mon_cb);

        mosi_data[i] = vif.spi_mon_cb.mosi;
        miso_data[i] = vif.spi_mon_cb.miso;

    end

    //------------------------------------------
    // WAIT FOR TRANSFER END
    //------------------------------------------

    wait(vif.spi_mon_cb.cs == 1'b1);

    //------------------------------------------
    // STORE DATA
    //------------------------------------------

    xtn_h.tx_data = mosi_data;
    xtn_h.rx_data = miso_data;

    //------------------------------------------
    // SEND TO SCOREBOARD
    //------------------------------------------

    spi_ap.write(xtn_h);

    `uvm_info("SPI_MON",
              $sformatf("SPI MOSI = %0h MISO = %0h",
                        mosi_data,
                        miso_data),
              UVM_LOW)

endtask

endclass : spi_monitor

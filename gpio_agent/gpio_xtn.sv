// gpio xtn class
class gpio_xtn extends uvm_sequence_item;

        // factory registration
        `uvm_object_utils(gpio_xtn)

        // gpio inputs
        rand logic [31:0] gpio_in;

        // gpio outputs
        logic [31:0] gpio_out;
        logic [31:0] gpio_dir;

        // constructor
        function new(string name = "gpio_xtn");
                super.new(name);
        endfunction : new

         // print
        function void do_print(uvm_printer printer);

                super.do_print(printer);

                printer.print_field("gpio_in",
                                     gpio_in,
                                     32,
                                     UVM_HEX);

                printer.print_field("gpio_out",
                                     gpio_out,
                                     32,
                                     UVM_HEX);

                printer.print_field("gpio_dir",
                                     gpio_dir,
                                     32,
                                     UVM_HEX);

        endfunction : do_print

endclass : gpio_xtn

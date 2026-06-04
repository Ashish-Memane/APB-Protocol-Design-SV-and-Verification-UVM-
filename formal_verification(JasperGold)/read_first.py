# You have to modify the run_gpio.tcl with the appropriate module instantiation, and can run on the Linux terminal using jg --tcl_script_name--
# in the JasperGold tool, you can command the source --tcl_script_file_name-- 

# Swap these targets into your active run_gpio.tcl script execution block
analyze -sv12 apb_interconnect.sv apb_interconnect_fv.sv
elaborate -top apb_interconnect -create_related_covers {precondition witness}


# Swap these setup targets into your active run_gpio.tcl configuration
analyze -sv12 apb_master.sv apb_master_fv.sv
elaborate -top apb_master -create_related_covers {precondition witness}


# Modify these lines in your existing Tcl script execution path:
analyze -sv12 apb_uart.sv apb_uart_fv.sv
elaborate -top apb_uart -create_related_covers {precondition witness}


# Modify the compilation lines inside your script to check this module:
analyze -sv12 apb_spi.sv apb_spi_fv.sv
elaborate -top apb_spi -create_related_covers {precondition witness}

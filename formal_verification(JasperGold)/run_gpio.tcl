# To clear previous Settings
clear -all

# Initialize coverage collection through -init enables all the coverage categories through type all
check_cov -init -type all -model {statement branch expression toggle functional}

# Analyze RTL + Assertions (compilation) - Using your SystemVerilog files
analyze -sv12 apb_gpio.sv apb_gpio_fv.sv

# Elaborate DUT (synthesis and design hierarchy)
elaborate -top apb_gpio -create_related_covers {precondition witness}

# Define clock and reset - Setup CLOCK and RESET for your APB module
clock PCLK
reset !PRESETn

# Prove all properties
prove -all -with_ppd -save_ppd -orchestration on


# Measure coverage - displays the summary of the coverage
check_cov -measure

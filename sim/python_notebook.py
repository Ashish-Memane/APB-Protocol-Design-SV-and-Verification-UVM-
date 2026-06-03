# creating the excel file using python
# importing the workbook
from openpyxl import Workbook

# create workbook  * can create multiple sheets with one workbook like MS excel
wb = Workbook()

# select sheet
sheet = wb.active
sheet.title = "directory_info"

# Add data
# coloumn name key ---- value

sheet["A1"] = "key"
sheet["B1"] = "value"

# adding the data_paths of rtl and testbench
sheet["A2"] = "RTL"
sheet["A3"] = "work"
sheet["A4"] = "SVTB1"
sheet["A5"] = "INC"
sheet["A6"] = "SVTB2"
sheet["A7"] = "VSIMOPT"
sheet["A8"] = "VSIMCOV"
sheet["A9"] = "VSIMBATCH1"
sheet["A10"] = "VSIMBATCH2"
sheet["A11"] = "VSIMBATCH3"
sheet["A12"] = "VSIMBATCH4"


# adding the path for the directories
sheet["B2"] = "../rtl/* ../interface/*"
sheet["B3"] = "../work/*"
sheet["B4"] = "../tb/top.sv"
sheet["B5"] = "../+incdir+../tb +incdir+../test +incdir+../apb_agent_top +incdir+../slave_agent_top +incdir+../uart_agent +incdir+../spi_agent +incdir+../gpio_agent"
sheet["B6"] = "../test/apb_protocol_pkg.sv"
sheet["B7"] = "-vopt -voptargs=+acc"
sheet["B8"] = "-coverage -sva"
sheet["B9"] = '-c -do "log -r /* ;coverage save -onexit apb_cov1;run -all; exit"'
sheet["B10"] = '-c -do "log -r /* ;coverage save -onexit apb_cov2;run -all; exit"'
sheet["B11"] = '-c -do "log -r /* ;coverage save -onexit apb_cov3;run -all; exit"'
sheet["B12"] = '-c -do "log -r /* ;coverage save -onexit apb_cov4;run -all; exit"'



# add data

sheet["C1"] = "sr_no"
sheet["D1"] = "testcase_name"


sheet["C2"] = "1"
sheet["C3"] = "2"
sheet["C4"] = "3"
sheet["C5"] = "4"
sheet["C6"] = "5"


# adding the testcase names

sheet["D2"] = "apb_write_uart_test"
sheet["D3"] = "apb_write_spi_test"
sheet["D4"] = "apb_write_gpio_test"
sheet["D5"] = "apb_read_uart_test"
sheet["D6"] = "apb_read_gpio_test"



# save as a real excel file
wb.save("dir_info.xlsx")
print("Excel file created successfully!")

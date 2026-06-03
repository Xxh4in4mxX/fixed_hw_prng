## Xung nhịp hệ thống (Onboard Clock - 100 MHz)
set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
 
## Công tắc điều khiển (Switches)
set_property PACKAGE_PIN V17 [get_ports sw0]					
	set_property IOSTANDARD LVCMOS33 [get_ports sw0]

## Nút nhấn điều khiển (Buttons)
set_property PACKAGE_PIN U18 [get_ports btnC]						
	set_property IOSTANDARD LVCMOS33 [get_ports btnC]
 
## Mạch giao tiếp USB-RS232 Bridge (UART)
set_property PACKAGE_PIN A18 [get_ports RsTx]						
	set_property IOSTANDARD LVCMOS33 [get_ports RsTx]

## Thiết lập cấu hình Bitstream bổ trợ
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIX4 [current_design]

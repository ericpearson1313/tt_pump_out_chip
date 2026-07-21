// vim: ts=4:
// The LPC Core.
// Wrapped by chip specific warapepr (ie project.,v)
module lpc_core (
	// System
	input logic clk,
	input logic reset,
	// Digial Inputs
	input logic button,
	input logic period_sw,
	input logic timeout_sw,
	input logic setup_sw,
	// Digial outputs
	output logic time_led,
	output logic fault_led,
	output logic run_led,
	output logic pump_out,
	// ADC/SPI Interface
	output logic adc_ncs,	// /cs to adc
	output logic adc_clk,	// shift clk to adc
	output logic adc_mosi,  // shift data input to adc
	 input logic adc_miso 	// shift data output from adc
);

endmodule
	

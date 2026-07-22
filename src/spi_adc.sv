// vim: ts=4:

// Interface modules for MCP3202 12-bit spi adc.
// Master, Monitor, Simulator. With these 3 blocks all anchored on the 4 I/O pins (spi)
// They are targetted at the LPC chip. They will be used for:
// emulation, monitoring, simlation fpga accelleration, asic bist?, chip testers and verilator testbenches.

// This is the master interface on chip, intended to talk to I/O pads
// Talks to the SPI ADC and strobes the data onto the bus
// Runs continuous. Alternating reads of channel 0, then channel 1, and repeat
// Sample rate is 15K each (total 30K). The ad_clk runs at 600Khzi. 40 ad_clk cycles to sample 0 and 1.
// Area is to be minimized. A bit serial (MSB) output is used
module adc_spi_master
(
	// Input clock,
	input wire clk,
	input wire reset,
	
	// External A/D Converter 
	// Assumed 1 external I/O reg on each.
	output logic ad_ncs,
	output logic ad_clk,
	output logic ad_mosi,
	input  logic ad_miso,
	
	// ADC monitor outputs
	output logic dout, // serial output
	output logic chan, // Indicate chan 0 or 1
	output logic dval, // Indicates valid bit 
    output logic strb // indicates start next chan, chan valid, Coincident with dval tbd.
);

	// Tie off TT outs for now
	assign ad_ncs = 0;
	assign ad_clk = 0;
	assign ad_mosi = 0;


endmodule

// This the monitor interface. It can montitor internal or external interfaces
// The interface can be asychous. The interface is oversampled and decoded, with
// parallel 12 bit output. and valid strobe
// External registers for async crossing are assumed. Should use I/O regs for chip monitoring.
// Also use to monitor internal interfaced in the case of emulation or simulation.
module adc_spi_monitor
(
	// Input clock,
	input wire clk,
	input wire reset,
	
	// A/D Converter interface
	input  logic ad_ncs,
	input  logic ad_clk,
	input  logic ad_mosi,
	input  logic ad_miso,
	
	// ADC monitor outputs
	output logic [11:0] dout, // parallel output
	output logic chan, // Indicate chan 0 or 1
    output logic strb // indicates start next chan, chan valid, Coincident with dval tbd.
);
endmodule

// This is the simulated ADC (MCP3202), Not general purpose
// SImualted only enough to work for this applicaiton.
// It has input ports for the parallel 12 bit data ports (0, 1)
// The external interface may be asycnronous, however latency matters somewhat
// This interface assumes exactly 1 ff between the core and the chip pin (IO flop) for all 4 signals.
module adc_spi_simulate
(
	// Input clock,
	input wire clk,
	input wire reset,
	
	// A/D Converter spi interface
	// Assume 1 external I/O Flop per signal
	input  logic ad_ncs,
	input  logic ad_clk,
	input  logic ad_mosi,
	output logic ad_miso,
	
	// ADC simulation inteface
	input logic [11:0] din0,
	input logic [11:0] din1,
	output logic strb0, // din0 was sampled
	output logic strb1  // din1 was sampled
);
endmodule


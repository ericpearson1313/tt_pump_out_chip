// vim: ts=4:
/////////////////////////////////////////////////////////////
// Interface modules for MCP3202 12-bit spi adc.
/////////////////////////////////////////////////////////////
// 3 perspectives: Master, Monitor, Simulator. 
// With these 3 blocks all anchored on the 4 I/O pins (spi)
// They are targetted at the LPC chip. They will be used for:
// emulation, monitoring, simlation fpga accelleration, 
// asic bist?, chip testers and verilator testbenches.
/////////////////////////////////////////////////////////////

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
	// Parameters
	parameter CLK_FREQ_HZ 			= 48000000; // Our ref clk
	parameter SAMPLE_FREQ_HZ    	= 15000; // System selected
	parameter CYC_PER_SAMPLE 		= 3200; // CLK_FREQ_HZ / SAMPLE_FREQ_HZ;
	parameter ADC_CLK_HZ 			= 600000; // Device limited
	parameter ADC_CLK_PER_SAMPLE 	= 40; // ADC_CLK_HZ / SAMPLE_FREQ_HZ adc clk cycles to read inputs 0 and 1
	parameter CYC_PER_ADC_HALF_CYC 	= 40; // CLK_FREQ_HZ / ADC_CLK_HZ / 2
	parameter CYC_PER_ADC_CYC 		= 80; // CLK_FREQ_HZ / ADC_CLK_HZ 
	parameter HALF_ADC_CLK_PER_SAMPLE=80; // 2 * ADC_CLK_HZ / SAMPLE_FREQ_HZ adc clk cycles to read inputs 0 and 1

	// Half cycle Base rate (2x bitrate)
	logic half_cyc; // strobe
	logic [5:0] div_half;
	assign half_cyc = ( div_half == 39 ) ? 1'b1 : 1'b0;
	always_ff @(posedge clk) 
		div_half <= (reset)?0:(half_cyc == 39)?0:div_half+1;

	// Sample period counter
	logic [6:0] count2x;
	always_ff @(posedge clk)
		count2x <= (reset)?0:(count2x== 79)?0:(half_cyc)?count2x+1:count2x;

	// Waves for SPI samplign cycle
	logic [0:39] ncs_wave, clk_wave, mosi_wave; 
	logic [0:39] samp_wave, chan_wave, strb_wave; 
	initial begin
		ncs_wave = 40'b1_0000_0_000000000000_1_0000_0_000000000000_1111;
		clk_wave = 40'b0_1111_1_111111111111_0_1111_1_111111111111_0000;
	    mosi_wave= 40'b0_1101_0_000000000000_0_1111_0_000000000000_0000;
		samp_wave= 40'b0_0000_0_111111111111_0_0000_0_111111111111_0000;	
		chan_wave= 40'b1_0000_0_000000000000_0_1111_1_111111111111_1111;	
		strb_wave= 40'b0_0010_0_000000000000_0_0010_0_000000000000_0000;	
	end
	logic ncs_reg , clk_reg , mosi_reg ; 
	logic samp_reg , chan_reg , strb_reg ; 
	always_ff @(posedge clk)  ncs_reg <=  ncs_wave[count2x[6:1]];
	always_ff @(posedge clk)  clk_reg <=  clk_wave[count2x[6:1]] & count2x[0]; // gated clk
	always_ff @(posedge clk) mosi_reg <= mosi_wave[count2x[6:1]];
	always_ff @(posedge clk) samp_reg <= samp_wave[count2x[6:1]] & !count2x[0] & half_cyc; // sample pulse
	always_ff @(posedge clk) chan_reg <= chan_wave[count2x[6:1]];
	always_ff @(posedge clk) strb_reg <= strb_wave[count2x[6:1]] & !count2x[0] & half_cyc; // chan stobe

	// Connect up ADC outputs (should have ext regs)
	assign ad_ncs = ncs_reg;
	assign ad_clk = clk_reg;
	assign ad_mosi= mosi_reg;

	// Connect up ADC input (should have ext reg)
	logic data_reg;
	always_ff @(posedge clk) 
		data_reg <= (reset)?0:(samp_reg)?ad_miso:data_reg;

	// Connect up internal interface
	assign dout = data_reg;
	logic samp_del;
	always_ff @(posedge clk) 
		samp_del <= samp_reg;
	assign dval = samp_del;
	assign chan = chan_reg;
	assign strb = strb_reg;

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


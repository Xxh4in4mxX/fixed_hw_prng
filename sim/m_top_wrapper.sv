`timescale 1ns/100ps
`default_nettype none
module m_top_wrapper();
    reg r_clk = 0;
    initial #50 forever #50 r_clk = ~r_clk;
    reg [31:0] r_cc = 1; always @(posedge r_clk) r_cc = r_cc + 1;
    initial #100000000 begin $display("Time out"); $finish; end
    m_sim m(r_clk, r_cc);
    // initial $dumpvars(0, m);
endmodule

// top_wrapper is a wrapper of the testbench, it:
// - generate the clock signal
// - stop simulation in case inf loop
// - put in a counting signal
// - use $dumpvar(0, m) to generate a waveform of every signal inside testbench

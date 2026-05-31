`timescale 1ns/10ps
module m_sim(w_clk, w_cc);
    input wire w_clk;
    input wire [31:0] w_cc;
    m_top m(w_clk);
    initial #49 begin
        // data used for rule90's load and data
        // m.r_ca_load <= 1'b1;
        // m.r_ca_data <= {512{1'b1}};
        m.w_rst_n_RND = 
    end

    initial #99 forever #100 begin 
        $display("CC%1d %d",
    w_cc, m.r_pattern_sel);
    end
    initial #101 begin
        m.r_ca_load <= 1'b0;
        m.r_ca_data <= 512'h0;
    end
endmodule

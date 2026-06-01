`timescale 1ns/10ps
module m_sim(w_clk, w_cc);
    input wire w_clk;
    input wire [31:0] w_cc;
    m_top_parallel m(w_clk);
    initial begin
        m.w_rst_n <= 1'b0;
        m.w_en_RND   <= 1'b0;
    end

    initial #99 forever #100 begin 
        $display("CC%1d %b",
    w_cc, m.r_state);
    end
    
    initial #150 begin
        m.w_rst_n <= 1'b1;
        m.w_en_RND <= 1'b1;
    end
endmodule

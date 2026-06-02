`timescale 1ns/10ps
module m_sim(w_clk, w_cc);
    input wire w_clk;
    input wire [31:0] w_cc;
    reg [127:0] r_prev_state=128'h0;
    reg [20:0]  w_total_hamming_distance=21'b0;
    reg [$clog2(128):0] w_min_hamming_distance={$clog2(128){1'b1}};
    logic [$clog2(128):0] w_hamming_distance;
    m_top_parallel m(w_clk);

    assign w_hamming_distance = $countones(r_prev_state ^ m.r_state);

    initial begin
        m.w_rst_n <= 1'b0;
        m.w_en_RND   <= 1'b0;
    end

    initial #99 forever #100 begin 
        $display("CC%1d %d, %d, %d",
    w_cc, w_hamming_distance, w_min_hamming_distance, w_total_hamming_distance);
    end
    
    initial #150 begin
        m.w_rst_n <= 1'b1;
        m.w_en_RND <= 1'b1;
    end

    always @(posedge w_clk) begin
        r_prev_state <= m.r_state;
        w_total_hamming_distance <= w_total_hamming_distance + w_hamming_distance;
        if (w_hamming_distance < w_min_hamming_distance && w_hamming_distance != 0)
            w_min_hamming_distance <= w_hamming_distance;
    end
endmodule

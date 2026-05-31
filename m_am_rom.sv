module m_am_rom #(
    parameter   int NUM_SBOX   = 14833,
    localparam  int SBOX_SIZE  = 256
)(
    input   wire [13:0] w_sel_sbox,
    input   wire [7:0]  w_in_num,
    output  wire [7:0]  w_out_num
);
    logic [7:0] rom_array [0:NUM_SBOX-1][0:SBOX_SIZE-1];
    initial begin
        $readmemh("sbox_patterns.mem", rom_array);
    end
    assign w_out_num = rom_array[w_sel_sbox][w_in_num];
endmodule

module m_sel_sbox(
    input   logic w_clk,
    input   logic         w_rst_n,
    input   logic         w_en,
    output  logic [13:0]  r_out_rnd
);
    logic [511:0] q;
    logic [511:0] q_left;
    logic [511:0] q_right;

    assign q_left = {q[0], q[511:1]};
    assign q_right = {q[510:0], q[511]};

    always @(posedge w_clk) begin
        if (!w_rst_n) begin
            q <= 512'ha5a5_5a5a_1234_5678_9abc_def0_ffff_0000_eeee_1111_bbbb_2222_7777_8888_9999_aaaa;
        end else if (w_en) begin
            q <= q_left ^ (q | q_right);
        end
    end
    assign r_out_rnd = q[13:0];
endmodule

// module m_sliding_window_ctrl(
// )

module m_top(
    input wire w_clk
);
    // Sbox selector signals
    wire    [13:0]  w_raw_bits;
    wire    [13:0]  w_pattern_sel;
    // Internal register
    reg     [127:0] r_state;
    reg     [6:0]   r_window_pointer;
    // Next_state_register
    reg     [7:0]   r_window_out;
    // Control signal: reset and enable
    reg     w_rst_n;
    reg     w_en_RND;

    m_sel_sbox mX (
        .w_clk(w_clk),
        .w_rst_n(w_rst_n),
        .w_en(w_en_RND),
        .r_out_rnd(w_raw_bits)
    );

    m_am_rom mY (
        .w_sel_sbox(w_pattern_sel),
        .w_in_num(r_state[r_window_pointer +: 8]),
        .w_out_num(r_window_out)
    );

    // always @(*) begin
    //     if (w_raw_bits >= 14'd14833)
    //         w_pattern_sel = w_raw_bits - 14'd14833;
    //     else
    //         w_pattern_sel = w_raw_bits;
    // end
    assign w_pattern_sel = (w_raw_bits >= 14'd14833) ? w_raw_bits - 14'd14833 : w_raw_bits;

    always @(posedge w_clk) begin
        if (!w_rst_n) begin
            r_state <= 128'h8080_8080_8080_8080_8080_8080_8080_8080;
            r_window_pointer <= 7'h0;
        end else if (w_en_RND) begin
            r_state[r_window_pointer +: 8] <= r_window_out;
            if (r_window_pointer >= 7'd120) begin
                r_window_pointer <= 7'd0;
            end else begin
                r_window_pointer <= r_window_pointer + 7'd1;
            end
        end
    end
endmodule

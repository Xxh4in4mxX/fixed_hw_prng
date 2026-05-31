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

// testing sequence
    // initial begin
        // displaying a sample only
        // for (int i = 0; i < 10; i ++) begin
            // $display("%h", rom_array[i][10]);
        // end
    // end

module m_sel_sbox(
    input   logic w_clk,
    // input   logic w_load,
    // input   logic [511:0] w_data,
    input   logic         w_rst_n,
    input   logic         w_en,
    // output  logic [511:0] r_out_rnd
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
    assign r_out_rnd = q[269:256];
endmodule

    // PRNG using rule90's cellular automaton
    // always @(posedge w_clk) begin
        // if (w_load)
            // r_out_rnd <= w_data;
        // else
            // r_out_rnd <= {1'b0, r_out_rnd[511:1]} ^ {r_out_rnd[510:0], 1'b0};
    // end

module m_top(
    input wire w_clk
    // input wire w_rst_n
);
    // signals used for rule90, load and load_data
    // reg   [511:0]   r_ca_data=512'b0;
    // reg             r_ca_load=1'b0;
    // wire  [511:0]   w_ca_state;
    // wire  [13:0]    w_raw_bits;
    // reg   [13:0]    r_pattern_sel;
    wire    w_rst_n_RND;
    wire    w_en_RND;
    wire    [13:0]  w_raw_bits;
    reg     [13:0]  r_pattern_sel;

    m_sel_sbox mX (
        .w_clk(w_clk),
        .w_rst_n(w_rst_n_RND),
        .w_en(w_en_RND),
        .r_out_rnd(w_raw_bits);
    );

    always @(*) begin
        if (w_raw_bits >= 14'd14833)
            r_pattern_sel = w_raw_bits - 14'd14833;
        else
            r_pattern_sel = w_raw_bits;
    end
endmodule

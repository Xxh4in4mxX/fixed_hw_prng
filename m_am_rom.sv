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

//  ADD MODULE: perm_rule_rom
module perm_rule_rom #(
    parameter int NUM_PATTERNS = 14833
)(
    input  wire [13:0]  pattern_sel, // rand_number in range 0~14833
    output reg  [23:0]  perm_rule    // flattened 24_bit bus (8ports * 3bits)
    // output reg  [2:0]   dest_pointers [0:7] // 8(0-7) nhóm 3-bits(0_2) indice
);
    logic [23:0] rom_array [0:NUM_PATTERNS-1]; // table of 14833 data lines, sized 24 bits

    // wire  [23:0] packed_rule = rom_array[pattern_sel]; // chọn một dòng 24 bits từ ROM, gán vào
    assign perm_rule = rom_array[pattern_sel];

    initial begin
        $readmemh("raw_perm_rules.mem", rom_array);
    end
endmodule
// ADDED perm_rule_rom

// ADD m_top_parallel
module m_top_parallel (
    input logic w_clk
);
    logic [127:0] r_state;
    wire  [127:0] w_parallel_out;

    wire  [13:0]  w_raw_bits;
    wire  [13:0]  w_pattern_sel;
    wire  [23:0]  w_perm_rule; 

    logic w_rst_n=1'b0;
    logic w_en_RND=1'b0;

    // 1. Khởi tạo selector core
    m_sel_sbox mX (
        .w_clk     (w_clk),
        .w_rst_n   (w_rst_n),
        .w_en      (w_en_RND),
        .r_out_rnd (w_raw_bits)
    );

    assign w_pattern_sel = (w_raw_bits >= 14'd14833) ? (w_raw_bits - 14'd14833) : w_raw_bits;

    // 2. Khởi tạo ROM cấu trúc phẳng
    perm_rule_rom m_rom (
        .pattern_sel (w_pattern_sel),
        .perm_rule   (w_perm_rule)
    );

    // 3. Tách luật cấu trúc phẳng 24-bit thành 8 đường dây con trỏ tĩnh bằng genvar
    wire [23:0] w_d_ptr_flat;
    genvar p;
    generate
        for (p = 0; p < 8; p = p + 1) begin : UNPACK_ROUTING
            assign w_d_ptr_flat[p*3 +: 3] = w_perm_rule[p*3 +: 3]; // w_d_ptr_flat[0:2] is a number from 0 to 7, indicating which bit of the block goes to output bit 0, w_d_ptr_flat[3:5] for output bit 1, etc.
        end
    endgenerate

    // 4. Mạch hoán vị bit song song (16 Blocks) dùng hoàn toàn assign
    genvar b, o;
    generate
        for (b = 0; b < 16; b = b + 1) begin : BMAPPED_BLOCKS
            wire [7:0] block_in = r_state[b*8 +: 8]; // block_in = 8-bit trong r_state
            wire [7:0] block_out;
            // Unroll mạch tổ hợp bằng các cổng logic chọn (MUX) thay vì luôn luôn_comb
            // variable o chạy từ 0 đến 7 đại diện cho mỗi bit output, chúng ta sẽ chọn bit nào từ block_in để đưa vào block_out[o] dựa trên w_d_ptr_flat
            for (o = 0; o < 8; o = o + 1) begin : BIT_MAPPING
                localparam int offset = (b*3) % 24;
                assign block_out[o] = (w_d_ptr_flat[(0*3+offset)%24 +: 3] == o[2:0]) ? block_in[0] :
                                      (w_d_ptr_flat[(1*3+offset)%24 +: 3] == o[2:0]) ? block_in[1] :
                                      (w_d_ptr_flat[(2*3+offset)%24 +: 3] == o[2:0]) ? block_in[2] :
                                      (w_d_ptr_flat[(3*3+offset)%24 +: 3] == o[2:0]) ? block_in[3] :
                                      (w_d_ptr_flat[(4*3+offset)%24 +: 3] == o[2:0]) ? block_in[4] :
                                      (w_d_ptr_flat[(5*3+offset)%24 +: 3] == o[2:0]) ? block_in[5] :
                                      (w_d_ptr_flat[(6*3+offset)%24 +: 3] == o[2:0]) ? block_in[6] :
                                      (w_d_ptr_flat[(7*3+offset)%24 +: 3] == o[2:0]) ? block_in[7] : 1'b0;
            end

            assign w_parallel_out[b*8 +: 8] = block_out;
        end
    endgenerate

    // 5. Cập nhật thanh ghi trạng thái đồng bộ
    always_ff @(posedge w_clk) begin
        if (!w_rst_n) begin
            // r_state <= 128'h0480_8080_0480_8080_4080_8080_4080_8080;
            r_state <= 128'hf000_f000_0000_0000_f000_0000_f000_0000;
        end else if (w_en_RND) begin
            r_state <= {w_parallel_out[6:0], w_parallel_out[127:7]};
        end
    end
endmodule
// ADDED m_top_parallel

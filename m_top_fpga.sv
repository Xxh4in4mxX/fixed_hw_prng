module m_top_fpga (
    input  logic clk,           // Chân thạch anh 100MHz (W5)
    input  logic btnC,          // Nút nhấn giữa làm chân Reset cứng
    input  logic sw0,           // Công tắc bật/tắt chế độ sinh số và truyền phát
    output logic RsTx           // Chân truyền phát dữ liệu UART (A18)
);
    // Đồng bộ hóa chân Reset mức thấp cho lõi hệ thống
    wire w_rst_n = ~btnC;

    // Các đường dây liên kết trung gian
    wire [127:0] w_rnd_state;
    logic        w_en_RND;
    
    logic        tx_start;
    logic [7:0]  tx_data;
    wire         tx_done;

    // 1. Khởi tạo lõi sinh số ngẫu nhiên song song 128-bit đã tối ưu
    m_top_parallel prng_core (
        .w_clk        (clk),
        .w_rst_n      (w_rst_n),
        .w_en_RND     (w_en_RND),
        .w_rnd_state  (w_rnd_state)
    );

    // 2. Khởi tạo module truyền UART
    uart_tx serial_transmitter (
        .clk      (clk),
        .rst_n    (w_rst_n),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .tx_line  (RsTx),
        .tx_done  (tx_done),
        .tx_busy  ()
    );

    // 3. Khối FSM điều khiển tuần tự hóa luồng dữ liệu 128-bit
    enum logic [1:0] {S_IDLE, S_GEN_PULSE, S_SEND_BYTE, S_WAIT_BYTE} fsm_state;
    logic [3:0]   byte_cnt;
    logic [127:0] r_tx_buffer;

    always_ff @(posedge clk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            fsm_state   <= S_IDLE;
            w_en_RND    <= 1'b0;
            tx_start    <= 1'b0;
            tx_data     <= 8'b0;
            byte_cnt    <= 0;
            r_tx_buffer <= 128'b0;
        end else begin
            case (fsm_state)
                S_IDLE: begin
                    tx_start <= 1'b0;
                    // Nếu sw0 bật, kích hoạt chu trình sinh và phát chuỗi dữ liệu
                    if (sw0) begin
                        w_en_RND  <= 1'b1; // Phát xung kích hoạt lõi PRNG
                        fsm_state <= S_GEN_PULSE;
                    end
                end

                S_GEN_PULSE: begin
                    w_en_RND    <= 1'b0;         // Ngắt xung kích hoạt ngay chu kỳ sau
                    r_tx_buffer <= w_rnd_state;  // Chốt giá trị 128-bit vừa tạo vào đệm
                    byte_cnt    <= 0;
                    fsm_state   <= S_SEND_BYTE;
                end

                S_SEND_BYTE: begin
                    // Tách và lấy 8 bit cao nhất (MSB) của bộ đệm để phát đi trước
                    tx_data   <= r_tx_buffer[127:120];
                    tx_start  <= 1'b1;
                    fsm_state <= S_WAIT_BYTE;
                end

                S_WAIT_BYTE: begin
                    tx_start <= 1'b0;
                    if (tx_done) begin
                        // Dịch trái bộ đệm dữ liệu 8-bit để đưa byte tiếp theo lên đầu
                        r_tx_buffer <= {r_tx_buffer[119:0], 8'b0};
                        
                        if (byte_cnt == 4'd15) begin
                            // Đã truyền phát đủ 16 bytes (16 * 8 = 128 bits)
                            fsm_state <= S_IDLE; 
                        end else begin
                            byte_cnt  <= byte_cnt + 1;
                            fsm_state <= S_SEND_BYTE;
                        end
                    end
                end
                default: fsm_state <= S_IDLE;
            endcase
        end
    end
endmodule

module uart_tx (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic       tx_line,
    output logic       tx_done,
    output logic       tx_busy
);
    localparam int CLKS_PER_BIT = 868;

    enum logic [1:0] {IDLE, START_BIT, DATA_BITS, STOP_BIT} state;

    logic [9:0] clk_cnt;
    logic [2:0] bit_idx;
    logic [7:0] data_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;
            tx_line  <= 1'b1;
            tx_done  <= 1'b0;
            tx_busy  <= 1'b0;
            clk_cnt  <= 0;
            bit_idx  <= 0;
            data_reg <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    tx_line <= 1'b1;
                    tx_done <= 1'b0;
                    if (tx_start) begin
                        data_reg <= tx_data;
                        tx_busy  <= 1'b1;
                        state    <= START_BIT;
                        clk_cnt  <= 0;
                    end else begin
                        tx_busy  <= 1'b0;
                    end
                end

                START_BIT: begin
                    tx_line <= 1'b0; // Chân UART kéo xuống 0 báo Start bit
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        state   <= DATA_BITS;
                        bit_idx <= 0;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                DATA_BITS: begin
                    tx_line <= data_reg[bit_idx]; // Phát lần lượt từ LSB đến MSB
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        if (bit_idx == 7) begin
                            state <= STOP_BIT;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                STOP_BIT: begin
                    tx_line <= 1'b1; // Chân UART kéo lên 1 báo Stop bit
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        tx_done <= 1'b1;
                        state   <= IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule

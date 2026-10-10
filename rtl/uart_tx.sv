module uart_tx #(
    parameter BAUD_RATE = 10_000_000,
    parameter CLK_RATE = 100_000_000,
    localparam BIT_TIME = CLK_RATE/BAUD_RATE,
    localparam HALF_BIT = BIT_TIME/2
) (
    input logic clk,
    input logic rst,
    input logic [7:0] p_in,
    input logic data_valid,
    output logic s_out,
    output logic tx_busy,
    output logic tx_done
);
    typedef enum  {IDLE, START, DATA, STOP} t_state;
    t_state state;
    logic [7:0] tx_data;
    logic [2:0] bit_idx;
    logic [3:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            s_out <= 1;
            tx_done <= 0;
            counter <= 0;
            bit_idx <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                  tx_busy <= 0;
                    if(data_valid) begin
                        tx_busy <= 1;
                        state <= START;
                        tx_data <= p_in;
                    end
                end
                START: begin
                  s_out <= 0;
                  if (counter < BIT_TIME - 1) begin
                    counter <= counter + 1;
                  end
                  else begin
                    state <= DATA;
                    counter <= 0;
                  end
                end
                DATA: begin
                  s_out <= tx_data[bit_idx];
                  if (counter < BIT_TIME - 1) begin
                    counter <= counter + 1;
                  end
                  else begin
                    counter <= 0;
                    if (bit_idx < 7) begin
                      bit_idx <= bit_idx + 1;
                    end
                    else begin
                      bit_idx <= 0;
                      state <= STOP;
                    end
                  end
                end
                STOP: begin
                  s_out <= 1;
                  if (counter <= BIT_TIME - 1) begin
                    counter <= counter + 1;
                  end
                  else begin
                    tx_done <= 1;
                    tx_busy <= 0;
                    counter <= 0;
                    state <= IDLE;
                  end
                end
            endcase
        end
    end
endmodule


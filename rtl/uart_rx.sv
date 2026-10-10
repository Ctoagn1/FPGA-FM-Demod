module uart_rx #(
    parameter BAUD_RATE = 10_000_000,
    parameter CLK_RATE = 100_000_000,
    localparam BIT_TIME = CLK_RATE/BAUD_RATE,
    localparam HALF_BIT = BIT_TIME/2

) (
    input logic clk,
    input logic rst,
    input logic rx_in,
    output logic [7:0] data,
    output logic data_valid
);
    typedef enum {IDLE, START, DATA, STOP, CLEANUP} rstate;
    rstate state;
    logic [3:0] counter;
    logic [2:0] bit_idx;

    logic rx_data_r;
    logic rx_data;


    always_ff @(posedge clk) begin
        rx_data_r <= rx_in;
        rx_data <= rx_data_r;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            counter <= 0;
            data_valid <= 0;
            bit_idx <= 0;
        end
        else begin
            case (state)
            IDLE: begin
                if (!rx_in) begin
                    state <= START;
                    counter <= 0;
                end
            end
            START: begin
                if (counter == HALF_BIT-1) begin
                    if(rx_data == 0) begin
                        counter <= 0;
                        state <= DATA;
                    end
                    else state <= IDLE;
                end
                else begin
                    counter <= counter + 1;
                end
            end
            DATA: begin
                if (counter < BIT_TIME - 1) begin
                    counter <= counter + 1;
                end
                else begin
                    counter <= 0;
                    bit_idx <= bit_idx + 1;
                    data[bit_idx] <= rx_data;
                

                  if (bit_idx < 7) begin
                      bit_idx <= bit_idx + 1;
                  end
                  else begin
                      state <= STOP;
                      bit_idx <= 0;
                  end
              end
            end
            STOP: begin
                if (counter < BIT_TIME - 1) begin
                    counter <= counter + 1;
                end
                else begin
                    data_valid <= 1;
                    counter <= 0;
                    state <= CLEANUP;
                end
            end
            CLEANUP: begin
                data_valid <= 0;
                state <= IDLE;
            end
            endcase
        end
    end


endmodule

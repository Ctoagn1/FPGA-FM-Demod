module uart_demo(
  input logic clk,
  input logic rst,
  input logic uart_rx_data,
  output logic uart_tx_data
  );

  logic [7:0] data_a, data_b;
  logic data_valid, tx_busy, tx_done;
  logic empty, full, start;
  assign start = !empty && !tx_busy;
  uart_rx rx_mod(
    .clk(clk), .rst(rst), .rx_in(uart_rx_data), .data(data_a), .data_valid(data_valid)
    );
  
  uart_tx tx_mod(
    .clk(clk), .rst(rst), .p_in(data_b), .data_valid(start), .s_out(uart_tx_data), .tx_busy(tx_busy), .tx_done(tx_done)
    );

    uart_fifo fifo(
      .clk(clk), .rst(rst), .push(data_valid), .pop(start), .din(data_a), .dout(data_b), .empty, .full
      );

endmodule

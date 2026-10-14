`timescale 1ns/1ps

module phase_demod(
  input logic clk,
  input logic rst,
  input logic uart_rx_data,
  output logic uart_tx_data
  ); 

  logic data_valid, cordic_output_valid, sub_output_valid, d_output_ready, e_output_ready, tx_busy, tx_done;
  logic [7:0] data_rx, data_re, data_im, data_split, data_tx;
  logic [15:0] phase, sub_phase, d_phase;
  logic input_ready, dempty, dfull, empty, full;

    uart_rx rx_mod(
    .clk(clk), .rst(rst), .rx_in(uart_rx_data), .data(data_rx), .data_valid(data_valid)
    );
    double_fifo iq(
      .clk(clk), .rst(rst), .push(data_valid), .pop(input_ready), .din(data_rx), .dout_re(data_re), .dout_im(data_im), .empty(dempty), .full(dfull)
    );
    cordic c(
      .clk(clk), .rst(rst), .input_valid(~dempty), .in_x({~data_re[7], data_re[6:0]}), .in_y({~data_im[7], data_im[6:0]}), .input_ready(input_ready), .output_valid(cordic_output_valid), .phase(phase)
    );
    subtractor s(
      .clk(clk), .rst(rst), .input_valid(cordic_output_valid), .data(phase), .output_valid(sub_output_valid), .sub_data(sub_phase)
    );
    fir fi(
      .clk(clk), .rst(rst), .input_valid(sub_output_valid), .in_data(sub_phase), .out_ready(d_output_ready), .out_data(d_phase)
    );

    sixteen_to_eight e(
      .clk(clk), .rst(rst), .input_valid(d_output_ready), .in(d_phase), .out(data_split), .output_valid(e_output_ready)
    );
    uart_fifo f(
      .clk(clk), .rst(rst), .push(e_output_ready), .pop(~tx_busy || tx_done), .din(data_split), .dout(data_tx), .empty(empty), .full(full)
    );
    uart_tx tx_mod(
      .clk(clk), .rst(rst), .p_in(data_tx), .data_valid(~empty), .s_out(uart_tx_data), .tx_busy(tx_busy), .tx_done(tx_done)
    );




endmodule

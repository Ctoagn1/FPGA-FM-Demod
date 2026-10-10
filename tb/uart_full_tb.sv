`timescale 1ns/1ps

module uart_full_tb;
  localparam CLK_PERIOD = 10;
  localparam CLKS_PER_BIT = 10;
  localparam NUM_BYTES = 5000;

  logic clk = 0, rst = 1, rx = 1;
  logic [7:0] data;
  logic valid;
  logic out;
  logic [7:0] recovered;

  uart_rx rx_mod(
    .clk(clk), .rst(rst), .rx_in(rx), .data(data), .data_valid(valid)
    );

  uart_tx tx_mod(
    .clk(clk), .rst(rst), .p_in(data), .data_valid(valid), .s_out(out), .tx_busy(), .tx_done()
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    int checked = 0, errors = 0;

    task automatic send_byte(input logic [7:0] b);
     rx <= 0;
      repeat (CLKS_PER_BIT) @(posedge clk);
      for (int i=0; i<8; i++) begin
        rx <= b[i];
        repeat(CLKS_PER_BIT) @(posedge clk);
      end
      rx <= 1;
      repeat (CLKS_PER_BIT) @(posedge clk);
    endtask

    task automatic recv_byte;
      @(negedge out);
      repeat (CLKS_PER_BIT/2) @(posedge clk);
      for (int i=0; i<8; i++) begin 
        repeat (CLKS_PER_BIT) @(posedge clk);
        recovered[i] <= out;
      end
      repeat (CLKS_PER_BIT) @(posedge clk);
    endtask

    initial begin 
      logic [7:0] b;
      repeat (5) @(posedge clk);
      rst <= 0;
      repeat (5) @(posedge clk);

      for (int n = 0; n < NUM_BYTES; n++) begin 
        b = $urandom_range(255, 0);
        fork
          send_byte(b);
          recv_byte();
        join
        if(b !== recovered) begin 
          $error("Expected 0x%02h, got 0x%02h", b, recovered);
          errors++;
        end
        checked++;
      end

      if (errors == 0 && checked == NUM_BYTES)
        $display("PASS: %0d bytes", checked);
      else 
        $fatal(1, "FAIL: checked=%0d errors=%0d", checked, errors);
      $finish;
    end

  initial begin
    #(CLK_PERIOD * CLKS_PER_BIT * 12 * NUM_BYTES * 2);
    $fatal(1, "TIMEOUT");
  end
endmodule

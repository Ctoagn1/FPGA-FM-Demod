`timescale 1ns/1ps

module uart_rx_tb;
  localparam CLK_PERIOD = 10;
  localparam CLKS_PER_BIT = 10;
  localparam NUM_BYTES = 5000;

  logic clk = 0, rst = 1, rx = 1;
  logic [7:0] data;
  logic valid;

  logic [7:0] input_data;

  uart_rx rx_mod(
    .clk(clk), .rst(rst), .rx_in(rx), .data(data), .data_valid(valid)
  );

    always #(CLK_PERIOD/2) clk = ~clk;

    logic [7:0] expected_q[$];
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

    always @(posedge clk) begin 
      logic [7:0] exp;
      if(!rst && valid) begin 
        if (expected_q.size() == 0) begin 
          $error("DUT produced unexpected byte 0x%02h", data);
          errors++;
        end else begin 
          exp = expected_q.pop_front();
          if (data !== exp) begin 
            $error("Mismatch: got 0x%02h, expected 0x%02h", data, exp);
            errors++;
          end 
          checked++;
        end
      end
    end

    initial begin 
      logic [7:0] b;
      repeat (5) @(posedge clk);
      rst <= 0;
      repeat (5) @(posedge clk);

      for (int n = 0; n < NUM_BYTES; n++) begin 
        b = $urandom_range(255, 0);
        expected_q.push_back(b);
        send_byte(b);
        repeat ($urandom_range(3, 0)) @(posedge clk);
      end

      repeat (5 * CLKS_PER_BIT) @(posedge clk);
      if (errors == 0 && checked == NUM_BYTES && expected_q.size() == 0)
        $display("PASS: %0d bytes", checked);
      else 
        $fatal(1, "FAIL: checked=%0d errors=%0d leftover=%0d", checked, errors, expected_q.size());
      $finish;
    end


endmodule

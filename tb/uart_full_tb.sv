`timescale 1ns/1ps

module uart_full_tb;
  localparam CLK_PERIOD = 10;
  localparam CLKS_PER_BIT = 100_000_000/115200;
  localparam NUM_BYTES = 5000;
  localparam MAX_GAP_BITS = 0;

  logic clk = 0, rst = 1, rx = 1;
  logic [7:0] data;
  logic valid;
  logic out;
  uart_rx rx_mod(
    .clk(clk), .rst(rst), .rx_in(rx), .data(data), .data_valid(valid)
    );

  uart_tx tx_mod(
    .clk(clk), .rst(rst), .p_in(data), .data_valid(valid), .s_out(out), .tx_busy(), .tx_done()
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    logic [7:0] expected [$];
    int received = 0, errors = 0, sent = 0;

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

  initial begin
    logic [7:0] b;
    repeat (5) @(posedge clk);
    rst <= 0;
    repeat (5) @(posedge clk);

    for (int n = 0; n < NUM_BYTES; n++) begin
      b = $urandom_range(255, 0);
      expected.push_back(b);                   // push BEFORE sending
      send_byte(b);
      sent++;
      if (MAX_GAP_BITS > 0)
        repeat ($urandom_range(MAX_GAP_BITS) * CLKS_PER_BIT) @(posedge clk);
    end
  end

  initial begin
    logic [7:0] got, exp;
    forever begin
      @(negedge out);                          // start bit edge
      repeat (CLKS_PER_BIT/2) @(posedge clk);  // middle of start bit
      if (out !== 1'b0) begin
        $error("Glitch on start bit"); errors++;
      end
      for (int i = 0; i < 8; i++) begin        // middle of each data bit
        repeat (CLKS_PER_BIT) @(posedge clk);
        got[i] = out;
      end
      repeat (CLKS_PER_BIT) @(posedge clk);    // middle of stop bit
      if (out !== 1'b1) begin
        $error("Framing error: stop bit low"); errors++;
      end

      if (expected.size() == 0) begin
        $error("Unexpected extra byte 0x%02h", got); errors++;
      end else begin
        exp = expected.pop_front();
        if (got !== exp) begin
          $error("Byte %0d: expected 0x%02h, got 0x%02h", received, exp, got);
          errors++;
        end
      end
      received++;
    end
  end

  // 3. Finisher: wait for the driver, let the pipeline drain, then judge
  initial begin
    wait (sent == NUM_BYTES);
    repeat (CLKS_PER_BIT * 20) @(posedge clk);
    if (errors == 0 && received == NUM_BYTES && expected.size() == 0)
      $display("PASS: %0d bytes.", received);
    else
      $fatal(1, "FAIL: sent=%0d received=%0d errors=%0d leftover=%0d",
             sent, received, errors, expected.size());
    $finish;
  end

  // Watchdog
  initial begin
    #(CLK_PERIOD * CLKS_PER_BIT * 12 * NUM_BYTES * 2);
    $fatal(1, "TIMEOUT");
  end
endmodule

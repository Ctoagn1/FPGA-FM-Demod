module uart_fifo #(parameter W = 8, DEPTH = 16) (
  input  logic clk, rst,
  input  logic push, pop,
  input  logic [W-1:0] din,
  output logic [W-1:0] dout,
  output logic empty, full
);
  logic [W-1:0] mem [DEPTH];
  logic [$clog2(DEPTH):0] wr, rd;
  assign empty = (wr == rd);
  assign full  = (wr - rd) == DEPTH;
  assign dout  = mem[rd[$clog2(DEPTH)-1:0]];

  always_ff @(posedge clk) begin
    if (rst) begin wr <= 0; rd <= 0; end
    else begin
      if (push && !full)  begin mem[wr[$clog2(DEPTH)-1:0]] <= din; wr <= wr + 1; end
      if (pop  && !empty) rd <= rd + 1;
    end
  end
endmodule

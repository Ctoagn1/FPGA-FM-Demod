module double_fifo #(parameter W = 8, DEPTH = 16) (
  input  logic clk, rst,
  input  logic push, pop,
  input  logic [W-1:0] din,
  output logic [W-1:0] dout_re,
  output logic [W-1:0] dout_im,
  output logic empty, full
);
  logic [W-1:0] mem_re [DEPTH];
  logic [W-1:0] mem_im [DEPTH];
  logic re;
  logic [$clog2(DEPTH):0] wr, rd;
  assign empty = (wr == rd);
  assign full  = (wr - rd) == DEPTH;
  assign dout_re  = mem_re[rd[$clog2(DEPTH)-1:0]];
  assign dout_im = mem_im[rd[$clog2(DEPTH)-1:0]];

  always_ff @(posedge clk) begin
    if (rst) begin wr <= 0; rd <= 0; re <= 1; end
    else begin
      if (push && !full)  begin 
        if (re) begin 
          re <= 0;
          mem_re[wr[$clog2(DEPTH)-1:0]] <= din; 
        end else begin 
          mem_im[wr[$clog2(DEPTH)-1:0]] <= din; 
          wr <= wr + 1;
          re <= 1; 
        end
      end
      if (pop  && !empty) rd <= rd + 1;
    end
  end
endmodule

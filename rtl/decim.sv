module decim#(
  D_FACTOR = 5,
  WIDTH = 16
  )
  (
    input logic clk,
    input logic rst,
    input logic input_valid,
    input logic [WIDTH-1:0] in_data,
    output logic output_ready,
    output logic [WIDTH-1:0] out_data
  );

  logic [$clog2(D_FACTOR):0] counter;

  always_ff @(posedge clk) begin 
    if (rst) begin 
      output_ready <= 0;
      counter <= 0;
    end else begin 
      if (input_valid) counter <= counter + 1;
      output_ready <= 0;
      if(counter == D_FACTOR - 1 && input_valid) begin 
        output_ready <= 1;
        out_data <= in_data;
        counter <= 0;
      end
    end
  end

endmodule

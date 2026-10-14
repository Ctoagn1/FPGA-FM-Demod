module subtractor#(
  parameter I_WIDTH = 16
  )(
    input logic clk,
    input logic rst,
    input logic input_valid,
    input logic [I_WIDTH-1:0] data,
    output logic output_valid,
    output logic [I_WIDTH-1:0] sub_data
  );

  logic [I_WIDTH-1:0] prev;

  always_ff @(posedge clk) begin 
    if(rst) begin 
      prev <= 0;
      output_valid <= 0;
    end
    if (input_valid) begin 
      prev <= data;
      sub_data <= data - prev;
      output_valid <= 1;
    end
    if (output_valid) output_valid <= 0;
  end
endmodule

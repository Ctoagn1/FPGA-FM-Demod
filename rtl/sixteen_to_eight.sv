module sixteen_to_eight(
  input logic clk,
  input logic rst,
  input logic input_valid,
  input logic [15:0] in,
  output logic [7:0] out,
  output logic output_valid
  );

  logic high;
  logic [7:0] saved;
  always_ff @(posedge clk) begin 
    if (rst) begin 
      output_valid <= 0;
      high <= 0;
    end else begin
       
      if (high) begin 
        output_valid <= 1;
        out <= saved;
        high <= 0;
      end
      else if (input_valid) begin  
          high <= 1;
          output_valid <= 1;
          out <= in[7:0];
          saved <= in[15:8];
      end
      else output_valid <= 0;
    end
  end

endmodule

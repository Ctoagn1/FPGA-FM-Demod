module cordic_tb();
  parameter O_DEPTH = 16; //2pi
  parameter I_DEPTH = 8;
  parameter CLK_PERIOD = 10;
  localparam NUM_RUNS = 50;


  logic clk=0, rst=1, input_valid=0, output_valid;
  logic signed [I_DEPTH-1:0] x, y;
  logic [31:0] counter = 0;
  logic signed [O_DEPTH-1:0] phase;

  cordic c(
    .clk(clk), .rst(rst), .input_valid(input_valid), .in_x(x), .in_y(y), .input_ready(input_ready), .output_valid(output_valid), .phase(phase)
    );

    always #(CLK_PERIOD/2) clk = ~clk;
    real actual, phase_adj;
    real PI = 3.14159265358978;

    initial begin 
      repeat (5) @(posedge clk);
      rst <= 0;
      repeat (5) @(posedge clk);
      for (int i=0; i<NUM_RUNS; i++) begin 
        counter <= 0;
        x <= $urandom();
        y <= $urandom();
        input_valid <= 1;



        @(posedge clk);
        input_valid <= 0;
        while (!output_valid) begin 
          counter++;
          @(posedge clk);
        end
        actual <= $atan2(y, x);
        phase_adj <= $itor(phase / 65536.0 * 2 * PI);
        @(posedge clk)
        $display("calc_phase = %0f, actual_phase = %0f, in_x = %0d, in_y = %0d, cycles = %0d", phase_adj, actual, x, y, counter);
      end

    end

  initial begin
    #(CLK_PERIOD * NUM_RUNS * 50);
    $fatal(1, "TIMEOUT");
  end


    
endmodule

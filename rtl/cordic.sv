module cordic#(
  parameter I_DEPTH = 8,
  parameter C_DEPTH = 16,
  parameter O_DEPTH = 16, //2pi
  parameter MAXITER = 10
  )(
  input logic clk,
  input logic rst,
  input logic input_valid,
  input logic signed [I_DEPTH-1:0] in_x,
  input logic signed  [I_DEPTH-1:0] in_y,
  output logic input_ready,
  output logic output_valid,
  output logic [O_DEPTH-1:0] phase
  );
  typedef enum {IDLE, INIT, RUNNING, FIN} cstate ;
  cstate state;

  typedef enum {Q1, Q2, Q3} quad;
  quad quadrant;

  assign input_ready = (state == IDLE);

  logic [$clog2(MAXITER):0] iter;
  logic signed [C_DEPTH-1:0] x; //q10.6
  logic signed  [C_DEPTH-1:0] y; 
  
  localparam logic [15:0] CTABLE [0:9] = '{16'd8192, 16'd4836, 16'd2555, 16'd1297,
    16'd651, 16'd326, 16'd163, 16'd81, 16'd41, 16'd20};
  localparam PI = 16'h8000;

  always_ff @(posedge clk ) begin 
  if (rst) begin 
    state <= IDLE;
    output_valid <= 0;
    iter <= 0;
  end else begin 
    case (state)
      IDLE: begin 
        output_valid <= 0;
        if (input_valid) begin 
          iter <= 0;
          x <= {{2{in_x[I_DEPTH-1]}}, in_x, 6'b000000};
          y <= {{2{in_y[I_DEPTH-1]}}, in_y, 6'b000000};
          state <= INIT;
        end
      end

      INIT: begin 
        phase <= 0; 
        quadrant <= Q1;
        if(x < 0) begin 
          quadrant <= ((y > 0) ? Q2 : Q3);
          x <= ~x + 1;
          y <= ~y + 1;
        end
        state <= RUNNING;
      end

      RUNNING: begin 
        if (y <= 0) begin 
          x <= x - (y >>> iter);
          y <= y + (x >>> iter);
          phase <= phase - CTABLE[iter]; 
        end 
        else begin 
          x <= x + (y >>> iter);
          y <= y - (x >>> iter);
          phase <= phase + CTABLE[iter];
        end
        if(iter >= MAXITER - 1) begin
          state <= FIN;
        end else iter <= iter + 1;
      end

      FIN: begin 
        if (quadrant == Q2) phase <= phase + PI;
        else if (quadrant == Q3) phase <= phase - PI;
        output_valid <= 1;
        state <= IDLE;
      end
    endcase
  end
  end


endmodule

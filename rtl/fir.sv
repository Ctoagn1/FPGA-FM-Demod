module fir(
  input logic clk,
  input logic rst,
  input logic input_valid,
  input logic [15:0] in_data,
  output logic [15:0] out_data,
  output logic out_ready
  );
  parameter TAPS = 93;
  parameter RUNS = TAPS/2 + 1;
  parameter HIST_WIDTH = 128;
  parameter DECIM = 5;


    logic [$clog2(RUNS):0] counter;
    logic [$clog2(RUNS):0] rd_a;
    logic [$clog2(RUNS):0] rd_b;
    logic [$clog2(RUNS):0] wr;
    logic [$clog2(DECIM):0] d_cnt;


    logic signed [15:0] a_r, b_r, c_r;
    logic v;
    logic signed [31:0] acc; 
    logic signed [15:0] taps [0:RUNS-1] = '{-4, -3, -1, 4, 11, 17, 20, 18, 7, -9, -30, -49, -58, -53, -29, 11, 60, 105, 130, 124, 79, 0, -99, -193, -254, -256, -184, -43, 141, 329, 465, 499, 400, 161, -181, -559, -877, -1030, -928, -516, 208, 1189, 2313, 3430, 4380, 5016, 5240}; //Q1.15 
    logic signed [15:0] hist [HIST_WIDTH-1:0];
    
    typedef enum {IDLE, ACTIVE, OUT} fstate;
    fstate state;

  always @(posedge clk) begin 
    if (rst) begin
      acc <= 0;
      d_cnt <= 0;
      v <= 0;
      state <= IDLE;
      wr <= 0;
      rd_a <= 0;
      rd_b <= 0;
      for (int i=0; i<TAPS; i++) begin 
        hist[i] <= 0;
      end
    end 
    else case (state) 
      IDLE: begin 
        v <= 0;
        out_ready <= 0;
        if (input_valid) begin 
          hist[wr] <= in_data;
          wr <= wr + 1;
          if (d_cnt == DECIM-1) begin 
            d_cnt <= 0;
            state <= ACTIVE;
            rd_a <= wr;
            rd_b <= wr - (RUNS-1);
            counter <= 0;
            acc <= 0;
          end else d_cnt <= d_cnt + 1;
        end
      end
      ACTIVE: begin
        if(counter < RUNS) begin 
          if (v)
            acc <= acc + (a_r + ((counter == RUNS-1_) ? 0 : b_r)) * c_r;
          
          a_r <= hist[rd_a];
          b_r <= hist[rd_b];
          c_r <= taps[counter];
          v <= 1;

          rd_a <= rd_a - 1;
          rd_b <= rd_b + 1;
          counter <= counter + 1;
        end else state <= OUT;
      end
      OUT: begin 
        out_data <= (acc >>> 15);
        out_ready <= 1;
        state <= IDLE;
      end
    endcase
  end
endmodule

`default_nettype none

//https://github.com/dalance/svlint
//https://github.com/dalance/svls

module template #(
  parameter int P_ACC_SIZE = 32
)(
  input logic i_clk,
  input logic i_n_rst,

  input logic [15:0] i_increment,
  output logic [P_ACC_SIZE-1:0] o_accumulator
);

  typedef struct packed {
    logic [P_ACC_SIZE-1:0] accumulator;
  } t_state;

  t_state curr, next;
  
  //synchronous logic
  always_ff @(posedge clk, negedge n_rst) begin
    if (!n_rst) begin
      curr <= '0;
    end else begin
      curr <= next;
    end
  end
  
  //next state logic
  always_comb begin
    next = curr;
    
    next.accumulator = curr.accumulator + i_increment;
  end
  
  //output
  assign o_accumulator = curr.accumulator;
  
endmodule
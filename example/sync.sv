
module sync #(
  parameter STAGES = 2
) (
  input  clk,
  input  in,
  output out
);

  (* ASYNC_REG = "TRUE" *)
  logic [STAGES-1: 0] sync_reg;

  always @(posedge clk) begin
     sync_reg <= {sync_reg[STAGES-2:0], in};
  end

  assign out = sync_reg[STAGES-1] ;

endmodule


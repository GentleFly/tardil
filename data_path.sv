
(* dont_touch="true" *)
module data_path #(
  parameter DATA_DEPTH = 10,
  parameter COMB_DEPTH = 100
) (
  input clk,
  input rst,
  input in,
  output out
);
  wire [DATA_DEPTH-1:0] ff_to_comb;

  genvar i;
	generate for (i = 0; i < DATA_DEPTH; i = i + 1) begin
    if (i==0) begin
      wire interal;

      comb_path #(
        .DEPTH(COMB_DEPTH)
      ) cp_i (
        .in(in),
        .out(interal)
      );

      register register_i(
        .c(clk),
        .r(rst),
        .d(interal),
        .q(ff_to_comb[i])
      );
    end else begin
      wire interal;

      comb_path #(
        .DEPTH(COMB_DEPTH)
      ) cp_i (
        .in(ff_to_comb[i-1]),
        .out(interal)
      );

      register register_i(
        .c(clk),
        .r(rst),
        .d(interal),
        .q(ff_to_comb[i])
      );
    end
  end endgenerate
  assign out = ff_to_comb[DATA_DEPTH-1];

endmodule


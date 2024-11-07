
module comb_path #(
  parameter DEPTH = 10
) (
  input in,
  output out
);
  wire [(DEPTH/2)-1:0] interal;

  genvar i;
	generate for (i = 0; i < DEPTH/2; i = i + 1) begin
    if (i==0) begin
      winv winv_i (
        .i(in),
        .o(interal[i])
      );
    end else begin
      winv winv_i (
        .i(interal[i-1]),
        .o(interal[i])
      );
    end
  end endgenerate
  assign out = interal[(DEPTH/2)-1];

endmodule


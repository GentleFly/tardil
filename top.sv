
module top (
  input clock,
  input rst,
  input in,
  output out
);

  wire clk;
  wire [1:0] interal;

   BUFG BUFG_inst (
      .O(clk),
      .I(clock)
   );

  data_path #(
    .DATA_DEPTH(10),
    .COMB_DEPTH(3)
  ) i_dp_0 (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(interal[0])
  );

  data_path #(
    .DATA_DEPTH(1),
    .COMB_DEPTH(30)
  ) i_dp_1 (
    .clk(clk),
    .rst(rst),
    .in(interal[0]),
    .out(interal[1])
  );

  data_path #(
    .DATA_DEPTH(10),
    .COMB_DEPTH(3)
  ) i_dp_2 (
    .clk(clk),
    .rst(rst),
    .in(interal[1]),
    .out(out)
  );

endmodule

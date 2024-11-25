
module clocks (
  input in,
  output out_inv,
  output out
);

   // BUFG BUFG_inst0 (
   //    .O(out),
   //    .I(in)
   // );

   // // after opt_design will be converted to IS_INVERTED=true on register's clock pin
   // assign out_inv = ~out;

  clk_wiz_0 clk_wiz_0_instance (
    // Clock out ports
    .clk_p000(clk_p000),     // output clk_p000
    .clk_p090(clk_p090),     // output clk_p090
    .clk_p180(clk_p180),     // output clk_p180
    .clk_p270(clk_p270),     // output clk_p270
    .clk_p360(clk_p360),     // output clk_p360
    .clk_n090(clk_n090),     // output clk_n090
    .clk_n180(clk_n180),     // output clk_n180
    // Status and control signals
    .reset(reset), // input reset
    .locked(locked),       // output locked
    // Clock in ports
    .clk_in1(in)      // input clk_in1
  );
  assign out = clk_p000;


endmodule



module clocks (
  input in,
  output out_inv,
  output out
);

   BUFG BUFG_inst0 (
      .O(out),
      .I(in)
   );

   // after opt_design will be converted to IS_INVERTED=true on register's clock pin
   assign out_inv = ~out;

endmodule


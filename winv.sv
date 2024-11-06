
(* dont_touch="true" *)
module winv (
  input i,
  output o
);
  wire interal;

  inv i_inv_i ( .i(i), .o(interal));
  inv i_inv_o ( .i(interal), .o(o));

endmodule


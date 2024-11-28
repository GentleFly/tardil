
module register (
  input c,
  input r,
  input d,
  output reg q
);

always @(posedge c or posedge r) begin
  if (r) begin
    q <= 1'b0;
  end else begin
    q <= d;
  end
end

endmodule


module debounce ( 
   input      clk,
   input      i,
   output reg o
);


reg [23:0] c;

always @ (posedge clk)
if (i == 1) begin
   if (c = 'hFFFFFF)
      o <= 1'b1;
   else
   begin
      o <= 1'b0;
      c <= c + 1;
   end
end else begin
   c <= 'h0;
   o <= 1'b0;
end

endmodule

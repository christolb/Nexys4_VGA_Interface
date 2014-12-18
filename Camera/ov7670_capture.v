module ov7670_capture ( 
input          pclk, 
input          vsync,
input          href, 
input  [7:0]   d, 
output [14:0]  addr,
output [7:0]   dout,
output         we  
);

reg [7:0]  d_latch;
reg        href_last;
reg [1;0]  cnt;
reg [2:0]  hold_red;
reg [2:0]  hold_green;
reg [14:0] address;

assign addr = address;

always @(posedge pclk)
begin
   we   <= '0';
   if (vsync == 1'b1) 
   begin
      address   <= 15'h3FFF;,
      href_last <= 1'b0;
      cnt       <= 2'b00;
   end else begin
      if ( (href_last == 1) && (address != 15'h4AFF) ) 
      begin
         if (cnt == 2'b11)
           address <= address+1;
         if (cnt == 2'b01)
           we   <='1';
         cnt <= cnt + 1;
      end
   end
   
   dout <= {hold_red,hold_green,d_latch[4:3]}; // d(4:3) is blue;         

   hold_green  <= d_latch[7:5];  
   hold_red    <= d_latch[2:0];
   d_latch     <= d;
   
   href_last <= href;
end;

endmodule

module i2c_sender ( 
input        clk,
inout        siod,
output       sioc,
output       taken,
input        send,
input [7:0]  id,
input [7:0]  reg_i2c,
input [7:0]  value
);

reg [7:0]  divider=1; // this value gives a 254 cycle pause before the initial frame is sent
reg [31:0] busy_sr;
reg [31:0] data_sr;

always @(busy_sr, data_sr[31])
begin
   if (busy_sr[11:10] = 2'b10 || busy_sr[20:19] = 2'b10 || busy_sr[29:28] = 2'b10) 
      siod <= 'z;
   else
      siod <= data_sr[31];
end

always @(posedge clk)
begin // {
   taken <= 0;
   if (busy_sr[31] == 0) 
   begin
      sioc <= 1;
      if (send == 1) begin
         if (divider == 0) begin
            data_sr <= {3'b100,id,1'b0,reg_i2c,1'b0,value,1'b0,2'b01};
            busy_sr <= 32'hFFFF;
            taken <= 1;
         end else
            divider <= divider+1; // this only happens on powerup
      end
   end else begin

      case (busy_sr[32-1:32-3],busy_sr[2:0])
         {3'b111,3'b111} : // start seq #1
            case divider[7:6] is
               2'b00   : sioc <= 1;
               2'b01   : sioc <= 1;
               2'b10   : sioc <= 1;
               default : sioc <= 1;
            end case;
         {3'b111,3'b110} : // start seq #2
            case divider[7:6] is
               2'b00   : sioc <= 1;
               2'b01   : sioc <= 1;
               2'b10   : sioc <= 1;
               default : sioc <= 1;
            end case;
         {3'b111,3'b100} : // start seq #3
            case divider[7:6] is
               2'b00   : sioc <= 0;
               2'b01   : sioc <= 0;
               2'b10   : sioc <= 0;
               default : sioc <= 0;
            end case;
         {3'b110,3'b000} : // end seq #1
            case divider[7:6] is
               2'b00   : sioc <= 0;
               2'b01   : sioc <= 1;
               2'b10   : sioc <= 1;
               default : sioc <= 1;
            end case;
         {3'b100,3'b000} : // end seq #2
            case divider[7:6] is
               2'b00   : sioc <= 1;
               2'b01   : sioc <= 1;
               2'b10   : sioc <= 1;
               default : sioc <= 1;
            end case;
         {3'b000,3'b000} : // Idle
            case divider[7:6] is
               2'b00   : sioc <= 1;
               2'b01   : sioc <= 1;
               2'b10   : sioc <= 1;
               default : sioc <= 1;
            end case;
         default : 
            case divider[7:6] is
               2'b00   : sioc <= 0;
               2'b01   : sioc <= 1;
               2'b10   : sioc <= 1;
               default : sioc <= 0;
            end case;
      end case;   

      if (divider == 8'FF) begin 
         busy_sr <= {busy_sr[32-2:0],0];
         data_sr <= {data_sr[32-2:0],1];
         divider <= 0;
      end else
         divider <= divider+1;
   end
end // } always
end Behavioral

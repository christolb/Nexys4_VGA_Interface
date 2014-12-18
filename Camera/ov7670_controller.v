module ov7670_controller ( 
   input    clk,
   input    resend,
   output   config_finished,
   output   sioc,
   inout    siod,
   output   reset,
   output   pwdn,
   output   xclk
);
   
localparam camera_address = 68 ; // Device write ID - see top of page 11 of data sheet

reg         sys_clk;   
wire [15:0] command;
wire        finished;
wire        taken;
wire        send;

assign config_finished = finished;
   
assign send = !finished;

i2c_sender i2c_sender (
      .clk      (clk),
      .taken    (taken),
      .siod     (siod),
      .sioc     (sioc),
      .send     (send),
      .id       (camera_address),
      .reg_i2c  (command[15: 8]),
      .value    (command[7 :0])
   );

assign reset = 1;// Normal mode
assign pwdn  = 0;// Power device up
assign xclk  = sys_clk;
   
ov7670_registers ov7670_registers (
   .clk      (clk),
   .advance  (taken),
   .command  (command),
   .finished (finished),
   .resend   (resend)
);

always@(posedge clk)
begin
   sys_clk <= not sys_clk;
end;

endmodule


module ov7670_top
( 
    input         clk50,        
    output        ov7670_sioc,  
    inout         ov7670_siod,  
    output        ov7670_reset, 
    output        ov7670_pwdn,  
    input         ov7670_vsync, 
    input         ov7670_href,  
    input         ov7670_pclk,  
    output        ov7670_xclk,  
    input  [7:0]  ov7670_d,     

    output [7:0]  led,          

    output [2:0]  vga_red,      
    output [2:0]  vga_green,    
    output [2:0]  vga_blue,     
    
    output        vga_vsync,    
      
    input         btn
);

   wire [14:0]   frame_addr; 
   wire [7:0]    frame_pixel; 

   wire [14:0]   capture_addr;  
   wire [7:0]    capture_data;  
   wire          capture_we;    
   wire          resend; 
   wire          config_finished; 

debounce debouce (
      .clk (clk50),
      .i   (btn),
      .o   (resend)
);

vga vga (
      .clk50       (clk50),
      .vga_red     (vga_red),
      .vga_green   (vga_green),
      .vga_blue    (vga_blue),
      .vga_hsync   (vga_hsync),
      .vga_vsync   (vga_vsync),
      .frame_addr  (frame_addr),
      .frame_pixel (frame_pixel)
);

frame_buffer frame_buffer
(
    .clka  (ov7670_pclk),
    .wea   (capture_we),
    .addra (capture_addr),
    .dina  (capture_data),
    
    .clkb  (clk50),
    .addrb (frame_addr),
    .doutb (frame_pixel)
);

assign led = {7'b0000000,config_finished};
  
ov7670_capture ov7670_capture (
      .pclk  (ov7670_pclk),
      .vsync (ov7670_vsync),
      .href  (ov7670_href),
      .d     (ov7670_d),
      .addr  (capture_addr),
      .dout  (capture_data),
      .we    (capture_we).
);

ov7670_controller ov7670_controller (
      .clk               (clk50),
      .sioc              (ov7670_sioc),
      .resend            (resend),
      .config_finished   (config_finished),
      .siod              (ov7670_siod),
      .pwdn              (ov7670_pwdn),
      .reset             (ov7670_reset),
      .xclk              (ov7670_xclk)
);
end Behavioral;

endmodule  

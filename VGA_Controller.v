----------------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Author     : Christol Barnes 
-- Institution: UCSB
-- Description: Simple VHDL VGA Controller
--              Generates HS, VS, RED, GREEN and BLUE outputs
----------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.math_real.all;

entity Vga is
    Port ( CLK_I : in  STD_LOGIC;
           -- VGA Output Signals
           VGA_HS_O : out  STD_LOGIC; -- HSYNC OUT
           VGA_VS_O : out  STD_LOGIC; -- VSYNC OUT
           VGA_RED_O    : out  STD_LOGIC_VECTOR (3 downto 0); -- Red signal going to the VGA interface
           VGA_GREEN_O  : out  STD_LOGIC_VECTOR (3 downto 0); -- Green signal going to the VGA interface
           VGA_BLUE_O   : out  STD_LOGIC_VECTOR (3 downto 0); -- Blue signal going to the VGA interface
           -- Input Signals
           -- RGB from Memory 
           IMAGE_RED   : in STD_LOGIC_VECTOR (3 downto 0);
           IMAGE_GREEN : in STD_LOGIC_VECTOR (3 downto 0);
           IMAGE_BLUE  : in STD_LOGIC_VECTOR (3 downto 0);
           );
end Vga;

architecture Behavioral of Vga is

-------------------------------------------------------------------------

-- Component Declarations

-------------------------------------------------------------------------


   -- To generate the 108 MHz Pixel Clock
   -- needed for a resolution of 1280*1024 pixels
   COMPONENT PxlClkGen
   PORT
    (-- Clock in ports
     CLK_IN1           : in std_logic;
     -- Clock out ports
     CLK_OUT1          : out std_logic;
     -- Status and control signals
     LOCKED            : out std_logic
    );
   END COMPONENT;

-------------------------------------------------------------

-- Constants for various VGA Resolutions

-------------------------------------------------------------

--***640x480@60Hz***--  
--constant FRAME_WIDTH : natural := 640;
--constant FRAME_HEIGHT : natural := 480;

--constant H_FP : natural := 16; --H front porch width (pixels)
--constant H_PW : natural := 96; --H sync pulse width (pixels)
--constant H_MAX : natural := 800; --H total period (pixels)
--
--constant V_FP : natural := 10; --V front porch width (lines)
--constant V_PW : natural := 2; --V sync pulse width (lines)
--constant V_MAX : natural := 525; --V total period (lines)

--constant H_POL : std_logic := '0';
--constant V_POL : std_logic := '0';

--***800x600@60Hz***--
--constant FRAME_WIDTH : natural := 800;
--constant FRAME_HEIGHT : natural := 600;
--
--constant H_FP : natural := 40; --H front porch width (pixels)
--constant H_PW : natural := 128; --H sync pulse width (pixels)
--constant H_MAX : natural := 1056; --H total period (pixels)
--
--constant V_FP : natural := 1; --V front porch width (lines)
--constant V_PW : natural := 4; --V sync pulse width (lines)
--constant V_MAX : natural := 628; --V total period (lines)
--
--constant H_POL : std_logic := '1';
--constant V_POL : std_logic := '1';

--***1280x1024@60Hz***--
constant FRAME_WIDTH : natural := 1280;
constant FRAME_HEIGHT : natural := 1024;

constant H_FP : natural := 48; --H front porch width (pixels)
constant H_PW : natural := 112; --H sync pulse width (pixels)
constant H_MAX : natural := 1688; --H total period (pixels)

constant V_FP : natural := 1; --V front porch width (lines)
constant V_PW : natural := 3; --V sync pulse width (lines)
constant V_MAX : natural := 1066; --V total period (lines)

constant H_POL : std_logic := '1';
constant V_POL : std_logic := '1';

--***1920x1080@60Hz***--
--constant FRAME_WIDTH : natural := 1920;
--constant FRAME_HEIGHT : natural := 1080;
--
--constant H_FP : natural := 88; --H front porch width (pixels)
--constant H_PW : natural := 44; --H sync pulse width (pixels)
--constant H_MAX : natural := 2200; --H total period (pixels)
--
--constant V_FP : natural := 4; --V front porch width (lines)
--constant V_PW : natural := 5; --V sync pulse width (lines)
--constant V_MAX : natural := 1125; --V total period (lines)
--
--constant H_POL : std_logic := '1';
--constant V_POL : std_logic := '1';

-------------------------------------------------------------------------

-- Signal Declarations

-------------------------------------------------------------------------


-------------------------------------------------------------------------

-- VGA Controller specific signals: Counters, Sync, R, G, B

-------------------------------------------------------------------------
-- Pixel clock, in this case 108 MHz
signal pxl_clk : std_logic;
-- The active signal is used to signal the active region of the screen (when not blank)
signal active  : std_logic;

-- Horizontal and Vertical counters
signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');

-- Pipe Horizontal and Vertical Counters
signal h_cntr_reg_dly   : std_logic_vector(11 downto 0) := (others => '0');
signal v_cntr_reg_dly   : std_logic_vector(11 downto 0) := (others => '0');

-- Horizontal and Vertical Sync
signal h_sync_reg : std_logic := not(H_POL);
signal v_sync_reg : std_logic := not(V_POL);
-- Pipe Horizontal and Vertical Sync
signal h_sync_reg_dly : std_logic := not(H_POL);
signal v_sync_reg_dly : std_logic :=  not(V_POL);

-- VGA R, G and B signals coming from the main multiplexers
signal vga_red_cmb   : std_logic_vector(3 downto 0);
signal vga_green_cmb : std_logic_vector(3 downto 0);
signal vga_blue_cmb  : std_logic_vector(3 downto 0);
--The main VGA R, G and B signals, validated by active
signal vga_red    : std_logic_vector(3 downto 0);
signal vga_green  : std_logic_vector(3 downto 0);
signal vga_blue   : std_logic_vector(3 downto 0);
-- Register VGA R, G and B signals
signal vga_red_reg   : std_logic_vector(3 downto 0) := (others =>'0');
signal vga_green_reg : std_logic_vector(3 downto 0) := (others =>'0');
signal vga_blue_reg  : std_logic_vector(3 downto 0) := (others =>'0');

-------------------------------------------------------------------------

-- Signals for registering the inputs

-------------------------------------------------------------------------
signal IMAGE_RED_dly   : std_logic_vector (3 downto 0);
signal IMAGE_BLUE_dly  : std_logic_vector (3 downto 0);
signal IMAGE_GREEN_dly : std_logic_vector (3 downto 0);


-------------------------------------------------------------------------

begin
  
------------------------------------

-- Generate the 108 MHz pixel clock 

------------------------------------
   Inst_PxlClkGen: PxlClkGen
   port map
    (-- Clock in ports
     CLK_IN1   => CLK_I,
     -- Clock out ports
     CLK_OUT1  => pxl_clk,
     -- Status and control signals
     LOCKED   => open
    );

---------------------------------------------------------------

-- Generate Horizontal, Vertical counters and the Sync signals

---------------------------------------------------------------
  -- Horizontal counter
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (h_cntr_reg = (H_MAX - 1)) then
        h_cntr_reg <= (others =>'0');
      else
        h_cntr_reg <= h_cntr_reg + 1;
      end if;
    end if;
  end process;
  -- Vertical counter
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if ((h_cntr_reg = (H_MAX - 1)) and (v_cntr_reg = (V_MAX - 1))) then
        v_cntr_reg <= (others =>'0');
      elsif (h_cntr_reg = (H_MAX - 1)) then
        v_cntr_reg <= v_cntr_reg + 1;
      end if;
    end if;
  end process;
  -- Horizontal sync
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (h_cntr_reg >= (H_FP + FRAME_WIDTH - 1)) and (h_cntr_reg < (H_FP + FRAME_WIDTH + H_PW - 1)) then
        h_sync_reg <= H_POL;
      else
        h_sync_reg <= not(H_POL);
      end if;
    end if;
  end process;
  -- Vertical sync
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (v_cntr_reg >= (V_FP + FRAME_HEIGHT - 1)) and (v_cntr_reg < (V_FP + FRAME_HEIGHT + V_PW - 1)) then
        v_sync_reg <= V_POL;
      else
        v_sync_reg <= not(V_POL);
      end if;
    end if;
  end process;
  
--------------------

-- The active 

--------------------  
  -- active signal
  active <= '1' when h_cntr_reg_dly < FRAME_WIDTH and v_cntr_reg_dly < FRAME_HEIGHT
            else '0';

--------------------

--------------------

-- Register Inputs

--------------------
register_inputs: process (pxl_clk, v_sync_reg)
  begin
    if (rising_edge(pxl_clk)) then
      if v_sync_reg = V_POL then -- All of the signals, except the incoming microphone data 
        IMAGE_RED_dly     <=  IMAGE_RED   (3 downto 0); 
        IMAGE_BLUE_dly    <=  IMAGE_BLUE  (3 downto 0); 
        IMAGE_GREEN_dly   <=  IMAGE_GREEN (3 downto 0); 
      end if;
    end if;
end process register_inputs;

-------------------------------------------------------------

-- Main Multiplexers for the VGA Red, Green and Blue signals

-------------------------------------------------------------
----------
-- Red
----------

   vga_red   <=   IMAGE_RED_dly   when h_cntr_reg_dly > 1 and h_cntr_reg_dly < H_MAX
                                and v_cntr_reg_dly > 1 and v_cntr_reg_dly < V_MAX;

   vga_blue  <=   IMAGE_BLUE_dly  when h_cntr_reg_dly > 1 and h_cntr_reg_dly < H_MAX
                                and v_cntr_reg_dly > 1 and v_cntr_reg_dly < V_MAX;

   vga_green <=   IMAGE_GREEN_dly when h_cntr_reg_dly > 1 and h_cntr_reg_dly < H_MAX
                                and v_cntr_reg_dly > 1 and v_cntr_reg_dly < V_MAX;

------------------------------------------------------------
-- Turn Off VGA RBG Signals if outside of the active screen
-- Make a 4-bit AND logic with the R, G and B signals
------------------------------------------------------------
 vga_red_cmb <= (active & active & active & active) and vga_red;
 vga_green_cmb <= (active & active & active & active) and vga_green;
 vga_blue_cmb <= (active & active & active & active) and vga_blue;
 

 -- Register Outputs
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then

       v_sync_reg_dly <= v_sync_reg;
      h_sync_reg_dly <= h_sync_reg;
      vga_red_reg    <= vga_red_cmb;
      vga_green_reg  <= vga_green_cmb;
      vga_blue_reg   <= vga_blue_cmb;      
    end if;
  end process;

  -- Assign outputs
  VGA_HS_O     <= h_sync_reg_dly;
  VGA_VS_O     <= v_sync_reg_dly;
  VGA_RED_O    <= vga_red_reg;
  VGA_GREEN_O  <= vga_green_reg;
  VGA_BLUE_O   <= vga_blue_reg;

end Behavioral;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity board_area is
  port (
    Clk          : in std_logic;

    Dash_T       : in std_logic;

    -- received
    Note_rx_x    : in std_logic_vector(7 downto 0);
    Note_rx_y    : in std_logic_vector(7 downto 0);
    Note_rx_v    : in std_logic;

    -- generated
    Note_x       : in std_logic_vector(7 downto 0);
    Note_y       : in std_logic_vector(7 downto 0);
    Note_v       : in std_logic;
    Restore      : in std_logic;
    Save         : in std_logic;

    -- output
    Board_top    : out std_logic_vector(7 downto 0);
    Board_bottom : out std_logic_vector(7 downto 0);
    Board_left   : out std_logic_vector(7 downto 0);
    Board_right  : out std_logic_vector(7 downto 0)
  );
end board_area;

architecture rtl of board_area is

  signal c_x             : std_logic_vector(31 downto 0);
  signal c_y             : std_logic_vector(31 downto 0);
  signal c_board_top     : std_logic_vector(7 downto 0);
  signal c_board_bottom  : std_logic_vector(7 downto 0);
  signal c_board_left    : std_logic_vector(7 downto 0);
  signal c_board_right   : std_logic_vector(7 downto 0);
  signal r_shadow_top    : std_logic_vector(7 downto 0);
  signal r_shadow_bottom : std_logic_vector(7 downto 0);
  signal r_shadow_left   : std_logic_vector(7 downto 0);
  signal r_shadow_right  : std_logic_vector(7 downto 0);

begin

  process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Dash_T = '1') then
        c_x            <= (others => '0');
        c_y            <= (others => '0');
        c_board_top    <= (others => '0');
        c_board_bottom <= (others => '0');
        c_board_left   <= (others => '0');
        c_board_right  <= (others => '0');

      elsif (Note_rx_v = '1') then
        c_x <= (X"000000" & c_board_left) + (X"000000" & Note_rx_x(7 downto 0));
        c_y <= (X"000000" & c_board_top)  + (X"000000" & Note_rx_y(7 downto 0));
        -- TODO: check timing between above and below
        if (Note_rx_x(7 downto 0) = X"00") then
          c_board_left <= c_board_left - 1;
        end if;
        if (Note_rx_y(7 downto 0) = X"00") then
          c_board_top <= c_board_top - 1;
        end if;
        if (c_board_right < c_x) then
          c_board_right <= c_x(7 downto 0);
        end if;
        if (c_board_bottom < c_y) then
          c_board_bottom <= c_y(7 downto 0);
        end if;

      elsif (Note_v = '1') then
        c_x <= (X"000000" & c_board_left) + (X"000000" & Note_x(7 downto 0));
        c_y <= (X"000000" & c_board_top)  + (X"000000" & Note_y(7 downto 0));
        -- TODO: check timing between above and below
        if (Note_x(7 downto 0) = X"00") then
          c_board_left <= c_board_left - 1;
        end if;
        if (Note_y(7 downto 0) = X"00") then
          c_board_top <= c_board_top - 1;
        end if;
        if (c_board_right < c_x) then
          c_board_right <= c_x(7 downto 0);
        end if;
        if (c_board_bottom < c_y) then
          c_board_bottom <= c_y(7 downto 0);
        end if;

      elsif (Restore = '1') then
        -- restore
        c_board_left   <= r_shadow_left;
        c_board_top    <= r_shadow_top;
        c_board_right  <= r_shadow_right;
        c_board_bottom <= r_shadow_bottom;
      end if;

      if (Save = '1') then
        r_shadow_left   <= c_board_left;
        r_shadow_right  <= c_board_right;
        r_shadow_top    <= c_board_top;
        r_shadow_bottom <= c_board_bottom;
      end if;

    end if;
  end process;

  Board_top    <= c_board_top;
  Board_bottom <= c_board_bottom;
  Board_left   <= c_board_left;
  Board_right  <= c_board_right;

end rtl;

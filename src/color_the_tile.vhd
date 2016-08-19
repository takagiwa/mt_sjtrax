library ieee;
use ieee.std_logic_1164.all;

entity color_the_tile is
  generic (
    DELAY_CYCLE : integer := 3 -- equal or less than 8
  );
  port (
    Clk         : in std_logic;
    Rst         : in std_logic;

    Color       : in std_logic_vector(3 downto 0);
    Tile        : in std_logic_vector(3 downto 0);
    Lc          : in std_logic_vector(3 downto 0);
    Rc          : in std_logic_vector(3 downto 0);
    Uc          : in std_logic_vector(3 downto 0);
    Dc          : in std_logic_vector(3 downto 0);
    C_v         : in std_logic;

    Color_out   : out std_logic_vector(3 downto 0);
    Color_out_v : out std_logic
  );
end color_the_tile;

architecture rtl of color_the_tile is

  constant NOTE_PLUS   : std_logic_vector(3 downto 0) := X"1";
  constant NOTE_SLASH  : std_logic_vector(3 downto 0) := X"2";
  constant NOTE_BSLASH : std_logic_vector(3 downto 0) := X"3";

  signal r_color : std_logic_vector(3 downto 0);
  signal r_tile  : std_logic_vector(3 downto 0);
  signal r_lc    : std_logic_vector(3 downto 0);
  signal r_rc    : std_logic_vector(3 downto 0);
  signal r_uc    : std_logic_vector(3 downto 0);
  signal r_dc    : std_logic_vector(3 downto 0);
  signal r_v     : std_logic;

  signal r_color_out : std_logic_vector(3 downto 0);

  signal r_color_v : std_logic_vector(8 downto 0);

begin

  process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (C_v = '1') then
        r_color <= Color;
        r_tile  <= Tile;
        r_lc    <= Lc;
        r_rc    <= Rc;
        r_uc    <= Uc;
        r_dc    <= Dc;
      end if;
      r_v <= C_v;
    end if;
  end process;

  process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (r_color = X"0") then
        if (r_tile = NOTE_PLUS) then
          if ((r_lc = X"1") or (r_rc = X"1") or (r_uc = X"2") or (r_dc = X"2")) then
            r_color_out <= X"1";
          else
            r_color_out <= X"2";
          end if;
        elsif (r_tile = NOTE_SLASH) then
          if ((r_lc = X"1") or (r_rc = X"2") or (r_uc = X"1") or (r_dc = X"2")) then
            r_color_out <= X"2";
          else
            r_color_out <= X"1";
          end if;
        elsif (r_tile = NOTE_BSLASH) then
          if ((r_lc = X"1") or (r_rc = X"2") or (r_uc = X"2") or (r_dc = X"1")) then
            r_color_out <= X"2";
          else
            r_color_out <= X"1";
          end if;
        else
          r_color_out <= X"3";
        end if;
      else
        r_color_out <= r_color;
      end if;

      r_color_v(8 downto 0) <= r_color_v(7 downto 0) & r_v;

    end if;
  end process;

  Color_out   <= r_color_out;
  Color_out_v <= r_color_v(DELAY_CYCLE);

end rtl;

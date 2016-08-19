library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity is_isolated is
  port (
    Clk   : in std_logic;
    Rst   : in std_logic;

    Turn  : in std_logic_vector(15 downto 0);

    Lc    : in std_logic_vector(3 downto 0);
    Rc    : in std_logic_vector(3 downto 0);
    Uc    : in std_logic_vector(3 downto 0);
    Dc    : in std_logic_vector(3 downto 0);
    C_v   : in std_logic;

    Res   : out std_logic;
    Color : out std_logic_vector(3 downto 0)
  );
end is_isolated;

architecture rtl of is_isolated is

  signal r_first_turn : std_logic;
  signal r_is_zero    : std_logic_vector(3 downto 0);
  signal r_res        : std_logic;
  signal r_color      : std_logic_vector(3 downto 0);

  signal r_v : std_logic;

begin

  process(Clk)
  begin
    if (rising_edge(Clk)) then
      r_v <= C_v;

      if (Turn = conv_std_logic_vector(1, 16)) then
        r_first_turn <= '1';
      else
        r_first_turn <= '0';
      end if;

      if (Lc = X"0") then
        r_is_zero(0) <= '1';
      else
        r_is_zero(0) <= '0';
      end if;
      if (Rc = X"0") then
        r_is_zero(1) <= '1';
      else
        r_is_zero(1) <= '0';
      end if;
      if (Uc = X"0") then
        r_is_zero(2) <= '1';
      else
        r_is_zero(2) <= '0';
      end if;
      if (Dc = X"0") then
        r_is_zero(3) <= '1';
      else
        r_is_zero(3) <= '0';
      end if;

      if ((Rst = '1') and (false)) then
        r_res <= '0';
      elsif (r_v = '1') then
        if (r_is_zero = "1111") then
          if (r_first_turn = '0') then
            r_res <= '1';
          else
            r_res <= '0';
          end if;
          r_color <= X"1";
        else
          r_res <= '0';
          r_color <= X"0";
        end if;
      end if;

    end if;
  end process;

  Res <= r_res;
  Color <= r_color;

end rtl;

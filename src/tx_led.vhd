library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity tx_led is
  generic (
    LIT_CYCLES : integer := 50000000
  );
  port (
    Clk : in std_logic;
    Rst : in std_logic;

    Src : in std_logic;
    Led : out std_logic
  );
end tx_led;

architecture rtl of tx_led is

  signal r_led : std_logic;
  signal c     : integer range 0 to LIT_CYCLES-1;

begin

  process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Rst = '1') then
        c <= 0;
      elsif ((c /= 0) and (c /= (LIT_CYCLES-1))) then
        c <= c + 1;
      elsif (Src = '1') then
        c <= c + 1;
      end if;
      if ((c /= 0) and (c < ((LIT_CYCLES/2)-1))) then
        r_led <= '1';
      else
        r_led <= '0';
      end if;
    end if;
  end process;

  Led <= r_led;

end rtl;

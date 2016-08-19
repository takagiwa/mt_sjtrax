library ieee;
use ieee.std_logic_1164.all;

entity is_prohibited_3 is
  port (
    Clk  : in std_logic;
    Rst  : in std_logic;

    Lc   : in std_logic_vector(3 downto 0);
    Rc   : in std_logic_vector(3 downto 0);
    Uc   : in std_logic_vector(3 downto 0);
    Dc   : in std_logic_vector(3 downto 0);
    C_v  : in std_logic;

    Res  : out std_logic
  );
end is_prohibited_3;

architecture rtl of is_prohibited_3 is

  signal r_equ_lr : std_logic;
  signal r_equ_ru : std_logic;
  signal r_equ_ud : std_logic;
  signal r_equ_dl : std_logic;
  signal r_l_zero : std_logic;
  signal r_r_zero : std_logic;
  signal r_u_zero : std_logic;
  signal r_d_zero : std_logic;
  signal r_cond   : std_logic_vector(3 downto 0);
  signal r_res    : std_logic;

  signal r_chk_delay : std_logic_vector(1 downto 0);

begin

  process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Lc = Rc) then
        r_equ_lr <= '1';
      else
        r_equ_lr <= '0';
      end if;
      if (Rc = Uc) then
        r_equ_ru <= '1';
      else
        r_equ_ru <= '0';
      end if;
      if (Uc = Dc) then
        r_equ_ud <= '1';
      else
        r_equ_ud <= '0';
      end if;
      if (Dc = Lc) then
        r_equ_dl <= '1';
      else
        r_equ_dl <= '0';
      end if;

      if (Lc = X"0") then
        r_l_zero <= '1';
      else
        r_l_zero <= '0';
      end if;
      if (Rc = X"0") then
        r_r_zero <= '1';
      else
        r_r_zero <= '0';
      end if;
      if (Uc = X"0") then
        r_u_zero <= '1';
      else
        r_u_zero <= '0';
      end if;
      if (Dc = X"0") then
        r_d_zero <= '1';
      else
        r_d_zero <= '0';
      end if;

      if ((r_equ_lr = '1') and (r_equ_ru = '1') and (r_u_zero = '0')) then
        r_cond(0) <= '1';
      else
        r_cond(0) <= '0';
      end if;
      if ((r_equ_ru = '1') and (r_equ_ud = '1') and (r_d_zero = '0')) then
        r_cond(1) <= '1';
      else
        r_cond(1) <= '0';
      end if;
      if ((r_equ_ud = '1') and (r_equ_dl = '1') and (r_l_zero = '0')) then
        r_cond(2) <= '1';
      else
        r_cond(2) <= '0';
      end if;
      if ((r_equ_dl = '1') and (r_equ_lr = '1') and (r_r_zero = '0')) then
        r_cond(3) <= '1';
      else
        r_cond(3) <= '0';
      end if;

      r_chk_delay(1 downto 0) <= r_chk_delay(0) & C_v;

      if ((r_cond /= "0000") and (r_chk_delay(1) = '1')) then
        r_res <= '1';
      else
        r_res <= '0';
      end if;
    end if;
  end process;

  Res <= r_res;

end rtl;

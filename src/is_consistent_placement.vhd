library ieee;
use ieee.std_logic_1164.all;

entity is_consistent_placement is
  port (
    Clk  : in std_logic;
    Rst  : in std_logic;

    Lc   : in std_logic_vector(3 downto 0);
    Rc   : in std_logic_vector(3 downto 0);
    Uc   : in std_logic_vector(3 downto 0);
    Dc   : in std_logic_vector(3 downto 0);
    C_v  : in std_logic;

    Tile : in std_logic_vector(3 downto 0);

    Res  : out std_logic
  );
end is_consistent_placement;

architecture rtl of is_consistent_placement is

  constant NOTE_PLUS   : std_logic_vector(3 downto 0) := X"1";
  constant NOTE_SLASH  : std_logic_vector(3 downto 0) := X"2";
  constant NOTE_BSLASH : std_logic_vector(3 downto 0) := X"3";

  signal r_lc : std_logic_vector(3 downto 0);
  signal r_rc : std_logic_vector(3 downto 0);
  signal r_uc : std_logic_vector(3 downto 0);
  signal r_dc : std_logic_vector(3 downto 0);
  signal r_v  : std_logic;
  signal r_tile : std_logic_vector(3 downto 0);

  signal r_nequ_lr : std_logic;
  signal r_nzero_l : std_logic;
  signal r_nzero_r : std_logic;
  signal r_nequ_ud : std_logic;
  signal r_nzero_u : std_logic;
  signal r_nzero_d : std_logic;
  signal r_nequ_lu : std_logic;
  signal r_nequ_rd : std_logic;
  signal r_nequ_ld : std_logic;
  signal r_nequ_ru : std_logic;

  signal r_res : std_logic;

begin

  process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (C_v = '1') then
        r_lc <= Lc;
        r_rc <= Rc;
        r_uc <= Uc;
        r_dc <= Dc;
      end if;
      r_v <= C_v;
      r_tile <= Tile;
    end if;
  end process;

  process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (r_lc /= r_rc) then
        r_nequ_lr <= '1';
      else
        r_nequ_lr <= '0';
      end if;
      if (r_uc /= r_dc) then
        r_nequ_ud <= '1';
      else
        r_nequ_ud <= '0';
      end if;
      if (r_lc /= r_uc) then
        r_nequ_lu <= '1';
      else
        r_nequ_lu <= '0';
      end if;
      if (r_rc /= r_dc) then
        r_nequ_rd <= '1';
      else
        r_nequ_rd <= '0';
      end if;
      if (r_lc /= r_dc) then
        r_nequ_ld <= '1';
      else
        r_nequ_ld <= '0';
      end if;
      if (r_rc /= r_uc) then
        r_nequ_ru <= '1';
      else
        r_nequ_ru <= '0';
      end if;

      if (r_lc /= X"0") then
        r_nzero_l <= '1';
      else
        r_nzero_l <= '0';
      end if;
      if (r_rc /= X"0") then
        r_nzero_r <= '1';
      else
        r_nzero_r <= '0';
      end if;
      if (r_uc /= X"0") then
        r_nzero_u <= '1';
      else
        r_nzero_u <= '0';
      end if;
      if (r_dc /= X"0") then
        r_nzero_d <= '1';
      else
        r_nzero_d <= '0';
      end if;

      if (r_tile = NOTE_PLUS) then
        if ((r_nequ_lr = '1') and (r_nzero_l = '1') and (r_nzero_r = '1')) then
          r_res <= '1';
        elsif ((r_nequ_ud = '1') and (r_nzero_u = '1') and (r_nzero_d = '1')) then
          r_res <= '1';
        else
          r_res <= '0';
        end if;
      elsif (r_tile = NOTE_SLASH) then
        if ((r_nequ_lu = '1') and (r_nzero_l = '1') and (r_nzero_u = '1')) then
          r_res <= '1';
        elsif ((r_nequ_rd = '1') and (r_nzero_r = '1') and (r_nzero_d = '1')) then
          r_res <= '1';
        else
          r_res <= '0';
        end if;
      elsif (r_tile = NOTE_BSLASH) then
        if ((r_nequ_ld = '1') and (r_nzero_l = '1') and (r_nzero_d = '1')) then
          r_res <= '1';
        elsif ((r_nequ_ru = '1') and (r_nzero_r = '1') and (r_nzero_u = '1')) then
          r_res <= '1';
        else
          r_res <= '0';
        end if;
      else
        r_res <= '0';
      end if;

    end if;
  end process;

  Res <= r_res;

end rtl;

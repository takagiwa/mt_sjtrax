library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity map_mem_w is
  port (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(19 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(19 DOWNTO 0);

    Rst  : in std_logic;
    Save : in std_logic;
    Restore : in std_logic;
    Busy : out std_logic
  );
end map_mem_w;

architecture rtl of map_mem_w is

  COMPONENT map_mem
    PORT (
      clka : IN STD_LOGIC;
      ena : IN STD_LOGIC;
      wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
      dina : IN STD_LOGIC_VECTOR(19 DOWNTO 0);
      douta : OUT STD_LOGIC_VECTOR(19 DOWNTO 0)
    );
  END COMPONENT;

  signal s_wea   : std_logic_vector(0 downto 0);
  signal s_addra : std_logic_vector(15 downto 0);
  signal s_dina  : std_logic_vector(19 downto 0);
  signal s_douta : std_logic_vector(19 downto 0);

  signal s_shadow_wea   : std_logic_vector(0 downto 0);
  signal s_shadow_addra : std_logic_vector(15 downto 0);
  signal s_shadow_dina  : std_logic_vector(19 downto 0);
  signal s_shadow_douta : std_logic_vector(19 downto 0);



  signal r_save      : std_logic;
  signal r_restore   : std_logic;
  signal r_saving    : std_logic;
  signal r_restoring : std_logic;

  signal c_r_addr     : std_logic_vector(15 downto 0);
  signal c_w_addr     : std_logic_vector(15 downto 0);
  signal r_addr_delay : std_logic_vector(3 downto 0);

  signal r_saving_delay    : std_logic_vector(3 downto 0);
  signal r_restoring_delay : std_logic_vector(3 downto 0);

begin

  flag_proc: process(clka)
  begin
    if (rising_edge(clka)) then
      r_save <= Save;
      r_restore <= Restore;

      if (Rst = '1') then
        r_saving <= '0';
        r_restoring <= '0';
      else
        if ((r_addr_delay(3) = '1') and (r_addr_delay(2) = '0')) then
          r_saving <= '0';
        elsif (r_save = '1') then
          r_saving <= '1';
        end if;
        if ((r_addr_delay(3) = '1') and (r_addr_delay(2) = '0')) then
          r_restoring <= '0';
        elsif (r_restore = '1') then
          r_restoring <= '1';
        end if;
      end if;

      r_saving_delay(3 downto 0) <= r_saving_delay(2 downto 0) & r_saving;
      r_restoring_delay(3 downto 0) <= r_restoring_delay(2 downto 0) & r_restoring;

    end if;
  end process;

  addr_proc: process(clka)
  begin
    if (rising_edge(clka)) then
      if ((r_save = '1') or (r_restore = '1')) then
        c_r_addr <= (others => '0');
        r_addr_delay(0) <= '0';
      elsif ((r_saving = '1') or (r_restoring = '1')) then
        if (c_r_addr /= X"FFFF") then
          c_r_addr <= c_r_addr + 1;
          r_addr_delay(0) <= '1';
        else
          r_addr_delay(0) <= '0';
        end if;
      else
        r_addr_delay(0) <= '0';
      end if;

      r_addr_delay(3 downto 1) <= r_addr_delay(2 downto 0);

      if ((r_save = '1') or (r_restore = '1')) then
        c_w_addr <= (others => '0');
      elsif (r_addr_delay(1) = '1') then
        c_w_addr <= c_w_addr + 1;
      end if;
    end if;
  end process;

  s_wea(0) <= r_addr_delay(1) or r_addr_delay(2) when (r_restoring = '1')
         else wea(0);
  s_addra <= c_w_addr when (r_restoring = '1')
        else c_r_addr when (r_saving = '1')
        else addra;
  s_dina <= s_shadow_douta when (r_restoring = '1')
       else dina;

  s_shadow_wea(0) <= r_addr_delay(1) or r_addr_delay(2) when (r_saving = '1')
                else '0';
  s_shadow_addra <= c_r_addr when (r_restoring = '1')
               else c_w_addr when (r_saving = '1')
               else X"0000";
  s_shadow_dina <= s_douta when (r_saving = '1')
              else X"00000";

  i_mem: map_mem
    port map (
      clka  => clka,
      ena   => ena,
      wea   => s_wea,
      addra => s_addra,
      dina  => s_dina,
      douta => s_douta
    );

  i_shadow_mem: map_mem
    port map (
      clka  => clka,
      ena   => ena,
      wea   => s_shadow_wea,
      addra => s_shadow_addra,
      dina  => s_shadow_dina,
      douta => s_shadow_douta
    );

  douta <= X"00000" when ((r_saving_delay(3) = '1') or (r_restoring_delay(3) = '1'))
      else s_douta;

  Busy <= r_saving or r_restoring;

end rtl;

------------------------------------------------------------------------------

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sim_map_mem_w is
end sim_map_mem_w;

architecture sim of sim_map_mem_w is

  constant CLK_CYCLE : time := 5 ns;

  component map_mem_w
    port (
      clka : IN STD_LOGIC;
      ena : IN STD_LOGIC;
      wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
      dina : IN STD_LOGIC_VECTOR(19 DOWNTO 0);
      douta : OUT STD_LOGIC_VECTOR(19 DOWNTO 0);

      Rst  : in std_logic;
      Save : in std_logic;
      Restore : in std_logic;
      Busy : out std_logic
    );
  end component;

  signal clk     : std_logic;
  signal ena     : std_logic;
  signal wea     : std_logic_vector(0 downto 0);
  signal addra   : std_logic_vector(15 downto 0);
  signal dina    : std_logic_vector(19 downto 0);
  signal douta   : std_logic_vector(19 downto 0);

  signal rst     : std_logic;
  signal save    : std_logic;
  signal restore : std_logic;
  signal busy    : std_logic;

begin

  clk_gen_proc: process
  begin
    clk <= '1';
    wait for CLK_CYCLE/2;
    clk <= '0';
    wait for CLK_CYCLE/2;
  end process;

  rst_gen_proc: process
  begin
    rst <= '1';
    wait for CLK_CYCLE*3;
    wait until (clk'event and clk = '0');
    rst <= '0';
    wait;
  end process;

  uut: map_mem_w
    port map (
      clka    => clk,
      ena     => ena,
      wea     => wea,
      addra   => addra,
      dina    => dina,
      douta   => douta,

      Rst     => rst,
      Save    => save,
      Restore => restore,
      Busy    => busy
    );

  ena <= '1';

  process
  begin
    wea(0) <= '0';
    addra  <= (others => '0');
    dina   <= (others => '0');

    wait for CLK_CYCLE * 10;

    -- fill incremental data

    for i in 0 to 65535 loop
      wea(0) <= '1';
      addra <= conv_std_logic_vector(i, 16);
      dina  <= conv_std_logic_vector(i, 20);

      wait for CLK_CYCLE;
    end loop;

    wea(0) <= '0';
    addra  <= (others => '0');
    dina   <= (others => '0');

    wait for CLK_CYCLE;

    wait for 350 us; -- wait for save

    wait for CLK_CYCLE * 10;

    -- write dummy data

    wea(0) <= '1';
    addra <= X"0010";
    dina  <= X"AAA55";
    wait for CLK_CYCLE;
    wea(0) <= '0';
    addra  <= (others => '0');
    dina   <= (others => '0');

    wait for CLK_CYCLE;

    -- read dummy data

    addra <= X"0010";
    wait for CLK_CYCLE;
    addra <= X"0000";

    wait for 350 us; -- wait for restore

    wait for CLK_CYCLE * 10;

    -- read dummy data again

    addra <= X"0010";
    wait for CLK_CYCLE;
    addra <= X"0000";

    wait;
  end process;

  process
  begin
    save <= '0';
    restore <= '0';

    wait for CLK_CYCLE * 10;

    wait for 350 us;
    wait until (clk'event and clk = '0');

    save <= '1';
    wait for CLK_CYCLE;
    save <= '0';

    wait for 350 us; -- wait for save

    restore <= '1';
    wait for CLK_CYCLE;
    restore <= '0';

    wait;
  end process;


end sim;

-- synthesis translate_on

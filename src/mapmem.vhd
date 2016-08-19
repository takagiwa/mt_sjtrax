library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity mapmem is
  port (
    Clk      : in std_logic;
    Rst      : in std_logic;

    Clear    : in std_logic;

    Save     : in std_logic;
    Restore  : in std_logic;

    Ready    : out std_logic;

    Key      : in std_logic_vector(15 downto 0);
    Value    : in std_logic_vector(3 downto 0);
    Wr_en    : in std_logic;
    Rd_en    : in std_logic;
    Res      : out std_logic_vector(3 downto 0);
    Res_v    : out std_logic;

    Notfound : out std_logic;
    Full     : out std_logic;
    Ignore   : out std_logic -- write while find
  );
end mapmem;

architecture rtl of mapmem is

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

  signal r_clear : std_logic;

  signal r_wea   : std_logic;
  signal r_dina  : std_logic_vector(19 downto 0);
  signal s_wea   : std_logic_vector(0 downto 0);
  signal s_addra : std_logic_vector(15 downto 0);
  signal s_dina  : std_logic_vector(19 downto 0);
  signal s_douta : std_logic_vector(19 downto 0);

  signal r_find     : std_logic;
  signal r_key      : std_logic_vector(15 downto 0);
  signal r_value    : std_logic_vector(3 downto 0);
  signal r_notfound : std_logic;

  signal r_find_d1 : std_logic;
  signal r_find_d2 : std_logic;
  signal r_find_d3 : std_logic;

  signal r_notfound_d1 : std_logic;
  signal r_notfound_d2 : std_logic;
  signal r_notfound_d3 : std_logic;
  signal r_notfound_d4 : std_logic;

  signal c_r_pointer : std_logic_vector(15 downto 0);
  signal c_w_pointer : std_logic_vector(15 downto 0);

  signal r_res   : std_logic_vector(3 downto 0);
  signal r_res_v : std_logic_vector(1 downto 0);

  signal r_full : std_logic;

  signal r_ignore : std_logic;

  signal r_busy : std_logic;

  signal s_mem_busy : std_logic;

begin

  write_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Rst = '1') then
        r_clear <= '1';
        c_w_pointer <= (others => '0');
        r_wea <= '1';
        r_full <= '0';
        r_ignore <= '0';
        r_dina <= X"F0000";
      else
        if (r_clear = '1') then
          if (c_w_pointer = X"FFFF") then
            r_wea <= '0';
            c_w_pointer <= (others => '0');
            r_clear <= '0';
            r_dina <= (others => '0');
          else
            r_wea <= '1';
            c_w_pointer <= c_w_pointer + 1;
          end if;
        elsif (Clear = '1') then
          r_clear <= '1';
          r_wea <= '1';
          c_w_pointer <= (others => '0');
          r_dina <= X"F0000";
        else
          if (r_find = '0') then
            if (Wr_en = '1') then
              r_wea <= '1';
              c_w_pointer <= c_w_pointer + 1;
              r_dina <= Value & Key;
            else
              r_wea <= '0';
              r_dina <= (others => '0');
            end if;
          else
            r_wea <= '0';
            r_dina <= (others => '0');
          end if;
        end if;

        if (c_w_pointer = X"FFFF") then
          r_full <= '1';
        else
          r_full <= '0';
        end if;

        if ((r_find = '1') and (Wr_en = '1')) then
          r_ignore <= '1';
        else
          r_ignore <= '0';
        end if;

      end if; -- reset
    end if; -- clock
  end process;

  read_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Rst = '1') then
        r_find <= '0';
        r_res_v <= (others => '0');
        r_notfound <= '0';
      else
        if (r_find = '1') then
          if (c_r_pointer = X"FFFF") then
            r_find <= '0';
            r_notfound <= '1';
          elsif (r_res_v(0) = '1') then
            r_find <= '0';
          else
            c_r_pointer <= c_r_pointer + 1;
          end if;
        elsif (Rd_en = '1') then
          r_find <= '1';
          c_r_pointer <= (others => '0');
          r_key <= Key;
          r_value <= Value;
          r_res_v(0) <= '0';
          r_notfound <= '0';
        end if;


        -- delay 1
        r_find_d1 <= r_find;
        r_notfound_d1 <= r_notfound;
        -- delay 2
        r_find_d2 <= r_find_d1;
        r_notfound_d2 <= r_notfound_d1;
        -- delay 3
        r_find_d3 <= r_find_d2;
        r_notfound_d3 <= r_notfound_d2;


        if ((r_notfound_d2 = '0') and (r_notfound_d1 = '1')) then
          r_res(3 downto 0) <= (others => '0');
          r_res_v(0) <= '1';
        elsif (r_find_d3 = '1') then
          if (s_douta(15 downto 0) = r_key(15 downto 0)) then
            r_res(3 downto 0) <= s_douta(19 downto 16);
            r_res_v(0) <= '1';
          else
            r_res_v(0) <= '0';
          end if;
        else
          r_res_v(0) <= '0';
        end if;

        r_res_v(1) <= r_res_v(0);
      end if;
    end if;
  end process;

  busy_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Rst = '1') then
        r_busy <= '0';
      else
        if (r_res_v(0) = '1') then
          r_busy <= '0';
        elsif (Rd_en = '1') then
          r_busy <= '1';
        end if;
      end if;
    end if;
  end process;

  s_wea(0) <= r_wea;
  s_addra  <= c_w_pointer when (r_wea = '1')
         else c_r_pointer;
  s_dina   <= r_dina when (r_wea = '1')
         else X"00000";

--  i_mem: map_mem
  i_mem: map_mem_w
    port map (
      clka    => Clk,
      ena     => '1',
      wea     => s_wea,
      addra   => s_addra,
      dina    => s_dina,
      douta   => s_douta,

      Rst     => Rst,
      Save    => Save,
      Restore => Restore,
      Busy    => s_mem_busy
    );

  Ready <= (not r_clear) and (not r_busy) and (not s_mem_busy); -- (not r_find);

  Res   <= r_res;
  Res_v <= r_res_v(0) and (not r_res_v(1));

  Notfound <= (not r_notfound_d3) and r_notfound_d2;
  Full <= r_full;
  Ignore <= r_ignore;

end rtl;

------------------------------------------------------------------------------

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sim_mapmem is
end sim_mapmem;

architecture sim of sim_mapmem is

  constant CLK_CYCLE : time := 5 ns;

  component mapmem
    port (
      Clk      : in std_logic;
      Rst      : in std_logic;

      Clear    : in std_logic;

      Save     : in std_logic;
      Restore  : in std_logic;

      Ready    : out std_logic;

      Key      : in std_logic_vector(15 downto 0);
      Value    : in std_logic_vector(3 downto 0);
      Wr_en    : in std_logic;
      Rd_en    : in std_logic;
      Res      : out std_logic_vector(3 downto 0);
      Res_v    : out std_logic;

      Notfound : out std_logic;
      Full     : out std_logic;
      Ignore   : out std_logic -- write while find
    );
  end component;

  signal clk      : std_logic;
  signal rst      : std_logic;
  signal clear    : std_logic;
  signal ready    : std_logic;
  signal key      : std_logic_vector(15 downto 0);
  signal value    : std_logic_vector(3 downto 0);
  signal wr_en    : std_logic;
  signal rd_en    : std_logic;
  signal res      : std_logic_vector(3 downto 0);
  signal res_v    : std_logic;
  signal notfound : std_logic;
  signal full     : std_logic;
  signal ignore   : std_logic;

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

  uut: mapmem
    port map (
      Clk      => clk,
      Rst      => rst,
      Clear    => clear,
      Save     => '0',
      Restore  => '0',
      Ready    => ready,
      Key      => key,
      Value    => value,
      Wr_en    => wr_en,
      Rd_en    => rd_en,
      Res      => res,
      Res_v    => res_v,
      Notfound => notfound,
      Full     => full,
      Ignore   => ignore
    );

  process
  begin
    clear <= '0';
    key <= X"0000";
    value <= X"0";
    wr_en <= '0';
    rd_en <= '0';

    wait for CLK_CYCLE * 10;
    wait until (ready = '1');

    key   <= X"0000";
    value <= X"0";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"0001";
    value <= X"1";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"0002";
    value <= X"2";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"0003";
    value <= X"3";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"0004";
    value <= X"4";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"0005";
    value <= X"5";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"0006";
    value <= X"6";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"0007";
    value <= X"7";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"0008";
    value <= X"8";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"0009";
    value <= X"9";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"000A";
    value <= X"A";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"000B";
    value <= X"B";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"000C";
    value <= X"C";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"000D";
    value <= X"D";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"000E";
    value <= X"E";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"000F";
    value <= X"F";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"0010";
    value <= X"9";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"0000";
    value <= X"0";
    wr_en <= '0';



    wait for CLK_CYCLE * 10;

    -- read

    key   <= X"0000";
    rd_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"0000";
    rd_en <= '0';

    wait for CLK_CYCLE * 10;

    -- read

    key   <= X"0001";
    rd_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"0000";
    rd_en <= '0';

    wait for CLK_CYCLE * 10;

    -- read

    key   <= X"0010";
    rd_en <= '1';

    wait for CLK_CYCLE;

    key   <= X"0000";
    rd_en <= '0';








    wait;
  end process;


end sim;

-- synthesis translate_on

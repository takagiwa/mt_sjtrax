library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity lookup is
  port (
    Clk       : in std_logic;
    Rst       : in std_logic;

    Map_ready : in std_logic;

    X_in      : in std_logic_vector(7 downto 0);
    Y_in      : in std_logic_vector(7 downto 0);
    V_in      : in std_logic;

    V_out     : out std_logic_vector(3 downto 0);
    V_v       : out std_logic;
    V_err     : out std_logic;

    Req       : out std_logic;
    Ack       : in std_logic;
    Key       : out std_logic_vector(15 downto 0);
    Value     : out std_logic_vector(3 downto 0);
    Wr_en     : out std_logic;
    Rd_en     : out std_logic;
    Res       : in std_logic_vector(3 downto 0);
    Res_v     : in std_logic;
    Notfound  : in std_logic
  );
end lookup;

architecture rtl of lookup is

  signal r_x_in : std_logic_vector(7 downto 0);
  signal r_y_in : std_logic_vector(7 downto 0);
  signal r_v_in : std_logic;

  signal r_req : std_logic;
  signal r_ack : std_logic;

  signal r_rd_en : std_logic_vector(2 downto 0);

  signal r_res   : std_logic_vector(3 downto 0);
  signal r_res_v : std_logic;

  signal r_v_err : std_logic;

begin

  input_rproc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (V_in = '1') then
        r_x_in <= X_in;
        r_y_in <= Y_in;
      end if;
      r_v_in <= V_in;
    end if;
  end process;

  req_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Rst = '1') then
        r_req <= '0';
      else
        if ((Res_v = '1') and (r_ack = '1')) then
          r_req <= '0';
        elsif (r_v_in = '1') then
          r_req <= '1';
        end if;
      end if;

      r_ack <= Ack;

      if (Rst = '1') then
        r_rd_en <= (others => '0');
      else
        r_rd_en(2) <= (not r_rd_en(1)) and r_rd_en(0);
        r_rd_en(1 downto 0) <= r_rd_en(0) & (r_req and r_ack and Map_ready);
      end if;

    end if;
  end process;

  Req   <= r_req;
  Key   <= r_y_in & r_x_in when (r_ack = '1')
      else (others => '0');
  Value <= (others => '0');
  Wr_en <= '0';
  Rd_en <= r_rd_en(2) when (r_ack = '1')
      else '0';

  ret_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Rst = '1') then
        r_v_err <= '0';
      else
        if ((Res_v = '1') and (r_ack = '1')) then
          r_res   <= Res;
          r_v_err <= Notfound;
        end if;
      end if;
      r_res_v <= Res_v and r_ack;
    end if;
  end process;

  V_out <= r_res;
  V_v   <= r_res_v;
  V_err <= r_v_err;

end rtl;

------------------------------------------------------------------------------

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sim_lookup is
end sim_lookup;

architecture sim of sim_lookup is

  constant CLK_CYCLE : time := 5 ns;

  component lookup
    port (
      Clk       : in std_logic;
      Rst       : in std_logic;

      Map_ready : in std_logic;

      X_in      : in std_logic_vector(7 downto 0);
      Y_in      : in std_logic_vector(7 downto 0);
      V_in      : in std_logic;

      V_out     : out std_logic_vector(3 downto 0);
      V_v       : out std_logic;
      V_err     : out std_logic;

      Req       : out std_logic;
      Ack       : in std_logic;
      Key       : out std_logic_vector(15 downto 0);
      Value     : out std_logic_vector(3 downto 0);
      Wr_en     : out std_logic;
      Rd_en     : out std_logic;
      Res       : in std_logic_vector(3 downto 0);
      Res_v     : in std_logic;
      Notfound  : in std_logic
    );
  end component;

  signal clk       : std_logic;
  signal rst       : std_logic;
  signal map_ready : std_logic;
  signal x_in      : std_logic_vector(7 downto 0);
  signal y_in      : std_logic_vector(7 downto 0);
  signal v_in      : std_logic;
  signal v_out     : std_logic_vector(3 downto 0);
  signal v_v       : std_logic;
  signal v_err     : std_logic;
  signal req       : std_logic;
  signal ack       : std_logic;
  signal key       : std_logic_vector(15 downto 0);
  signal value     : std_logic_vector(3 downto 0);
  signal wr_en     : std_logic;
  signal rd_en     : std_logic;
  signal res       : std_logic_vector(3 downto 0);
  signal res_v     : std_logic;
  signal notfound  : std_logic;

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

  uut: lookup
    port map (
      Clk => clk,
      Rst => rst,
      Map_ready => map_ready,
      X_in      => x_in,
      Y_in      => y_in,
      V_in      => v_in,
      V_out     => v_out,
      V_v       => v_v,
      V_err     => v_err,
      Req       => req,
      Ack       => ack,
      Key       => key,
      Value     => value,
      Wr_en     => wr_en,
      Rd_en     => rd_en,
      Res       => res,
      Res_v     => res_v,
      Notfound  => notfound
    );

  process
  begin
    map_ready <= '0';
    x_in <= X"00";
    y_in <= X"00";
    v_in <= '0';

    ack <= '0';

    res <= X"0";
    res_v <= '0';
    notfound <= '0';

    wait for CLK_CYCLE * 10;

    -- map_ready still low

    x_in <= X"A5";
    y_in <= X"39";
    v_in <= '1';

    wait for CLK_CYCLE;

    x_in <= X"00";
    y_in <= X"00";
    v_in <= '0';

    wait for CLK_CYCLE * 10;

    map_ready <= '1';

    wait for CLK_CYCLE * 10;

    ack <= '1';

    wait until (rd_en = '1');

    wait for CLK_CYCLE * 10;

    res <= X"6";
    res_v <= '1';
    notfound <= '0';

    wait for CLK_CYCLE;

    res <= X"0";
    res_v <= '0';
    notfound <= '0';

    wait until (req = '0');

    wait for CLK_CYCLE;

    ack <= '0';




    wait;
  end process;

end sim;

-- synthesis translate_on

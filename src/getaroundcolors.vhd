library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity getaroundcolors is
  port (
    Clk             : in std_logic;
    Rst             : in std_logic;

    X_in            : in std_logic_vector(7 downto 0);
    Y_in            : in std_logic_vector(7 downto 0);
    V_in            : in std_logic;

    Lc              : out std_logic_vector(3 downto 0);
    Rc              : out std_logic_vector(3 downto 0);
    Uc              : out std_logic_vector(3 downto 0);
    Dc              : out std_logic_vector(3 downto 0);
    C_v             : out std_logic;

    Map_ready       : in std_logic;

    Req             : out std_logic_vector(2 downto 0);
    Ack             : in std_logic_vector(2 downto 0);
    Key             : out std_logic_vector(15 downto 0);
    Value           : out std_logic_vector(3 downto 0);
    Wr_en           : out std_logic;
    Rd_en           : out std_logic;
    Res             : in std_logic_vector(3 downto 0);
    Res_v           : in std_logic;
    Notfound        : in std_logic;

    Color_map_ready : in std_logic;

    Color_req       : out std_logic_vector(3 downto 0);
    Color_ack       : in std_logic_vector(3 downto 0);
    Color_key       : out std_logic_vector(15 downto 0);
    Color_value     : out std_logic_vector(3 downto 0);
    Color_wr_en     : out std_logic;
    Color_rd_en     : out std_logic;
    Color_res       : in std_logic_vector(3 downto 0);
    Color_res_v     : in std_logic;
    Color_notfound  : in std_logic
  );
end getaroundcolors;

architecture rtl of getaroundcolors is

  constant NOTE_PLUS   : std_logic_vector(3 downto 0) := X"1";
  constant NOTE_SLASH  : std_logic_vector(3 downto 0) := X"2";
  constant NOTE_BSLASH : std_logic_vector(3 downto 0) := X"3";

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

  signal s_lc_x     : std_logic_vector(7 downto 0);
  signal s_lc_y     : std_logic_vector(7 downto 0);
  signal s_lc_v_out : std_logic_vector(3 downto 0);
  signal s_lc_v_v   : std_logic;
  signal s_lc_v_err : std_logic;

  signal s_rc_x     : std_logic_vector(7 downto 0);
  signal s_rc_y     : std_logic_vector(7 downto 0);
  signal s_rc_v_out : std_logic_vector(3 downto 0);
  signal s_rc_v_v   : std_logic;
  signal s_rc_v_err : std_logic;

  signal s_rc_v_out_o : std_logic_vector(3 downto 0);

  signal s_uc_x     : std_logic_vector(7 downto 0);
  signal s_uc_y     : std_logic_vector(7 downto 0);
  signal s_uc_v_out : std_logic_vector(3 downto 0);
  signal s_uc_v_v   : std_logic;
  signal s_uc_v_err : std_logic;

  signal s_uc_v_out_o : std_logic_vector(3 downto 0);

  signal s_dc_x     : std_logic_vector(7 downto 0);
  signal s_dc_y     : std_logic_vector(7 downto 0);
  signal s_dc_v_out : std_logic_vector(3 downto 0);
  signal s_dc_v_v   : std_logic;
  signal s_dc_v_err : std_logic;

  signal s_dc_v_out_o : std_logic_vector(3 downto 0);

  signal s_lc_key   : std_logic_vector(15 downto 0);
  signal s_lc_rd_en : std_logic;
  signal s_rc_key   : std_logic_vector(15 downto 0);
  signal s_rc_rd_en : std_logic;
  signal s_uc_key   : std_logic_vector(15 downto 0);
  signal s_uc_rd_en : std_logic;
  signal s_dc_key   : std_logic_vector(15 downto 0);
  signal s_dc_rd_en : std_logic;

  signal r_key   : std_logic_vector(15 downto 0);
  signal r_rd_en : std_logic;

  signal r_lc   : std_logic_vector(3 downto 0);
  signal r_rc   : std_logic_vector(3 downto 0);
  signal r_uc   : std_logic_vector(3 downto 0);
  signal r_dc   : std_logic_vector(3 downto 0);
  signal r_xc_v : std_logic_vector(3 downto 0);
  signal r_v    : std_logic;

  component opposite_color
    port (
      c : in std_logic_vector(3 downto 0);
      o : out std_logic_vector(3 downto 0)
    );
  end component;




  signal r_x_in : std_logic_vector(7 downto 0);
  signal r_y_in : std_logic_vector(7 downto 0);
  signal r_v_in : std_logic;

  signal s_map_lookup_rc_v_out : std_logic_vector(3 downto 0);
  signal s_map_lookup_rc_v_v   : std_logic;
  signal s_map_lookup_rc_v_err : std_logic;
  signal s_map_lookup_rc_key   : std_logic_vector(15 downto 0);
  signal s_map_lookup_rc_rd_en : std_logic;

  signal r_map_lookup_rc : std_logic_vector(3 downto 0);

  signal s_map_lookup_uc_v_out : std_logic_vector(3 downto 0);
  signal s_map_lookup_uc_v_v   : std_logic;
  signal s_map_lookup_uc_v_err : std_logic;
  signal s_map_lookup_uc_key   : std_logic_vector(15 downto 0);
  signal s_map_lookup_uc_rd_en : std_logic;

  signal r_map_lookup_uc : std_logic_vector(3 downto 0);

  signal s_map_lookup_dc_v_out : std_logic_vector(3 downto 0);
  signal s_map_lookup_dc_v_v   : std_logic;
  signal s_map_lookup_dc_v_err : std_logic;
  signal s_map_lookup_dc_key   : std_logic_vector(15 downto 0);
  signal s_map_lookup_dc_rd_en : std_logic;

  signal r_map_lookup_dc : std_logic_vector(3 downto 0);

  signal r_map_stat : std_logic_vector(3 downto 0);
  signal r_map_done : std_logic_vector(2 downto 0);

  signal r_color_req : std_logic_vector(3 downto 0);

  signal s_color_lookup_lc_v_out : std_logic_vector(3 downto 0);
  signal s_color_lookup_lc_v_v   : std_logic;
  signal s_color_lookup_lc_v_err : std_logic;
  signal s_color_lookup_lc_key   : std_logic_vector(15 downto 0);
  signal s_color_lookup_lc_rd_en : std_logic;

  signal r_color_lookup_lc : std_logic_vector(3 downto 0);

  signal s_color_lookup_rc_v_out : std_logic_vector(3 downto 0);
  signal s_color_lookup_rc_v_v   : std_logic;
  signal s_color_lookup_rc_v_err : std_logic;
  signal s_color_lookup_rc_key   : std_logic_vector(15 downto 0);
  signal s_color_lookup_rc_rd_en : std_logic;

  signal r_color_lookup_rc : std_logic_vector(3 downto 0);

  signal s_color_lookup_uc_v_out : std_logic_vector(3 downto 0);
  signal s_color_lookup_uc_v_v   : std_logic;
  signal s_color_lookup_uc_v_err : std_logic;
  signal s_color_lookup_uc_key   : std_logic_vector(15 downto 0);
  signal s_color_lookup_uc_rd_en : std_logic;

  signal r_color_lookup_uc : std_logic_vector(3 downto 0);

  signal s_color_lookup_dc_v_out : std_logic_vector(3 downto 0);
  signal s_color_lookup_dc_v_v   : std_logic;
  signal s_color_lookup_dc_v_err : std_logic;
  signal s_color_lookup_dc_key   : std_logic_vector(15 downto 0);
  signal s_color_lookup_dc_rd_en : std_logic;

  signal r_color_lookup_dc : std_logic_vector(3 downto 0);

  signal r_color_stat : std_logic_vector(3 downto 0);
  signal r_color_done : std_logic_vector(2 downto 0);


  signal s_color_opposite_rc : std_logic_vector(3 downto 0);
  signal s_color_opposite_uc : std_logic_vector(3 downto 0);
  signal s_color_opposite_dc : std_logic_vector(3 downto 0);

  signal r_color_rc : std_logic_vector(3 downto 0);
  signal r_color_uc : std_logic_vector(3 downto 0);
  signal r_color_dc : std_logic_vector(3 downto 0);

  signal r_color_v : std_logic_vector(1 downto 0);

begin

  xy_reg_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (V_in = '1') then
        r_x_in <= X_in;
        r_y_in <= Y_in;
      end if;
      r_v_in <= V_in;
    end if;
  end process;

  s_lc_x <= r_x_in - 1;
  s_lc_y <= r_y_in;

  s_rc_x <= r_x_in + 1;
  s_rc_y <= r_y_in;

  s_uc_x <= r_x_in;
  s_uc_y <= r_y_in - 1;

  s_dc_x <= r_x_in;
  s_dc_y <= r_y_in + 1;

  -- access to map -----------------------------------------------------------

  -- i_lc_map_lookup -- don't need lookup map

  i_rc_map_lookup: lookup
    port map (
      Clk => Clk,
      Rst => Rst,

      Map_ready => Map_ready,

      X_in      => s_rc_x,
      Y_in      => s_rc_y,
      V_in      => r_v_in,

      V_out     => s_map_lookup_rc_v_out,
      V_v       => s_map_lookup_rc_v_v,
      V_err     => s_map_lookup_rc_v_err,

      Req       => Req(0),
      Ack       => Ack(0),
      Key       => s_map_lookup_rc_key,
      Value     => open,
      Wr_en     => open,
      Rd_en     => s_map_lookup_rc_rd_en,
      Res       => Res,
      Res_v     => Res_v,
      Notfound  => Notfound
    );

  i_uc_map_lookup: lookup
    port map (
      Clk => Clk,
      Rst => Rst,

      Map_ready => Map_ready,

      X_in      => s_uc_x,
      Y_in      => s_uc_y,
      V_in      => r_v_in,

      V_out     => s_map_lookup_uc_v_out,
      V_v       => s_map_lookup_uc_v_v,
      V_err     => s_map_lookup_uc_v_err,

      Req       => Req(1),
      Ack       => Ack(1),
      Key       => s_map_lookup_uc_key,
      Value     => open,
      Wr_en     => open,
      Rd_en     => s_map_lookup_uc_rd_en,
      Res       => Res,
      Res_v     => Res_v,
      Notfound  => Notfound
    );

  i_dc_map_lookup: lookup
    port map (
      Clk => Clk,
      Rst => Rst,

      Map_ready => Map_ready,

      X_in      => s_dc_x,
      Y_in      => s_dc_y,
      V_in      => r_v_in,

      V_out     => s_map_lookup_dc_v_out,
      V_v       => s_map_lookup_dc_v_v,
      V_err     => s_map_lookup_dc_v_err,

      Req       => Req(2),
      Ack       => Ack(2),
      Key       => s_map_lookup_dc_key,
      Value     => open,
      Wr_en     => open,
      Rd_en     => s_map_lookup_dc_rd_en,
      Res       => Res,
      Res_v     => Res_v,
      Notfound  => Notfound
    );

  Key   <= s_map_lookup_rc_key   or s_map_lookup_uc_key   or s_map_lookup_dc_key;
  Value <= (others => '0');
  Wr_en <= '0';
  Rd_en <= s_map_lookup_rc_rd_en or s_map_lookup_uc_rd_en or s_map_lookup_dc_rd_en;

  map_done_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (r_v_in = '1') then
        r_map_stat <= (others => '0');
      else
        if (s_map_lookup_rc_v_v = '1') then
          r_map_stat(1) <= '1';
        end if;
        if (s_map_lookup_uc_v_v = '1') then
          r_map_stat(2) <= '1';
        end if;
        if (s_map_lookup_dc_v_v = '1') then
          r_map_stat(3) <= '1';
        end if;
      end if;

      if (r_v_in = '1') then
        r_map_done(0) <= '0';
      elsif (r_map_stat = "1110") then
        r_map_done(0) <= '1';
      end if;
      r_map_done(1) <= r_map_done(0);
      r_map_done(2) <= (not r_map_done(1)) and r_map_done(0);
    end if;
  end process;

  map_data_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (r_v_in = '1') then
        r_map_lookup_rc <= (others => '0');
      elsif (s_map_lookup_rc_v_v = '1') then
        if (s_map_lookup_rc_v_err = '1') then
          r_map_lookup_rc <= (others => '0');
        else
          r_map_lookup_rc <= s_map_lookup_rc_v_out;
        end if;
      end if;

      if (r_v_in = '1') then
        r_map_lookup_uc <= (others => '0');
      elsif (s_map_lookup_uc_v_v = '1') then
        if (s_map_lookup_uc_v_err = '1') then
          r_map_lookup_uc <= (others => '0');
        else
          r_map_lookup_uc <= s_map_lookup_uc_v_out;
        end if;
      end if;

      if (r_v_in = '1') then
        r_map_lookup_dc <= (others => '0');
      elsif (s_map_lookup_dc_v_v = '1') then
        if (s_map_lookup_dc_v_err = '1') then
          r_map_lookup_dc <= (others => '0');
        else
          r_map_lookup_dc <= s_map_lookup_dc_v_out;
        end if;
      end if;
    end if;
  end process;

  -- access to color map -----------------------------------------------------

  color_req_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (r_v_in = '1') then
        r_color_req <= (others => '0');
      elsif (r_map_done(2) = '1') then
        r_color_req(0) <= '1';
        if (r_map_lookup_rc /= X"0") then
          r_color_req(1) <= '1';
        end if;
        if (r_map_lookup_uc /= X"0") then
          r_color_req(2) <= '1';
        end if;
        if (r_map_lookup_dc /= X"0") then
          r_color_req(3) <= '1';
        end if;
      else
        r_color_req <= (others => '0');
      end if;
    end if;
  end process;


  i_lc_color_lookup: lookup
    port map (
      Clk => Clk,
      Rst => Rst,

      Map_ready => Color_map_ready,

      X_in      => s_lc_x,
      Y_in      => s_lc_y,
      V_in      => r_color_req(0),

      V_out     => s_color_lookup_lc_v_out,
      V_v       => s_color_lookup_lc_v_v,
      V_err     => s_color_lookup_lc_v_err,

      Req       => Color_req(0),
      Ack       => Color_ack(0),
      Key       => s_color_lookup_lc_key,
      Value     => open,
      Wr_en     => open,
      Rd_en     => s_color_lookup_lc_rd_en,
      Res       => Color_res,
      Res_v     => Color_res_v,
      Notfound  => Color_notfound
    );

  i_rc_color_lookup: lookup
    port map (
      Clk => Clk,
      Rst => Rst,

      Map_ready => Color_map_ready,

      X_in      => s_rc_x,
      Y_in      => s_rc_y,
      V_in      => r_color_req(1),

      V_out     => s_color_lookup_rc_v_out,
      V_v       => s_color_lookup_rc_v_v,
      V_err     => s_color_lookup_rc_v_err,

      Req       => Color_req(1),
      Ack       => Color_ack(1),
      Key       => s_color_lookup_rc_key,
      Value     => open,
      Wr_en     => open,
      Rd_en     => s_color_lookup_rc_rd_en,
      Res       => Color_res,
      Res_v     => Color_res_v,
      Notfound  => Color_notfound
    );

  i_uc_color_lookup: lookup
    port map (
      Clk => Clk,
      Rst => Rst,

      Map_ready => Color_map_ready,

      X_in      => s_uc_x,
      Y_in      => s_uc_y,
      V_in      => r_color_req(2),

      V_out     => s_color_lookup_uc_v_out,
      V_v       => s_color_lookup_uc_v_v,
      V_err     => s_color_lookup_uc_v_err,

      Req       => Color_req(2),
      Ack       => Color_ack(2),
      Key       => s_color_lookup_uc_key,
      Value     => open,
      Wr_en     => open,
      Rd_en     => s_color_lookup_uc_rd_en,
      Res       => Color_res,
      Res_v     => Color_res_v,
      Notfound  => Color_notfound
    );

  i_dc_color_lookup: lookup
    port map (
      Clk => Clk,
      Rst => Rst,

      Map_ready => Color_map_ready,

      X_in      => s_dc_x,
      Y_in      => s_dc_y,
      V_in      => r_color_req(3),

      V_out     => s_color_lookup_dc_v_out,
      V_v       => s_color_lookup_dc_v_v,
      V_err     => s_color_lookup_dc_v_err,

      Req       => Color_req(3),
      Ack       => Color_ack(3),
      Key       => s_color_lookup_dc_key,
      Value     => open,
      Wr_en     => open,
      Rd_en     => s_color_lookup_dc_rd_en,
      Res       => Color_res,
      Res_v     => Color_res_v,
      Notfound  => Color_notfound
    );

  Color_key   <= s_color_lookup_lc_key   or s_color_lookup_rc_key   or s_color_lookup_uc_key   or s_color_lookup_dc_key;
  Color_value <= (others => '0');
  Color_wr_en <= '0';
  Color_rd_en <= s_color_lookup_lc_rd_en or s_color_lookup_rc_rd_en or s_color_lookup_uc_rd_en or s_color_lookup_dc_rd_en;

  color_done_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (r_v_in = '1') then
        r_color_stat <= (others => '0');
      else
        if (s_color_lookup_lc_v_v = '1') then
          r_color_stat(0) <= '1';
        end if;

        if (r_map_done(2) = '1') then
          if (r_map_lookup_rc = X"0") then
            r_color_stat(1) <= '1';
          end if;
        elsif (s_color_lookup_rc_v_v = '1') then
          r_color_stat(1) <= '1';
        end if;

        if (r_map_done(2) = '1') then
          if (r_map_lookup_uc = X"0") then
            r_color_stat(2) <= '1';
          end if;
        elsif (s_color_lookup_uc_v_v = '1') then
          r_color_stat(2) <= '1';
        end if;

        if (r_map_done(2) = '1') then
          if (r_map_lookup_dc = X"0") then
            r_color_stat(3) <= '1';
          end if;
        elsif (s_color_lookup_dc_v_v = '1') then
          r_color_stat(3) <= '1';
        end if;
      end if;

      if (r_v_in = '1') then
        r_color_done(0) <= '0';
      elsif (r_color_stat = "1111") then
        r_color_done(0) <= '1';
      end if;
      r_color_done(1) <= r_color_done(0);
      r_color_done(2) <= (not r_color_done(1)) and r_color_done(0);
    end if;
  end process;

  color_data_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (r_map_done(2) = '1') then
        r_color_lookup_lc <= (others => '0');
      elsif (s_color_lookup_lc_v_v = '1') then
        if (s_color_lookup_lc_v_err = '1') then
          r_color_lookup_lc <= (others => '0');
        else
          r_color_lookup_lc <= s_color_lookup_lc_v_out;
        end if;
      end if;

      if (r_map_done(2) = '1') then
        r_color_lookup_rc <= (others => '0');
      elsif (s_color_lookup_rc_v_v = '1') then
        if (s_color_lookup_rc_v_err = '1') then
          r_color_lookup_rc <= (others => '0');
        else
          r_color_lookup_rc <= s_color_lookup_rc_v_out;
        end if;
      end if;

      if (r_map_done(2) = '1') then
        r_color_lookup_uc <= (others => '0');
      elsif (s_color_lookup_uc_v_v = '1') then
        if (s_color_lookup_uc_v_err = '1') then
          r_color_lookup_uc <= (others => '0');
        else
          r_color_lookup_uc <= s_color_lookup_uc_v_out;
        end if;
      end if;

      if (r_map_done(2) = '1') then
        r_color_lookup_dc <= (others => '0');
      elsif (s_color_lookup_dc_v_v = '1') then
        if (s_color_lookup_dc_v_err = '1') then
          r_color_lookup_dc <= (others => '0');
        else
          r_color_lookup_dc <= s_color_lookup_dc_v_out;
        end if;
      end if;
    end if;
  end process;

  -- opposite colors ---------------------------------------------------------

  i_opposite_rc: opposite_color
    port map (
      c => r_color_lookup_rc,
      o => s_color_opposite_rc
    );

  i_opposite_uc: opposite_color
    port map (
      c => r_color_lookup_uc,
      o => s_color_opposite_uc
    );

  i_opposite_dc: opposite_color
    port map (
      c => r_color_lookup_dc,
      o => s_color_opposite_dc
    );

  -- output ------------------------------------------------------------------

  color_sel_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (r_map_lookup_rc = NOTE_PLUS) then
        r_color_rc <= r_color_lookup_rc;
      else
        r_color_rc <= s_color_opposite_rc;
      end if;

      if (r_map_lookup_uc = NOTE_SLASH) then
        r_color_uc <= r_color_lookup_uc;
      else
        r_color_uc <= s_color_opposite_uc;
      end if;

      if (r_map_lookup_dc = NOTE_BSLASH) then
        r_color_dc <= r_color_lookup_dc;
      else
        r_color_dc <= s_color_opposite_dc;
      end if;

      r_color_v(1 downto 0) <= r_color_v(0) & r_color_done(2);
    end if;
  end process;

  Lc  <= r_color_lookup_lc;
  Rc  <= r_color_rc;
  Uc  <= r_color_uc;
  Dc  <= r_color_dc;
  C_v <= r_color_v(1);

end rtl;

------------------------------------------------------------------------------

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity sim_getaroundcolors is
end sim_getaroundcolors;

architecture sim of sim_getaroundcolors is

  constant CLK_CYCLE : time := 5 ns;

  component getaroundcolors
    port (
      Clk             : in std_logic;
      Rst             : in std_logic;

      X_in            : in std_logic_vector(7 downto 0);
      Y_in            : in std_logic_vector(7 downto 0);
      V_in            : in std_logic;

      Lc              : out std_logic_vector(3 downto 0);
      Rc              : out std_logic_vector(3 downto 0);
      Uc              : out std_logic_vector(3 downto 0);
      Dc              : out std_logic_vector(3 downto 0);
      C_v             : out std_logic;

      Map_ready       : in std_logic;

      Req             : out std_logic_vector(2 downto 0);
      Ack             : in std_logic_vector(2 downto 0);
      Key             : out std_logic_vector(15 downto 0);
      Value           : out std_logic_vector(3 downto 0);
      Wr_en           : out std_logic;
      Rd_en           : out std_logic;
      Res             : in std_logic_vector(3 downto 0);
      Res_v           : in std_logic;
      Notfound        : in std_logic;

      Color_map_ready : in std_logic;

      Color_req       : out std_logic_vector(3 downto 0);
      Color_ack       : in std_logic_vector(3 downto 0);
      Color_key       : out std_logic_vector(15 downto 0);
      Color_value     : out std_logic_vector(3 downto 0);
      Color_wr_en     : out std_logic;
      Color_rd_en     : out std_logic;
      Color_res       : in std_logic_vector(3 downto 0);
      Color_res_v     : in std_logic;
      Color_notfound  : in std_logic
    );
  end component;

  signal clk             : std_logic;
  signal rst             : std_logic;
  signal x_in            : std_logic_vector(7 downto 0);
  signal y_in            : std_logic_vector(7 downto 0);
  signal v_in            : std_logic;
  signal lc              : std_logic_vector(3 downto 0);
  signal rc              : std_logic_vector(3 downto 0);
  signal uc              : std_logic_vector(3 downto 0);
  signal dc              : std_logic_vector(3 downto 0);
  signal c_v             : std_logic;
  signal map_ready       : std_logic;
  signal req             : std_logic_vector(2 downto 0);
  signal ack             : std_logic_vector(2 downto 0);
  signal key             : std_logic_vector(15 downto 0);
  signal value           : std_logic_vector(3 downto 0);
  signal wr_en           : std_logic;
  signal rd_en           : std_logic;
  signal res             : std_logic_vector(3 downto 0);
  signal res_v           : std_logic;
  signal notfound        : std_logic;
  signal color_map_ready : std_logic;
  signal color_req       : std_logic_vector(3 downto 0);
  signal color_ack       : std_logic_vector(3 downto 0);
  signal color_key       : std_logic_vector(15 downto 0);
  signal color_value     : std_logic_vector(3 downto 0);
  signal color_wr_en     : std_logic;
  signal color_rd_en     : std_logic;
  signal color_res       : std_logic_vector(3 downto 0);
  signal color_res_v     : std_logic;
  signal color_notfound  : std_logic;

  signal key_1 : std_logic_vector(15 downto 0);
  signal key_2 : std_logic_vector(15 downto 0);

  signal color_key_1 : std_logic_vector(15 downto 0);
  signal color_key_2 : std_logic_vector(15 downto 0);

  component mish_simple_arbiter
      generic (
          NUM_PORTS : integer := 16
      );
      port (
          Clk : in std_logic;
          Rst : in std_logic;

          Req : in std_logic_vector(NUM_PORTS-1 downto 0);
          Ack : out std_logic_vector(NUM_PORTS-1 downto 0)
      );
  end component;

  component mapmem
    port (
      Clk      : in std_logic;
      Rst      : in std_logic;

      Clear    : in std_logic;

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

  signal full   : std_logic;
  signal ignore : std_logic;

  signal color_full   : std_logic;
  signal color_ignore : std_logic;

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

  i_uut: getaroundcolors
    port map (
      Clk             => clk,
      Rst             => rst,

      X_in            => x_in,
      Y_in            => y_in,
      V_in            => v_in,

      Lc              => lc,
      Rc              => rc,
      Uc              => uc,
      Dc              => dc,
      C_v             => c_v,

      Map_ready       => map_ready,

      Req             => req,
      Ack             => ack,
      Key             => key_1,
      Value           => open,
      Wr_en           => open,
      Rd_en           => rd_en,
      Res             => res,
      Res_v           => res_v,
      Notfound        => notfound,

      Color_map_ready => color_map_ready,

      Color_req       => color_req,
      Color_ack       => color_ack,
      Color_key       => color_key_1,
      Color_value     => open,
      Color_wr_en     => open,
      Color_rd_en     => color_rd_en,
      Color_res       => color_res,
      Color_res_v     => color_res_v,
      Color_notfound  => color_notfound
    );

  i_arbiter: mish_simple_arbiter
    generic map (
      NUM_PORTS => 3
    )
    port map (
      Clk => clk,
      Rst => rst,

      Req => req,
      Ack => ack
    );

  i_mapmem: mapmem
    port map (
      Clk      => clk,
      Rst      => rst,

      Clear    => '0',

      Ready    => map_ready,

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

  i_color_arbiter: mish_simple_arbiter
    generic map (
      NUM_PORTS => 4
    )
    port map (
      Clk => clk,
      Rst => rst,

      Req => color_req,
      Ack => color_ack
    );

  i_color_mapmem: mapmem
    port map (
      Clk      => clk,
      Rst      => rst,

      Clear    => '0',

      Ready    => color_map_ready,

      Key      => color_key,
      Value    => color_value,
      Wr_en    => color_wr_en,
      Rd_en    => color_rd_en,
      Res      => color_res,
      Res_v    => color_res_v,

      Notfound => color_notfound,
      Full     => color_full,
      Ignore   => color_ignore
    );

  key <= key_1 or key_2;
  color_key <= color_key_1 or color_key_2;

  mem_init_proc: process
  begin
    key_2 <= X"0000";
    value <= X"0";
    wr_en <= '0';

    color_key_2 <= X"0000";
    color_value <= X"0";
    color_wr_en <= '0';

    wait until (map_ready = '1');
    wait until (clk'event and clk = '0');

    key_2 <= X"0000";
    value <= X"1";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key_2 <= X"0001";
    value <= X"2";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key_2 <= X"0100";
    value <= X"3";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key_2 <= X"0101";
    value <= X"1";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key_2 <= X"0102";
    value <= X"2";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key_2 <= X"0201";
    value <= X"3";
    wr_en <= '1';

    wait for CLK_CYCLE;

    key_2 <= X"0000";
    value <= X"0";
    wr_en <= '0';

    wait;
  end process;

  target_proc: process
  begin
    x_in <= X"00";
    y_in <= X"00";
    v_in <= '0';

    wait until (map_ready = '1');
    wait until (clk'event and clk = '0');
    wait for CLK_CYCLE * 10;

    x_in <= X"00";
    y_in <= X"00";
    v_in <= '1';

    wait for CLK_CYCLE;

    x_in <= X"00";
    y_in <= X"00";
    v_in <= '0';

    wait until (c_v = '1');



    wait;
  end process;


end sim;

-- synthesis translate_on

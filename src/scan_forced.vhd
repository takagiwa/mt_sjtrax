library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity scan_forced is
  port (
    Clk             : in std_logic;
    Rst             : in std_logic;

    Force_run       : in std_logic;

    M_top           : in std_logic_vector(7 downto 0);
    M_bottom        : in std_logic_vector(7 downto 0);
    M_left          : in std_logic_vector(7 downto 0);
    M_right         : in std_logic_vector(7 downto 0);

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

    Color_req       : out std_logic_vector(4 downto 0);
    Color_ack       : in std_logic_vector(4 downto 0);
    Color_key       : out std_logic_vector(15 downto 0);
    Color_value     : out std_logic_vector(3 downto 0);
    Color_wr_en     : out std_logic;
    Color_rd_en     : out std_logic;
    Color_res       : in std_logic_vector(3 downto 0);
    Color_res_v     : in std_logic;
    Color_notfound  : in std_logic;

    Force_x         : out std_logic_vector(7 downto 0);
    Force_y         : out std_logic_vector(7 downto 0);
    Force_tile      : out std_logic_vector(3 downto 0);
    Force_v         : out std_logic
  );
end scan_forced;

architecture rtl of scan_forced is

  constant NOTE_PLUS   : std_logic_vector(3 downto 0) := X"1";
  constant NOTE_SLASH  : std_logic_vector(3 downto 0) := X"2";
  constant NOTE_BSLASH : std_logic_vector(3 downto 0) := X"3";

  signal r_top    : std_logic_vector(7 downto 0);
  signal r_bottom : std_logic_vector(7 downto 0);
  signal r_right  : std_logic_vector(7 downto 0);
  signal r_left   : std_logic_vector(7 downto 0);
  signal r_run    : std_logic;

--  signal r_color_val : std_logic_vector(3 downto 0);
--  signal r_color_v   : std_logic;
--  signal r_color_err : std_logic;
--
--  signal r_around_lc : std_logic_vector(3 downto 0);
--  signal r_around_rc : std_logic_vector(3 downto 0);
--  signal r_around_uc : std_logic_vector(3 downto 0);
--  signal r_around_dc : std_logic_vector(3 downto 0);
--  signal r_around_cv : std_logic;

  signal c_x : std_logic_vector(7 downto 0);
  signal c_y : std_logic_vector(7 downto 0);

  signal r_color_v_out : std_logic;

  signal r_around_v : std_logic;

----  signal r_color_req   : std_logic;
----  signal r_color_rd_en : std_logic;
----  signal r_around_v    : std_logic;
----
----  type T_SEQ is (
----    TSEQ_INC,
----    TSEQ_AROUND_WAIT,
----    TSEQ_AROUND_REQ,
----    TSEQ_COLOR_LOOKUP_END,
----    TSEQ_COLOR_LOOKUP_WAIT,
----    TSEQ_COLOR_LOOKUP_REQ,
----    TSEQ_COLOR_ACK,
----    TSEQ_COLOR_ACK_WAIT,
----    TSEQ_COLOR_REQ,
----    TSEQ_WAIT
----  );
----  signal c_seq : T_SEQ;

  type T_SEQ is (
    TSEQ_INC,
    TSEQ_WAIT_AROUND,
    TSEQ_REQ_AROUND,
    TSEQ_CHK_COLOR_2,
    TSEQ_CHK_COLOR_1,
    TSEQ_WAIT_COLOR,
    TSEQ_REQ_COLOR,
    TSEQ_WAIT
  );
  signal c_seq : T_SEQ;

  signal r_equ_lr : std_logic;
  signal r_equ_lu : std_logic;
  signal r_equ_ld : std_logic;
  signal r_equ_ru : std_logic;
  signal r_equ_rd : std_logic;
  signal r_equ_ud : std_logic;
  signal r_nequ_ld : std_logic;
  signal r_nequ_rd : std_logic;
  signal r_nequ_ru : std_logic;
  signal r_nzero_l : std_logic;
  signal r_nzero_r : std_logic;
  signal r_nzero_u : std_logic;
  signal r_nzero_d : std_logic;

----  signal r_color_res : std_logic_vector(3 downto 0);

  signal r_forced : std_logic_vector(3 downto 0);
  signal r_forced_delay : std_logic_vector(3 downto 0);
  signal r_forced_x_d1 : std_logic_vector(7 downto 0);
  signal r_forced_x_d2 : std_logic_vector(7 downto 0);
  signal r_forced_y_d1 : std_logic_vector(7 downto 0);
  signal r_forced_y_d2 : std_logic_vector(7 downto 0);

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

  signal s_lookup_v_out : std_logic_vector(3 downto 0);
  signal s_lookup_v_v   : std_logic;
  signal s_lookup_v_err : std_logic;

  signal s_lookup_key   : std_logic_vector(15 downto 0);
  signal s_lookup_rd_en : std_logic;

  signal r_lookup_v_out : std_logic_vector(3 downto 0);
  signal r_lookup_v_v   : std_logic;

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

  signal s_getaroundcol_lc  : std_logic_vector(3 downto 0);
  signal s_getaroundcol_rc  : std_logic_vector(3 downto 0);
  signal s_getaroundcol_uc  : std_logic_vector(3 downto 0);
  signal s_getaroundcol_dc  : std_logic_vector(3 downto 0);
  signal s_getaroundcol_c_v : std_logic;

  signal s_getaroundcol_color_key   : std_logic_vector(15 downto 0);
  signal s_getaroundcol_color_rd_en : std_logic;

  signal r_getaroundcol_lc  : std_logic_vector(3 downto 0);
  signal r_getaroundcol_rc  : std_logic_vector(3 downto 0);
  signal r_getaroundcol_uc  : std_logic_vector(3 downto 0);
  signal r_getaroundcol_dc  : std_logic_vector(3 downto 0);
  signal r_getaroundcol_c_v : std_logic;



begin

  input_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then

      if (Force_run = '1') then
        r_top    <= M_top;
        r_bottom <= M_bottom;
        r_right  <= M_right;
        r_left   <= M_left;
      end if;
      r_run <= Force_run;

    end if;
  end process;


  loop_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Rst = '1') then
        c_seq <= TSEQ_WAIT;
      else

        case c_seq is
          when TSEQ_INC =>
            if (c_x = r_right) then
              if (c_y = r_bottom) then
                c_seq <= TSEQ_WAIT;
              else
                c_seq <= TSEQ_REQ_COLOR;
                c_y <= c_y + 1;
              end if;
            else
              c_seq <= TSEQ_REQ_COLOR;
              c_x <= c_x + 1;
            end if;

            r_color_v_out <= '0';
            r_around_v <= '0';

          when TSEQ_WAIT_AROUND =>
            if (r_getaroundcol_c_v = '1') then
              c_seq <= TSEQ_INC;
            end if;

            r_around_v <= '0';

          when TSEQ_REQ_AROUND =>
            c_seq <= TSEQ_WAIT_AROUND;

            r_around_v <= '1';

          when TSEQ_CHK_COLOR_2 =>
            if (r_lookup_v_out = X"0") then
              c_seq <= TSEQ_INC;
            else
              c_seq <= TSEQ_REQ_AROUND;
            end if;

          when TSEQ_CHK_COLOR_1 =>
            c_seq <= TSEQ_CHK_COLOR_2;

          when TSEQ_WAIT_COLOR =>
            if (r_lookup_v_v = '1') then
              c_seq <= TSEQ_CHK_COLOR_1;
            end if;

            r_color_v_out <= '0';
            r_around_v <= '0';

          when TSEQ_REQ_COLOR =>
            c_seq <= TSEQ_WAIT_COLOR;

            r_color_v_out <= '1';

          when TSEQ_WAIT =>
            if (r_run = '1') then
              c_seq <= TSEQ_REQ_COLOR;
            end if;

            c_x <= r_left;
            c_y <= r_top;

            r_color_v_out <= '0';
            r_around_v <= '0';

          when others =>
            c_seq <= TSEQ_WAIT;
        end case;

      end if;

    end if;
  end process;

  i_lookup: lookup
    port map (
      Clk       => Clk,
      Rst       => Rst,

      Map_ready => Map_ready,

      X_in      => c_x,
      Y_in      => c_y,
      V_in      => r_color_v_out,

      V_out     => s_lookup_v_out,
      V_v       => s_lookup_v_v,
      V_err     => s_lookup_v_err,

      Req       => Color_req(0),
      Ack       => Color_ack(0),
      Key       => s_lookup_key,
      Value     => open,
      Wr_en     => open,
      Rd_en     => s_lookup_rd_en,
      Res       => Color_res,
      Res_v     => Color_res_v,
      Notfound  => Color_notfound
    );

  lookup_hold_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (r_color_v_out = '1') then
        r_lookup_v_out <= (others => '0');
      elsif (s_lookup_v_v = '1') then
        if (s_lookup_v_err = '1') then
          r_lookup_v_out <= (others => '0');
        else
          r_lookup_v_out <= s_lookup_v_out;
        end if;
      end if;
      r_lookup_v_v <= s_lookup_v_v;
    end if;
  end process;


  i_getaroundcolors: getaroundcolors
    port map (
      Clk             => Clk,
      Rst             => Rst,

      X_in            => c_x,
      Y_in            => c_y,
      V_in            => r_around_v,

      Lc              => s_getaroundcol_lc,
      Rc              => s_getaroundcol_rc,
      Uc              => s_getaroundcol_uc,
      Dc              => s_getaroundcol_dc,
      C_v             => s_getaroundcol_c_v,

      Map_ready       => Map_ready,

      Req             => Req,
      Ack             => Ack,
      Key             => Key,
      Value           => open,
      Wr_en           => open,
      Rd_en           => Rd_en,
      Res             => Res,
      Res_v           => Res_v,
      Notfound        => Notfound,

      Color_map_ready => Color_map_ready,

      Color_req       => Color_req(4 downto 1),
      Color_ack       => Color_ack(4 downto 1),
      Color_key       => s_getaroundcol_color_key,
      Color_value     => open,
      Color_wr_en     => open,
      Color_rd_en     => s_getaroundcol_color_rd_en,
      Color_res       => Color_res,
      Color_res_v     => Color_res_v,
      Color_notfound  => Color_notfound
    );

  Value <= (others => '0');
  Wr_en <= '0';

  Color_key   <= s_lookup_key   or s_getaroundcol_color_key;
  Color_value <= (others => '0');
  Color_wr_en <= '0';
  Color_rd_en <= s_lookup_rd_en or s_getaroundcol_color_rd_en;

  getaroundcol_hold_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (r_around_v = '1') then
        r_getaroundcol_lc <= (others => '0');
        r_getaroundcol_rc <= (others => '0');
        r_getaroundcol_uc <= (others => '0');
        r_getaroundcol_dc <= (others => '0');
      elsif (s_getaroundcol_c_v = '1') then
        r_getaroundcol_lc <= s_getaroundcol_lc;
        r_getaroundcol_rc <= s_getaroundcol_rc;
        r_getaroundcol_uc <= s_getaroundcol_uc;
        r_getaroundcol_dc <= s_getaroundcol_dc;
      end if;
      r_getaroundcol_c_v <= s_getaroundcol_c_v;
    end if;
  end process;


  around_color_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then

      r_forced_delay(0) <= r_getaroundcol_c_v;
      if (r_around_v = '1') then
        r_forced_x_d1 <= c_x;
        r_forced_y_d1 <= c_y;
      end if;

      if (r_getaroundcol_lc = r_getaroundcol_rc) then
        r_equ_lr <= '1';
      else
        r_equ_lr <= '0';
      end if;
      if (r_getaroundcol_lc = r_getaroundcol_uc) then
        r_equ_lu <= '1';
      else
        r_equ_lu <= '0';
      end if;
      if (r_getaroundcol_lc = r_getaroundcol_dc) then
        r_equ_ld <= '1';
        r_nequ_ld <= '0';
      else
        r_equ_ld <= '0';
        r_nequ_ld <= '1';
      end if;
      if (r_getaroundcol_rc = r_getaroundcol_uc) then
        r_equ_ru <= '1';
        r_nequ_ru <= '0';
      else
        r_equ_ru <= '0';
        r_nequ_ru <= '1';
      end if;
      if (r_getaroundcol_rc = r_getaroundcol_dc) then
        r_equ_rd <= '1';
        r_nequ_rd <= '0';
      else
        r_equ_rd <= '0';
        r_nequ_rd <= '1';
      end if;
      if (r_getaroundcol_uc = r_getaroundcol_dc) then
        r_equ_ud <= '1';
      else
        r_equ_ud <= '0';
      end if;
      if (r_getaroundcol_lc /= X"0") then
        r_nzero_l <= '1';
      else
        r_nzero_l <= '0';
      end if;
      if (r_getaroundcol_rc /= X"0") then
        r_nzero_r <= '1';
      else
        r_nzero_r <= '0';
      end if;
      if (r_getaroundcol_uc /= X"0") then
        r_nzero_u <= '1';
      else
        r_nzero_u <= '0';
      end if;
      if (r_getaroundcol_dc /= X"0") then
        r_nzero_d <= '1';
      else
        r_nzero_d <= '0';
      end if;

      r_forced_delay(1) <= r_forced_delay(0);
      r_forced_x_d2 <= r_forced_x_d1;
      r_forced_y_d2 <= r_forced_y_d1;

      if ( ((r_equ_lu = '1') and (r_nzero_u = '1')) or ((r_equ_rd = '1') and (r_nzero_r = '1')) ) then
        r_forced <= NOTE_SLASH;
      elsif ( ((r_equ_ru = '1') and (r_nzero_u = '1')) or ((r_equ_ld = '1') and (r_nzero_l = '1')) ) then
        r_forced <= NOTE_BSLASH;
      elsif ( ((r_equ_lr = '1') and (r_nzero_r = '1') and (r_nequ_rd = '1') and (r_nequ_ru = '1')) or ((r_equ_ud = '1') and (r_nzero_d = '1') and (r_nequ_ld = '1')) ) then
        r_forced <= NOTE_PLUS;
      else
        r_forced <= X"0";
      end if;

    end if;
  end process;


  Force_x    <= r_forced_x_d2;
  Force_y    <= r_forced_y_d2;
  Force_tile <= r_forced;
  Force_v    <= r_forced_delay(1);

end rtl;

------------------------------------------------------------------------------

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity sim_scan_forced is
end sim_scan_forced;

architecture sim of sim_scan_forced is

  constant CLK_CYCLE : time := 5 ns;

  constant NOTE_PLUS   : std_logic_vector(3 downto 0) := X"1";
  constant NOTE_SLASH  : std_logic_vector(3 downto 0) := X"2";
  constant NOTE_BSLASH : std_logic_vector(3 downto 0) := X"3";

  component scan_forced
    port (
      Clk            : in std_logic;
      Rst            : in std_logic;

      Force_run      : in std_logic;

      M_top          : in std_logic_vector(7 downto 0);
      M_bottom       : in std_logic_vector(7 downto 0);
      M_left         : in std_logic_vector(7 downto 0);
      M_right        : in std_logic_vector(7 downto 0);

      Map_ready      : in std_logic;

      Req            : out std_logic_vector(2 downto 0);
      Ack            : in std_logic_vector(2 downto 0);
      Key            : out std_logic_vector(15 downto 0);
      Value          : out std_logic_vector(3 downto 0);
      Wr_en          : out std_logic;
      Rd_en          : out std_logic;
      Res            : in std_logic_vector(3 downto 0);
      Res_v          : in std_logic;
      Notfound       : in std_logic;

      Color_map_ready      : in std_logic;

      Color_req            : out std_logic_vector(4 downto 0);
      Color_ack            : in std_logic_vector(4 downto 0);
      Color_key            : out std_logic_vector(15 downto 0);
      Color_value          : out std_logic_vector(3 downto 0);
      Color_wr_en          : out std_logic;
      Color_rd_en          : out std_logic;
      Color_res            : in std_logic_vector(3 downto 0);
      Color_res_v          : in std_logic;
      Color_notfound       : in std_logic;

      Force_x        : out std_logic_vector(7 downto 0);
      Force_y        : out std_logic_vector(7 downto 0);
      Force_tile     : out std_logic_vector(3 downto 0);
      Force_v        : out std_logic
    );
  end component;

  signal clk             : std_logic;
  signal rst             : std_logic;
  signal force_run       : std_logic;
  signal m_top           : std_logic_vector(7 downto 0);
  signal m_bottom        : std_logic_vector(7 downto 0);
  signal m_left          : std_logic_vector(7 downto 0);
  signal m_right         : std_logic_vector(7 downto 0);
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
  signal color_req       : std_logic_vector(4 downto 0);
  signal color_ack       : std_logic_vector(4 downto 0);
  signal color_key       : std_logic_vector(15 downto 0);
  signal color_value     : std_logic_vector(3 downto 0);
  signal color_wr_en     : std_logic;
  signal color_rd_en     : std_logic;
  signal color_res       : std_logic_vector(3 downto 0);
  signal color_res_v     : std_logic;
  signal color_notfound  : std_logic;
  signal force_x         : std_logic_vector(7 downto 0);
  signal force_y         : std_logic_vector(7 downto 0);
  signal force_tile      : std_logic_vectoR(3 downto 0);
  signal force_v         : std_logic;


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

  signal s_map_key       : std_logic_vector(15 downto 0);
  signal s_color_map_key : std_logic_vector(15 downto 0);

  signal manual_key       : std_logic_vector(15 downto 0);
  signal manual_color_key : std_logic_vector(15 downto 0);

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


  i_map_arbiter: mish_simple_arbiter
    generic map (
      NUM_PORTS => 3
    )
    port map (
      Clk => clk,
      Rst => rst,

      Req => req,
      Ack => ack
    );

  i_map: mapmem
    port map (
      Clk      => clk,
      Rst      => rst,

      Clear    => '0',

      Save     => '0',
      Restore  => '0',

      Ready    => map_ready,

      Key      => s_map_key,
      Value    => value,
      Wr_en    => wr_en,
      Rd_en    => rd_en,
      Res      => res,
      Res_v    => res_v,

      Notfound => notfound,
      Full     => open,
      Ignore   => open
    );

  s_map_key <= key or manual_key;

  i_color_map_arbiter: mish_simple_arbiter
    generic map (
      NUM_PORTS => 5
    )
    port map (
      Clk => clk,
      Rst => rst,

      Req => color_req,
      Ack => color_ack
    );

  i_color_map: mapmem
    port map (
      Clk      => clk,
      Rst      => rst,

      Clear    => '0',

      Save     => '0',
      Restore  => '0',

      Ready    => color_map_ready,

      Key      => s_color_map_key,
      Value    => color_value,
      Wr_en    => color_wr_en,
      Rd_en    => color_rd_en,
      Res      => color_res,
      Res_v    => color_res_v,

      Notfound => color_notfound,
      Full     => open,
      Ignore   => open
    );

  s_color_map_key <= color_key or manual_color_key;


  uut: scan_forced
    port map (
      Clk             => clk,
      Rst             => rst,

      Force_run       => force_run,

      M_top           => m_top,
      M_bottom        => m_bottom,
      M_left          => m_left,
      M_right         => m_right,

      Map_ready       => map_ready,

      Req             => req,
      Ack             => ack,
      Key             => key,
      Value           => open,
      Wr_en           => open,
      Rd_en           => rd_en,
      Res             => res,
      Res_v           => res_v,
      Notfound        => notfound,

      Color_map_ready => color_map_ready,

      Color_req       => color_req,
      Color_ack       => color_ack,
      Color_key       => color_key,
      Color_value     => open,
      Color_wr_en     => open,
      Color_rd_en     => color_rd_en,
      Color_res       => color_res,
      Color_res_v     => color_res_v,
      Color_notfound  => color_notfound,

      Force_x         => force_x,
      Force_y         => force_y,
      Force_tile      => force_tile,
      Force_v         => force_v
    );


  m_top    <= X"FF";
  m_bottom <= X"00";
  m_left   <= X"FF";
  m_right  <= X"03";

  process
  begin
    force_run <= '0';
    manual_key <= X"0000";
    value      <= X"0";
    wr_en      <= '0';
    manual_color_key <= X"0000";
    color_value      <= X"0";
    color_wr_en      <= '0';

    wait until (map_ready = '1');
    wait until (clk'event and clk = '0');
    wait for CLK_CYCLE * 10;

    -- turn 1: 0, 0, \

    manual_key <= X"0000";
    value      <= NOTE_BSLASH;
    wr_en      <= '1';
    manual_color_key <= X"0000";
    color_value      <= X"1";
    color_wr_en      <= '1';

    wait for CLK_CYCLE;

    -- turn 2: -1, 0, +

    manual_key <= X"00FF";
    value  <= NOTE_PLUS;
    wr_en  <= '1';
    manual_color_key <= X"00FF";
    color_value      <= X"2";
    color_wr_en      <= '1';

    wait for CLK_CYCLE;

    -- turn 3: 1, 0, /

    manual_key <= X"0001";
    value  <= NOTE_SLASH;
    wr_en  <= '1';
    manual_color_key <= X"0001";
    color_value      <= X"1";
    color_wr_en      <= '1';

    wait for CLK_CYCLE;

    -- turn 4: 2, 0, +

    manual_key <= X"0002";
    value  <= NOTE_PLUS;
    wr_en  <= '1';
    manual_color_key <= X"0002";
    color_value      <= X"2";
    color_wr_en      <= '1';

    wait for CLK_CYCLE;

    -- turn 5: 3, 0, /

    manual_key <= X"0003";
    value  <= NOTE_SLASH;
    wr_en  <= '1';
    manual_color_key <= X"0003";
    color_value      <= X"1";
    color_wr_en      <= '1';


    wait for CLK_CYCLE;

    -- turn 6: -1, -1, +

    manual_key <= X"FFFF";
    value  <= NOTE_SLASH;
    wr_en  <= '1';
    manual_color_key <= X"FFFF";
    color_value      <= X"2";
    color_wr_en      <= '1';


    wait for CLK_CYCLE;

    -- turn 7: 0, -1, \

    manual_key <= X"FF00";
    value  <= NOTE_BSLASH;
    wr_en  <= '1';
    manual_color_key <= X"FF00";
    color_value      <= X"1";
    color_wr_en      <= '1';

    wait for CLK_CYCLE;

    manual_key <= X"0000";
    value  <= X"0";
    wr_en  <= '0';
    manual_color_key <= X"0000";
    color_value      <= X"0";
    color_wr_en      <= '0';

    wait for CLK_CYCLE * 10;

    force_run <= '1';

    wait for CLK_CYCLE;

    force_run <= '0';

    wait;
  end process;



end sim;


-- synthesis translate_on

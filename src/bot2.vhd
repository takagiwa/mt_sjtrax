library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity bot2 is
  generic (
    PLAYER_ID : std_logic_vector(15 downto 0) := X"AA"
  );
  port (
    Clk        : in std_logic;
    Rst        : in std_logic;

    Dash_T     : in std_logic;
    Dash_W     : in std_logic;
    Dash_B     : in std_logic;
    Dash_Error : in std_logic;

    Pid        : out std_logic_vector(15 downto 0);
    Pid_v      : out std_logic;

    Note_rx_x  : in std_logic_vector(31 downto 0);
    Note_rx_y  : in std_logic_vector(31 downto 0);
    Note_rx_t  : in std_logic_vector(7 downto 0);
    Note_rx_v  : in std_logic;

    Note_tx_x  : out std_logic_vector(31 downto 0);
    Note_tx_y  : out std_logic_vector(31 downto 0);
    Note_tx_t  : out std_logic_vector(7 downto 0);
    Note_tx_v  : out std_logic;

    Got_init   : out std_logic;
    Im_first   : out std_logic;
    Init_done  : out std_logic;

    Trying     : out std_logic
  );
end bot2;

architecture rtl of bot2 is

  constant ASCII_AT     : std_logic_vector(7 downto 0) := X"40"; -- @
  constant ASCII_0      : std_logic_vector(7 downto 0) := X"30";
  constant ASCII_9      : std_logic_vector(7 downto 0) := X"39";
  constant ASCII_A      : std_logic_vector(7 downto 0) := X"41";
  constant ASCII_B      : std_logic_vector(7 downto 0) := X"42";
  constant ASCII_T      : std_logic_vector(7 downto 0) := X"54";
  constant ASCII_W      : std_logic_vector(7 downto 0) := X"57";
  constant ASCII_Z      : std_logic_vector(7 downto 0) := X"5A";
  constant ASCII_LF     : std_logic_vector(7 downto 0) := X"0A";
  constant ASCII_PLUS   : std_logic_vector(7 downto 0) := X"2B"; -- +
  constant ASCII_SLASH  : std_logic_vector(7 downto 0) := X"2F"; -- /
  constant ASCII_BSLASH : std_logic_vector(7 downto 0) := X"5C"; -- \
  constant ASCII_DASH   : std_logic_vector(7 downto 0) := X"2D"; -- -

  constant NOTE_PLUS   : std_logic_vector(3 downto 0) := X"1";
  constant NOTE_SLASH  : std_logic_vector(3 downto 0) := X"2";
  constant NOTE_BSLASH : std_logic_vector(3 downto 0) := X"3";

  signal r_note_tx_x : std_logic_vector(31 downto 0);
  signal r_note_tx_y : std_logic_vector(31 downto 0);
  signal r_note_tx_t : std_logic_vector(7 downto 0);
  signal r_note_tx_v : std_logic;

  signal r_first_note_x : std_logic_vector(31 downto 0);
  signal r_first_note_y : std_logic_vector(31 downto 0);
  signal r_first_note_t : std_logic_vector(7 downto 0);
  signal r_first_note_v : std_logic;

  signal r_got_init : std_logic;
  signal r_im_first : std_logic;
  signal r_init_done : std_logic;

  signal c_id_delay : std_logic_vector(4 downto 0);
  signal r_pid_v    : std_logic;




  signal turn : integer;

  signal t_left       : integer;
  signal t_right      : integer;
  signal t_top        : integer;
  signal t_bottom     : integer;
  signal t_red_loop   : boolean;
  signal t_red_line   : boolean;
  signal t_white_loop : boolean;
  signal t_white_line : boolean;
-- t_board
-- t_board_color
-- t_board_marks



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

  signal s_map_board_clear    : std_logic;
  signal s_map_board_ready    : std_logic;
  signal s_map_board_key      : std_logic_vector(15 downto 0);
  signal s_map_board_value    : std_logic_vector(3 downto 0);
  signal s_map_board_wr_en    : std_logic;
  signal s_map_board_rd_en    : std_logic;
  signal s_map_board_res      : std_logic_vector(3 downto 0);
  signal s_map_board_res_v    : std_logic;
  signal s_map_board_notfound : std_logic;
  signal s_map_board_full     : std_logic;
  signal s_map_board_ignore   : std_logic;

  signal s_map_board_color_clear    : std_logic;
  signal s_map_board_color_ready    : std_logic;
  signal s_map_board_color_key      : std_logic_vector(15 downto 0);
  signal s_map_board_color_value    : std_logic_vector(3 downto 0);
  signal s_map_board_color_wr_en    : std_logic;
  signal s_map_board_color_rd_en    : std_logic;
  signal s_map_board_color_res      : std_logic_vector(3 downto 0);
  signal s_map_board_color_res_v    : std_logic;
  signal s_map_board_color_notfound : std_logic;
  signal s_map_board_color_full     : std_logic;
  signal s_map_board_color_ignore   : std_logic;

  signal s_map_board_marks_clear    : std_logic;
  signal s_map_board_marks_ready    : std_logic;
  signal s_map_board_marks_key      : std_logic_vector(15 downto 0);
  signal s_map_board_marks_value    : std_logic_vector(3 downto 0);
  signal s_map_board_marks_wr_en    : std_logic;
  signal s_map_board_marks_rd_en    : std_logic;
  signal s_map_board_marks_res      : std_logic_vector(3 downto 0);
  signal s_map_board_marks_res_v    : std_logic;
  signal s_map_board_marks_notfound : std_logic;
  signal s_map_board_marks_full     : std_logic;
  signal s_map_board_marks_ignore   : std_logic;

  signal c_turn : std_logic_vector(31 downto 0);

  signal c_board_left   : std_logic_vector(7 downto 0);
  signal c_board_right  : std_logic_vector(7 downto 0);
  signal c_board_top    : std_logic_vector(7 downto 0);
  signal c_board_bottom : std_logic_vector(7 downto 0);

  signal r_shadow_turn : std_logic_vector(31 downto 0);



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

  component is_isolated
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
  end component;

  signal r_error_invalid_first_turn : std_logic;

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

  signal s_lookup_occupied_v_out : std_logic_vector(3 downto 0);
  signal s_lookup_occupied_v_v   : std_logic;
  signal s_lookup_occupied_v_err : std_logic;

  signal s_lookup_occupied_key   : std_logic_vector(15 downto 0);
  signal s_lookup_occupied_rd_en : std_logic;

  signal r_chk_occupied_flag        : std_logic;
  signal r_error_occupied_placement : std_logic;

  signal r_place_mark_key   : std_logic_vector(15 downto 0);
  signal r_place_mark_value : std_logic_vector(3 downto 0);
  signal r_place_mark_wr_en : std_logic;

  signal r_color : std_logic_vector(3 downto 0);

  signal r_place_tile_key   : std_logic_vector(15 downto 0);
  signal r_place_tile_value : std_logic_vector(3 downto 0);
  signal r_place_tile_wr_en : std_logic;

  signal s_place_getaround_req         : std_logic_vector(2 downto 0);
  signal s_place_getaround_ack         : std_logic_vectoR(3 downto 0);
  signal s_place_geraround_key         : std_logic_vector(15 downto 0);
  signal s_place_getaround_rd_en       : std_logic;
  signal s_place_getaround_color_req   : std_logic_vector(3 downto 0);
  signal s_place_getaround_color_ack   : std_logic_vector(3 downto 0);
  signal s_place_getaround_color_key   : std_logic_vector(15 downto 0);
  signal s_place_getaround_color_rd_en : std_logic;
  signal s_place_getaround_lc          : std_logic_vector(3 downto 0);
  signal s_place_getaround_rc          : std_logic_vector(3 downto 0);
  signal s_place_getaround_uc          : std_logic_vector(3 downto 0);
  signal s_place_getaround_dc          : std_logic_vector(3 downto 0);
  signal s_place_getaround_c_v         : std_logic;

  signal s_error_is_isolated : std_logic;

  signal s_isolated_color : std_logic_vector(3 downto 0);

  component is_prohibited_3
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
  end component;

  signal s_error_is_prohibited_3 : std_logic;

  component is_consistent_placement
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
  end component;

  signal s_error_is_consistent_placement : std_logic;

  component color_the_tile
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
  end component;

  signal s_colored_tile   : std_logic_vector(3 downto 0);
  signal s_colored_tile_v : std_logic;

  signal r_colored_tile_key   : std_logic_vector(15 downto 0);
  signal r_colored_tile_value : std_logic_vector(3 downto 0);
  signal r_colored_tile_wr_en : std_logic;

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

  signal s_map_req : std_logic_vector(3 downto 0);
  signal s_map_ack : std_logic_vector(3 downto 0);

  signal s_map_color_req : std_logic_vector(3 downto 0);
  signal s_map_color_ack : std_logic_vector(3 downto 0);

--  signal s_map_mark_req : std_logic_vector();
--  signal s_map_mark_ack : std_logic_vector();

  signal r_color_delay_v : std_logic_vector(1 downto 0);

  signal r_note_rx_x : std_logic_vector(31 downto 0);
  signal r_note_rx_y : std_logic_vector(31 downto 0);
  signal r_note_rx_t : std_logic_vector(7 downto 0);
  signal r_note_rx_v : std_logic;

  signal s_write_mark : std_logic;

  signal r_isolated_chk : std_logic_vector(2 downto 0);

  signal r_consistent_chk : std_logic_vector(2 downto 0);

  signal r_done : std_logic_vector(8 downto 0);



  component rnd_note_gen
    port (
      Clk       : in std_logic;
      Rst       : in std_logic;

      Dash_T    : in std_logic;

      Save      : out std_logic;
      Restore   : out std_logic;
      Mem_ready : in std_logic_vector(2 downto 0);

      M_left    : in std_logic_vector(7 downto 0);
      M_right   : in std_logic_vector(7 downto 0);
      M_top     : in std_logic_vector(7 downto 0);
      M_bottom  : in std_logic_vector(7 downto 0);

      Done      : in std_logic;
      Errors    : in std_logic_vector(3 downto 0);

      Note_x    : out std_logic_vector(31 downto 0);
      Note_y    : out std_logic_vector(31 downto 0);
      Note_t    : out std_logic_vector(7 downto 0);
      Note_v    : out std_logic;

      Send      : out std_logic
    );
  end component;

  signal s_notegen_save      : std_logic;
  signal s_notegen_restore   : std_logic;
  signal s_notegen_mem_ready : std_logic_vector(2 downto 0);
  signal s_notegen_m_left    : std_logic_vector(7 downto 0);
  signal s_notegen_m_right   : std_logic_vector(7 downto 0);
  signal s_notegen_m_top     : std_logic_vector(7 downto 0);
  signal s_notegen_m_bottom  : std_logic_vector(7 downto 0);
  signal s_notegen_done      : std_logic;
  signal s_notegen_errors    : std_logic_vector(3 downto 0);
  signal s_notegen_note_x    : std_logic_vector(31 downto 0);
  signal s_notegen_note_y    : std_logic_vector(31 downto 0);
  signal s_notegen_note_t    : std_logic_vector(7 downto 0);
  signal s_notegen_note_v    : std_logic;
  signal s_notegen_send      : std_logic;

  signal r_note_x : std_logic_vector(31 downto 0);
  signal r_note_y : std_logic_vector(31 downto 0);
  signal r_note_t : std_logic_vector(7 downto 0);
  signal r_note_v : std_logic;



component board_area
  port (
    Clk          : in std_logic;

    Dash_T       : in std_logic;

    -- received
    Note_rx_x    : in std_logic_vector(7 downto 0);
    Note_rx_y    : in std_logic_vector(7 downto 0);
    Note_rx_v    : in std_logic;

    -- generated
    Note_x       : in std_logic_vector(7 downto 0);
    Note_y       : in std_logic_vector(7 downto 0);
    Note_v       : in std_logic;
    Restore      : in std_logic;
    Save         : in std_logic;

    -- output
    Board_top    : out std_logic_vector(7 downto 0);
    Board_bottom : out std_logic_vector(7 downto 0);
    Board_left   : out std_logic_vector(7 downto 0);
    Board_right  : out std_logic_vector(7 downto 0)
  );
end component;



begin ------------------------------------------------------------------------

  process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Rst = '1') then
        c_id_delay <= (others => '0');
      elsif (Dash_T = '1') then
        c_id_delay <= "00001";
      elsif ((c_id_delay /= "00000") and (c_id_delay /= "01111")) then
        c_id_delay <= c_id_delay + 1;
      end if;
      if (Rst = '1') then
        r_pid_v <= '0';
      elsif (c_id_delay = "01110") then
        r_pid_v <= '1';
      else
        r_pid_v <= '0';
      end if;
    end if;
  end process;

  Pid   <= PLAYER_ID;
  Pid_v <= r_pid_v;

  my_first_note_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Dash_W = '1') then
        r_first_note_x <= conv_std_logic_vector(0, 32);
        r_first_note_y <= conv_std_logic_vector(0, 32);
        r_first_note_t <= X"0" & NOTE_PLUS;
        r_first_note_v <= '1';
      else
        r_first_note_x <= conv_std_logic_vector(0, 32);
        r_first_note_y <= conv_std_logic_vector(0, 32);
        r_first_note_t <= conv_std_logic_vector(0, 8);
        r_first_note_v <= '0';
      end if;
    end if;
  end process;



  output_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (r_first_note_v = '1') then
        r_note_tx_x <= r_first_note_x;
        r_note_tx_y <= r_first_note_y;
        r_note_tx_t <= r_first_note_t;
        r_note_tx_v <= '1';
      elsif (s_notegen_send = '1') then
        r_note_tx_x <= s_notegen_note_x;
        r_note_tx_y <= s_notegen_note_y;
        r_note_tx_t <= s_notegen_note_t;
        r_note_tx_v <= '1';
      else
        r_note_tx_x <= (others => '0');
        r_note_tx_y <= (others => '0');
        r_note_tx_t <= (others => '0');
        r_note_tx_v <= '0';
      end if;
    end if;
  end process;

  Note_tx_x <= r_note_tx_x;
  Note_tx_y <= r_note_tx_y;
  Note_tx_t <= r_note_tx_t;
  Note_tx_v <= r_note_tx_v;



  process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Rst = '1') then
        r_got_init <= '0';
        r_im_first <= '0';
        r_init_done <= '0';
      else
        if (Dash_T = '1') then
          r_got_init <= '1';
        end if;
        if (Dash_W = '1') then
          r_im_first <= '1';
          r_init_done <= '1';
        end if;
        if (Dash_B = '1') then
          r_im_first <= '0';
          r_init_done <= '1';
        end if;
      end if;
    end if;
  end process;

  Got_init <= r_got_init;
  Im_first <= r_im_first;
  Init_done <= r_init_done;



  rx_note_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Note_rx_v = '1') then
        r_note_rx_x <= Note_rx_x;
        r_note_rx_y <= Note_rx_y;
        r_note_rx_t <= Note_rx_t;
      end if;
      r_note_rx_v <= Note_rx_v;
    end if;
  end process;



  process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (r_note_rx_v = '1') then
        r_note_x <= r_note_rx_x;
        r_note_y <= r_note_rx_y;
        r_note_t <= r_note_rx_t;
      elsif (s_notegen_note_v = '1') then
        r_note_x <= s_notegen_note_x;
        r_note_y <= s_notegen_note_y;
        r_note_t <= s_notegen_note_t;
      end if;
      r_note_v <= r_note_rx_v or s_notegen_note_v;
    end if;
  end process;



  turn_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Dash_T = '1') then
        c_turn <= conv_std_logic_vector(0, 32);
      elsif (s_notegen_restore = '1') then
        c_turn <= r_shadow_turn;
      elsif (Note_rx_v = '1') then
        c_turn <= c_turn + 1;
      elsif (r_first_note_v = '1') then
        c_turn <= c_turn + 1;
      elsif (s_notegen_note_v = '1') then
        c_turn <= c_turn + 1;
      end if;

      if (s_notegen_save = '1') then
        r_shadow_turn <= c_turn;
      end if;
    end if;
  end process;



  i_board_area: board_area
    port map (
      Clk          => Clk,

      Dash_T       => Dash_T,

      Note_rx_x    => r_note_rx_x(7 downto 0),
      Note_rx_y    => r_note_rx_y(7 downto 0),
      Note_rx_v    => r_note_rx_v,

      Note_x       => s_notegen_note_x(7 downto 0),
      Note_y       => s_notegen_note_y(7 downto 0),
      Note_v       => s_notegen_note_v,
      Restore      => s_notegen_restore,
      Save         => s_notegen_save,

      Board_top    => c_board_top,
      Board_bottom => c_board_bottom,
      Board_left   => c_board_left,
      Board_right  => c_board_right
    );



  i_map_arbiter: mish_simple_arbiter
    generic map (
      NUM_PORTS => 4
    )
    port map (
      Clk => Clk,
      Rst => Rst,

      Req => s_map_req,
      Ack => s_map_ack
    );

  i_map_board: mapmem
    port map (
      Clk      => Clk,
      Rst      => Rst,

      Clear    => s_map_board_clear,

      Save     => s_notegen_save,
      Restore  => s_notegen_restore,

      Ready    => s_map_board_ready,

      Key      => s_map_board_key,
      Value    => s_map_board_value,
      Wr_en    => s_map_board_wr_en,
      Rd_en    => s_map_board_rd_en,
      Res      => s_map_board_res,
      Res_v    => s_map_board_res_v,

      Notfound => s_map_board_notfound,
      Full     => s_map_board_full,
      Ignore   => s_map_board_ignore
    );

  s_map_board_clear <= Dash_T;
  s_map_board_key   <= r_place_tile_key or s_place_geraround_key or s_lookup_occupied_key;
  s_map_board_value <= r_place_tile_value;
  s_map_board_wr_en <= r_place_tile_wr_en;
  s_map_board_rd_en <= s_place_getaround_rd_en or s_lookup_occupied_rd_en;



  i_map_color_arbiter: mish_simple_arbiter
    generic map (
      NUM_PORTS => 4
    )
    port map (
      Clk => Clk,
      Rst => Rst,

      Req => s_map_color_req,
      Ack => s_map_color_ack
    );

  i_map_board_color: mapmem
    port map (
      Clk      => Clk,
      Rst      => Rst,

      Clear    => s_map_board_color_clear,

      Save     => s_notegen_save,
      Restore  => s_notegen_restore,

      Ready    => s_map_board_color_ready,

      Key      => s_map_board_color_key,
      Value    => s_map_board_color_value,
      Wr_en    => s_map_board_color_wr_en,
      Rd_en    => s_map_board_color_rd_en,
      Res      => s_map_board_color_res,
      Res_v    => s_map_board_color_res_v,

      Notfound => s_map_board_color_notfound,
      Full     => s_map_board_color_full,
      Ignore   => s_map_board_color_ignore
    );

  s_map_board_color_clear <= Dash_T;
  s_map_board_color_key   <= s_place_getaround_color_key or r_colored_tile_key;
  s_map_board_color_value <= r_colored_tile_value;
  s_map_board_color_wr_en <= r_colored_tile_wr_en;
  s_map_board_color_rd_en <= s_place_getaround_color_rd_en;



  i_map_board_marks: mapmem
    port map (
      Clk      => Clk,
      Rst      => Rst,

      Clear    => s_map_board_marks_clear,

      Save     => s_notegen_save,
      Restore  => s_notegen_restore,

      Ready    => s_map_board_marks_ready,

      Key      => s_map_board_marks_key,
      Value    => s_map_board_marks_value,
      Wr_en    => s_map_board_marks_wr_en,
      Rd_en    => s_map_board_marks_rd_en,
      Res      => s_map_board_marks_res,
      Res_v    => s_map_board_marks_res_v,

      Notfound => s_map_board_marks_notfound,
      Full     => s_map_board_marks_full,
      Ignore   => s_map_board_marks_ignore
    );

  s_map_board_marks_clear <= Dash_T;
  s_map_board_marks_key   <= r_place_mark_key;
  s_map_board_marks_value <= r_place_mark_value;
  s_map_board_marks_wr_en <= r_place_mark_wr_en;
  s_map_board_marks_rd_en <= '0';



  -- trax.cc : trax::place(move mo, int turn) : first turn check -------------
  -- check only for anothers. my first note is fixed.
  first_turn_chk_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if ((Rst = '1') or (Dash_T = '1')) then
        r_error_invalid_first_turn <= '0';
      elsif (c_turn = conv_std_logic_vector(0, 32)) then
        if (r_note_rx_v = '1') then
          if ((r_note_rx_x /= X"00000000") or (r_note_rx_y /= X"00000000") or ( (r_note_rx_t(3 downto 0) /= NOTE_PLUS) and (r_note_rx_t(3 downto 0) /= NOTE_SLASH))) then
            r_error_invalid_first_turn <= '1';
          else
            r_error_invalid_first_turn <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;



  -- trax.cc : trax::place(move mo, int turn) : **** ALREADY OCCUPIED! **** --
  i_lookup_occupied: lookup
    port map (
      Clk       => Clk,
      Rst       => Rst,

      Map_ready => s_map_board_ready,

      X_in      => r_note_x(7 downto 0),
      Y_in      => r_note_y(7 downto 0),
      V_in      => r_note_v,

      V_out     => s_lookup_occupied_v_out,
      V_v       => s_lookup_occupied_v_v,
      V_err     => s_lookup_occupied_v_err,

      Req       => s_map_req(3),
      Ack       => s_map_ack(3),
      Key       => s_lookup_occupied_key,
      Value     => open,
      Wr_en     => open,
      Rd_en     => s_lookup_occupied_rd_en,
      Res       => s_map_board_res,
      Res_v     => s_map_board_res_v,
      Notfound  => s_map_board_notfound
    );

  chk_occupied_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if ((Rst = '1') or (Dash_T = '1')) then
        r_chk_occupied_flag <= '0';
      elsif (s_lookup_occupied_v_v = '1') then
        r_chk_occupied_flag <= '0';
      elsif (r_note_v = '1') then
        r_chk_occupied_flag <= '1';
      end if;

      if ((Rst = '1') or (Dash_T = '1')) then
        r_error_occupied_placement <= '0';
      elsif (s_lookup_occupied_v_v = '1') then
        -- found
--        if ((s_lookup_occupied_v_err /= '1') and (s_lookup_occupied_v_out /= X"F")) then
--          -- not error and not initial value = already placed
--          r_error_occupied_placement <= '1';
--        end if;

        if (s_lookup_occupied_v_err = '1') then
          -- not found => not occupied
          r_error_occupied_placement <= '0';
        else
          -- found
          if (s_lookup_occupied_v_out = X"F") then
            -- initial value => not occupied
            r_error_occupied_placement <= '0';
          else
            r_error_occupied_placement <= '1';
          end if;
        end if;

      end if;
    end if;
  end process;

  s_write_mark <= r_chk_occupied_flag and s_lookup_occupied_v_v and (not s_lookup_occupied_v_err);



  -- trax.cc : trax::place(move mo, int turn) : board_marks[xy(x,y)] = 1;
  -- don't use arbiter because others not running
  mark_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if ((Rst = '1') or (Dash_T = '1')) then
        r_place_mark_key   <= (others => '0');
        r_place_mark_value <= (others => '0');
        r_place_mark_wr_en <= '0';
      else
        if (s_write_mark = '1') then -- r_note_rx_v
          r_place_mark_key   <= r_note_y(7 downto 0) & r_note_x(7 downto 0);
          r_place_mark_value <= conv_std_logic_vector(1, 4);
          r_place_mark_wr_en <= '1';
--        elsif () then
        else
          r_place_mark_key   <= (others => '0');
          r_place_mark_value <= (others => '0');
          r_place_mark_wr_en <= '0';
        end if;
      end if;
    end if;
  end process;



  -- trax.cc : trax::place(const int x, const int y, const char tile, int turn) : board[xy(x,y)] = tile;
  tile_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if ((Rst = '1') or (Dash_T = '1')) then
        r_place_tile_key   <= (others => '0');
        r_place_tile_value <= (others => '0');
        r_place_tile_wr_en <= '0';
      else
        if (s_write_mark = '1') then -- r_note_rx_v
          r_place_tile_key   <= r_note_y(7 downto 0) & r_note_x(7 downto 0);
          r_place_tile_value <= r_note_t(3 downto 0);
          r_place_tile_wr_en <= '1';
--        elsif () then
        else
          r_place_tile_key   <= (others => '0');
          r_place_tile_value <= (others => '0');
          r_place_tile_wr_en <= '0';
        end if;
      end if;
    end if;
  end process;

  i_place_getaroundcolors: getaroundcolors
    port map (
      Clk             => Clk,
      Rst             => Rst,

      X_in            => r_note_x(7 downto 0),
      Y_in            => r_note_y(7 downto 0),
      V_in            => r_note_v, -- r_note_rx_v,

      Lc              => s_place_getaround_lc,
      Rc              => s_place_getaround_rc,
      Uc              => s_place_getaround_uc,
      Dc              => s_place_getaround_dc,
      C_v             => s_place_getaround_c_v,

      Map_ready       => s_map_board_ready,

      Req             => s_map_req(2 downto 0),
      Ack             => s_map_ack(2 downto 0),
      Key             => s_place_geraround_key,
      Value           => open,
      Wr_en           => open,
      Rd_en           => s_place_getaround_rd_en,
      Res             => s_map_board_res,
      Res_v           => s_map_board_res_v,
      Notfound        => s_map_board_notfound,

      Color_map_ready => s_map_board_color_ready,

      Color_req       => s_map_color_req(3 downto 0),
      Color_ack       => s_map_color_ack(3 downto 0),
      Color_key       => s_place_getaround_color_key,
      Color_value     => open,
      Color_wr_en     => open,
      Color_rd_en     => s_place_getaround_color_rd_en,
      Color_res       => s_map_board_color_res,
      Color_res_v     => s_map_board_color_res_v,
      Color_notfound  => s_map_board_color_notfound
    );

  i_is_isolated: is_isolated
    port map (
      Clk   => Clk,
      Rst   => Rst,

      Turn  => c_turn(15 downto 0),

      Lc    => s_place_getaround_lc,
      Rc    => s_place_getaround_rc,
      Uc    => s_place_getaround_uc,
      Dc    => s_place_getaround_dc,
      C_v   => s_place_getaround_c_v,

      Res   => s_error_is_isolated,
      Color => s_isolated_color
    );

  isolated_chk_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (r_note_v = '1') then
        r_isolated_chk <= (others => '0');
      else
        r_isolated_chk(1 downto 0) <= r_isolated_chk(0) & s_place_getaround_c_v;
        if (r_isolated_chk(1) = '1') then
          r_isolated_chk(2) <= s_error_is_isolated;
        end if;
      end if;
    end if;
  end process;


  i_is_prohibited_3: is_prohibited_3
    port map (
      Clk => Clk,
      Rst => Rst,

      Lc  => s_place_getaround_lc,
      Rc  => s_place_getaround_rc,
      Uc  => s_place_getaround_uc,
      Dc  => s_place_getaround_dc,
      C_v => s_place_getaround_c_v,

      Res => s_error_is_prohibited_3
    );

  i_is_consistent_placement: is_consistent_placement
    port map (
      Clk  => Clk,
      Rst  => Rst,

      Lc   => s_place_getaround_lc,
      Rc   => s_place_getaround_rc,
      Uc   => s_place_getaround_uc,
      Dc   => s_place_getaround_dc,
      C_v  => s_place_getaround_c_v,

      Tile => r_note_t(3 downto 0),

      Res  => s_error_is_consistent_placement
    );

  consistent_chk_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (r_note_v = '1') then
        r_consistent_chk <= (others => '0');
      else
        r_consistent_chk(1 downto 0) <= r_consistent_chk(0) & s_place_getaround_c_v;
        if (r_consistent_chk(1) = '1') then
          r_consistent_chk(2) <= s_error_is_consistent_placement;
        end if;
      end if;
    end if;
  end process;


  process(Clk)
  begin
    if (rising_edge(Clk)) then
      r_color_delay_v(1 downto 0) <= r_color_delay_v(0) & s_place_getaround_c_v;
    end if;
  end process;


  i_color_tile: color_the_tile
    generic map (
      DELAY_CYCLE => 3
    )
    port map (
      Clk         => Clk,
      Rst         => Rst,

      Color       => s_isolated_color, -- TODO: 2 cycles later than this valid
      Tile        => r_note_t(3 downto 0),
      Lc          => s_place_getaround_lc,
      Rc          => s_place_getaround_rc,
      Uc          => s_place_getaround_uc,
      Dc          => s_place_getaround_dc,
      C_v         => r_color_delay_v(1), -- s_place_getaround_c_v,

      Color_out   => s_colored_tile,
      Color_out_v => s_colored_tile_v
    );

  write_color_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if ((Rst = '1') or (Dash_T = '1')) then
        r_colored_tile_key   <= (others => '0');
        r_colored_tile_value <= (others => '0');
        r_colored_tile_wr_en <= '0';
      else
        if (s_colored_tile_v = '1') then
          r_colored_tile_key   <= r_note_y(7 downto 0) & r_note_x(7 downto 0);
          r_colored_tile_value <= s_colored_tile;
          r_colored_tile_wr_en <= '1';
        else
          r_colored_tile_key   <= (others => '0');
          r_colored_tile_value <= (others => '0');
          r_colored_tile_wr_en <= '0';
        end if;
      end if;
    end if;
  end process;


  done_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if ((Rst = '1') or (Dash_T = '1')) then
        r_done <= (others => '0');
      else
        if (r_note_v = '1') then
          r_done <= (others => '0');
        else
          if (s_lookup_occupied_v_v = '1') then
            r_done(3) <= '1';
          end if;
          if (s_place_getaround_c_v = '1') then
            r_done(4) <= '1';
          end if;
          if (r_isolated_chk(1) = '1') then
            r_done(5) <= '1';
          end if;
          if (s_place_getaround_c_v = '1') then
            r_done(6) <= '1';
          end if;
          if (r_consistent_chk(1) = '1') then
            r_done(7) <= '1';
          end if;
          if (r_colored_tile_wr_en = '1') then
            r_done(8) <= '1';
          end if;

          if (r_done(8 downto 3) = "1111111") then
            r_done(1) <= '1';
          elsif ((r_chk_occupied_flag = '1') and (s_lookup_occupied_v_v = '1') and (s_lookup_occupied_v_err = '0')) then
            r_done(1) <= '1';
          else
            r_done(1) <= '0';
          end if;
          r_done(2) <= r_done(1);
          r_done(0) <= (not r_done(2)) and r_done(1);
        end if;
      end if;
    end if;
  end process;


  i_rnd_note_gen: rnd_note_gen
    port map (
      Clk       => Clk,
      Rst       => Rst,

      Dash_T    => Dash_T,

      Save      => s_notegen_save,
      Restore   => s_notegen_restore,
      Mem_ready => s_notegen_mem_ready,

      M_left    => s_notegen_m_left,
      M_right   => s_notegen_m_right,
      M_top     => s_notegen_m_top,
      M_bottom  => s_notegen_m_bottom,

      Done      => s_notegen_done,
      Errors    => s_notegen_errors,

      Note_x    => s_notegen_note_x,
      Note_y    => s_notegen_note_y,
      Note_t    => s_notegen_note_t,
      Note_v    => s_notegen_note_v,

      Send      => s_notegen_send
    );

  s_notegen_mem_ready <= s_map_board_ready & s_map_board_color_ready & s_map_board_marks_ready;

  s_notegen_m_left   <= c_board_left;
  s_notegen_m_right  <= c_board_right;
  s_notegen_m_top    <= c_board_top;
  s_notegen_m_bottom <= c_board_bottom;

  s_notegen_done <= r_done(0);
  s_notegen_errors <= r_error_occupied_placement & r_isolated_chk(2) & s_error_is_prohibited_3 & r_consistent_chk(2);


  Trying <= s_notegen_note_v;







end rtl;

------------------------------------------------------------------------------

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity sim_bot2 is
end sim_bot2;

architecture sim of sim_bot2 is

  constant CLK_CYCLE : time := 5 ns;

  constant ASCII_AT     : std_logic_vector(7 downto 0) := X"40"; -- @
  constant ASCII_0      : std_logic_vector(7 downto 0) := X"30";
  constant ASCII_9      : std_logic_vector(7 downto 0) := X"39";
  constant ASCII_A      : std_logic_vector(7 downto 0) := X"41";
  constant ASCII_B      : std_logic_vector(7 downto 0) := X"42";
  constant ASCII_T      : std_logic_vector(7 downto 0) := X"54";
  constant ASCII_W      : std_logic_vector(7 downto 0) := X"57";
  constant ASCII_Z      : std_logic_vector(7 downto 0) := X"5A";
  constant ASCII_LF     : std_logic_vector(7 downto 0) := X"0A";
  constant ASCII_PLUS   : std_logic_vector(7 downto 0) := X"2B"; -- +
  constant ASCII_SLASH  : std_logic_vector(7 downto 0) := X"2F"; -- /
  constant ASCII_BSLASH : std_logic_vector(7 downto 0) := X"5C"; -- \
  constant ASCII_DASH   : std_logic_vector(7 downto 0) := X"2D"; -- -

  constant NOTE_PLUS   : std_logic_vector(3 downto 0) := X"1";
  constant NOTE_SLASH  : std_logic_vector(3 downto 0) := X"2";
  constant NOTE_BSLASH : std_logic_vector(3 downto 0) := X"3";

  component bot2
    generic (
      PLAYER_ID : std_logic_vector(15 downto 0) := X"AA"
    );
    port (
      Clk        : in std_logic;
      Rst        : in std_logic;

      Dash_T     : in std_logic;
      Dash_W     : in std_logic;
      Dash_B     : in std_logic;
      Dash_Error : in std_logic;

      Pid        : out std_logic_vector(15 downto 0);
      Pid_v      : out std_logic;

      Note_rx_x  : in std_logic_vector(31 downto 0);
      Note_rx_y  : in std_logic_vector(31 downto 0);
      Note_rx_t  : in std_logic_vector(7 downto 0);
      Note_rx_v  : in std_logic;

      Note_tx_x  : out std_logic_vector(31 downto 0);
      Note_tx_y  : out std_logic_vector(31 downto 0);
      Note_tx_t  : out std_logic_vector(7 downto 0);
      Note_tx_v  : out std_logic;

      Got_init   : out std_logic;
      Im_first   : out std_logic;
      Init_done  : out std_logic
    );
  end component;

  signal clk        : std_logic;
  signal rst        : std_logic;
  signal dash_t     : std_logic;
  signal dash_w     : std_logic;
  signal dash_b     : std_logic;
  signal dash_error : std_logic;
  signal pid        : std_logic_vector(15 downto 0);
  signal pid_v      : std_logic;
  signal note_rx_x  : std_logic_vector(31 downto 0);
  signal note_rx_y  : std_logic_vector(31 downto 0);
  signal note_rx_t  : std_logic_vector(7 downto 0);
  signal note_rx_v  : std_logic;
  signal note_tx_x  : std_logic_vector(31 downto 0);
  signal note_tx_y  : std_logic_vector(31 downto 0);
  signal note_tx_t  : std_logic_vector(7 downto 0);
  signal note_tx_v  : std_logic;
  signal got_init   : std_logic;
  signal im_first   : std_logic;
  signal init_done  : std_logic;

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

  uut: bot2
    generic map (
      PLAYER_ID  => X"4141"
    )
    port map (
      Clk        => clk,
      Rst        => rst,

      Dash_T     => dash_t,
      Dash_W     => dash_w,
      Dash_B     => dash_b,
      Dash_Error => dash_error,

      Pid        => pid,
      Pid_v      => pid_v,

      Note_rx_x  => note_rx_x,
      Note_rx_y  => note_rx_y,
      Note_rx_t  => note_rx_t,
      Note_rx_v  => note_rx_v,

      Note_tx_x  => note_tx_x,
      Note_tx_y  => note_tx_y,
      Note_tx_t  => note_tx_t,
      Note_tx_v  => note_tx_v,

      Got_init   => got_init,
      Im_first   => im_first,
      Init_done  => init_done
    );

  process
  begin
    dash_t <= '0';
    dash_w <= '0';
    dash_b <= '0';
    dash_error <= '0';

    note_rx_x <= conv_std_logic_vector(0, 32);
    note_rx_y <= conv_std_logic_vector(0, 32);
    note_rx_t <= conv_std_logic_vector(0, 8);
    note_rx_v <= '0';

--    wait for 350 us;
    wait for CLK_CYCLE*10;
    wait until (clk'event and clk = '0');

    dash_t <= '1';
    wait for CLK_CYCLE;
    dash_t <= '0';

--    wait for 350 us;
    wait for CLK_CYCLE*10;
    wait until (clk'event and clk = '0');

    dash_w <= '0';
    wait for CLK_CYCLE;
    dash_w <= '0';

    wait for CLK_CYCLE * 10;

    -- @0/

    note_rx_x <= conv_std_logic_vector(0, 32);
    note_rx_y <= conv_std_logic_vector(0, 32);
    note_rx_t <= X"0" & NOTE_SLASH;
    note_rx_v <= '1';
    wait for CLK_CYCLE;
    note_rx_x <= conv_std_logic_vector(0, 32);
    note_rx_y <= conv_std_logic_vector(0, 32);
    note_rx_t <= conv_std_logic_vector(0, 8);
    note_rx_v <= '0';

    wait for 5 ms;
    wait until (clk'event and clk = '0');

    -- @1/

--    note_rx_x <= conv_std_logic_vector(0, 32);
--    note_rx_y <= conv_std_logic_vector(1, 32);
--    note_rx_t <= X"0" & NOTE_SLASH;
--    note_rx_v <= '1';
--    wait for CLK_CYCLE;
--    note_rx_x <= conv_std_logic_vector(0, 32);
--    note_rx_y <= conv_std_logic_vector(0, 32);
--    note_rx_t <= conv_std_logic_vector(0, 8);
--    note_rx_v <= '0';

--    wait for 2 ms;
--    wait until (clk'event and clk = '0');

    -- A2+

--    note_rx_x <= conv_std_logic_vector(1, 32);
--    note_rx_y <= conv_std_logic_vector(2, 32);
--    note_rx_t <= X"0" & NOTE_PLUS;
--    note_rx_v <= '1';
--    wait for CLK_CYCLE;
--    note_rx_x <= conv_std_logic_vector(0, 32);
--    note_rx_y <= conv_std_logic_vector(0, 32);
--    note_rx_t <= conv_std_logic_vector(0, 8);
--    note_rx_v <= '0';

--    wait for 2 ms;
--    wait until (clk'event and clk = '0');

    note_rx_x <= conv_std_logic_vector(1, 32);
    note_rx_y <= conv_std_logic_vector(1, 32);
    note_rx_t <= X"0" & NOTE_SLASH;
    note_rx_v <= '1';
    wait for CLK_CYCLE;
    note_rx_x <= conv_std_logic_vector(0, 32);
    note_rx_y <= conv_std_logic_vector(0, 32);
    note_rx_t <= conv_std_logic_vector(0, 8);
    note_rx_v <= '0';






    wait;
  end process;












end sim;


-- synthesis translate_on

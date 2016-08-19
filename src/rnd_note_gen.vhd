library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity make_mask is
  generic (
    DATA_WIDTH : integer := 8
  );
  port (
    Clk  : in std_logic;
    Rst  : in std_logic;

    Lim  : in std_logic_vector(DATA_WIDTH-1 downto 0);

    Sig  : out std_logic;
    Mag  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    Mask : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end make_mask;

architecture rtl of make_mask is

  signal r_sign_1 : std_logic;
  signal r_mag_1  : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal r_sign_2 : std_logic;
  signal r_mag_2  : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal r_mask : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

  process(Clk)
    variable pos : integer := 0;
  begin
    if (rising_edge(Clk)) then
      r_sign_1 <= Lim(DATA_WIDTH-1);
      r_mag_1  <= '0' & Lim(DATA_WIDTH-2 downto 0);

      r_sign_2 <= r_sign_1;
      if (r_sign_1 = '1') then
        r_mag_2 <= (not r_mag_1) + conv_std_logic_vector(1, DATA_WIDTH);
      else
        r_mag_2 <= r_mag_1;
      end if;

      if (r_mag_2(DATA_WIDTH-2 downto 0) = conv_std_logic_vector(0, DATA_WIDTH-1)) then
        r_mask(DATA_WIDTH-2 downto 0) <= conv_std_logic_vector(1, DATA_WIDTH-1);
      else
        for i in 0 to DATA_WIDTH-2 loop
          if (r_mag_2(i) = '1') then
            pos := i;
          end if;
        end loop;

        for j in 0 to DATA_WIDTH-2 loop
          if (j > pos) then
            r_mask(j) <= '0';
          else
            r_mask(j) <= '1';
          end if;
        end loop;
      end if;
      r_mask(DATA_WIDTH-1) <= '0';

    end if;
  end process;

  Sig  <= r_sign_2;
  Mag  <= '0' & r_mag_2(DATA_WIDTH-2 downto 0);
  Mask <= r_mask;

end rtl;

------------------------------------------------------------------------------

-- synthesis translate_off

-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.std_logic_arith.all;
-- use ieee.std_logic_signed.all;
-- 
-- entity sim_make_mask is
-- end sim_make_mask;
-- 
-- architecture sim of sim_make_mask is
-- 
--   constant CLK_CYCLE : time := 5 ns;
-- 
--   component make_mask
--     port (
--       Clk  : in std_logic;
--       Rst  : in std_logic;
-- 
--       Lim  : in std_logic_vector(7 downto 0);
-- 
--       Sig  : out std_logic;
--       Mag  : out std_logic_vector(7 downto 0);
--       Mask : out std_logic_vector(7 downto 0)
--     );
--   end component;
-- 
--   signal clk  : std_logic;
--   signal rst  : std_logic;
--   signal lim  : std_logic_vector(7 downto 0);
--   signal sig  : std_logic;
--   signal mag  : std_logic_vector(7 downto 0);
--   signal mask : std_logic_vector(7 downto 0);
-- 
-- begin
-- 
--   clk_gen_proc: process
--   begin
--     clk <= '1';
--     wait for CLK_CYCLE/2;
--     clk <= '0';
--     wait for CLK_CYCLE/2;
--   end process;
-- 
--   rst_gen_proc: process
--   begin
--     rst <= '1';
--     wait for CLK_CYCLE*3;
--     wait until (clk'event and clk = '0');
--     rst <= '0';
--     wait;
--   end process;
-- 
--   uut: make_mask
--     port map (
--       Clk  => clk,
--       Rst  => rst,
-- 
--       Lim  => lim,
-- 
--       Sig  => sig,
--       Mag  => mag,
--       Mask => mask
--     );
-- 
--   process
--   begin
--     lim <= X"00";
-- 
--     wait for CLK_CYCLE * 10;
-- 
--     for i in 0 to 127 loop
--       lim <= conv_std_logic_vector(i, 8);
--       wait for CLK_CYCLE * 10;
--     end loop;
-- 
--     lim <= conv_std_logic_vector(0, 8);
--     wait for CLK_CYCLE * 10;
-- 
--     for i in 255 downto 128 loop
--       lim <= conv_std_logic_vector(i, 8);
--       wait for CLK_CYCLE * 10;
--     end loop;
-- 
-- 
--     wait;
--   end process;
-- 
-- end sim;

-- synthesis translate_on

------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity rnd_note_gen is
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
end rnd_note_gen;

architecture rtl of rnd_note_gen is

  constant USE_PRBS : boolean := false;

  constant NOTE_PLUS   : std_logic_vector(3 downto 0) := X"1";
  constant NOTE_SLASH  : std_logic_vector(3 downto 0) := X"2";
  constant NOTE_BSLASH : std_logic_vector(3 downto 0) := X"3";

  component make_mask
    generic (
      DATA_WIDTH : integer := 8
    );
    port (
      Clk  : in std_logic;
      Rst  : in std_logic;

      Lim  : in std_logic_vector(DATA_WIDTH-1 downto 0);

      Sig  : out std_logic;
      Mag  : out std_logic_vector(DATA_WIDTH-1 downto 0);
      Mask : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  component mish_prbs15p16
      port (
          RESET : in std_logic;
          CLK   : in std_logic;

          CLR   : in std_logic;
          ENA   : in std_logic;

          DOUT  : out std_logic_vector(15 downto 0);
          VOUT  : out std_logic
      );
  end component;

--   signal s_prbs_src : std_logic_vector(15 downto 0);

  type T_SEQ is (
    TSEQ_SEND_NOTE,
    TSEQ_WAIT_RESTORE_DONE,
    TSEQ_DO_RESTORE,
    TSEQ_WAIT_PUT,
    TSEQ_TRY_PUT,
    TSEQ_WAIT_SAVE_DONE,
    TSEQ_DO_SAVE,
    TSEQ_WAIT
  );
  signal c_seq : T_SEQ;

  type T_NOTE_SEQ is (
    TSEQ_NG_T_LD,
    TSEQ_NG_Y_GATE,
    TSEQ_NG_Y_SMALLER,
    TSEQ_NG_Y_LARGER,
    TSEQ_NG_Y_LD_WAIT2,
    TSEQ_NG_Y_LD_WAIT,
    TSEQ_NG_Y_LD,
    TSEQ_NG_X_GATE,
    TSEQ_NG_X_SMALLER,
    TSEQ_NG_X_LARGER,
    TSEQ_NG_X_LD_WAIT2,
    TSEQ_NG_X_LD_WAIT,
    TSEQ_NG_X_LD,
    TSEQ_NG_WAIT
  );
  signal c_note_seq : T_NOTE_SEQ;

  signal c_wait : std_logic_vector(3 downto 0);



--   signal s_left   : std_logic_vector(7 downto 0);
--   signal s_right  : std_logic_vector(7 downto 0);
--   signal s_top    : std_logic_vector(7 downto 0);
--   signal s_bottom : std_logic_vector(7 downto 0);
-- 
--   signal s_prbs : std_logic_vector(7 downto 0);
--   signal r_prbs : std_logic_vector(7 downto 0);
--   signal r_prbs2 : std_logic_vector(7 downto 0);




--   signal r_prbs_sign_src : std_logic;
--   signal r_prbs_mag_src  : std_logic_vector(7 downto 0);
--   signal r_prbs_sign : std_logic;
--   signal r_prbs_mag  : std_logic_vector(7 downto 0);
-- 
--   signal r_left_sign_src : std_logic;
--   signal r_left_mag_src  : std_logic_vector(7 downto 0);
--   signal r_right_sign_src : std_logic;
--   signal r_right_mag_src  : std_logic_vector(7 downto 0);
--   signal r_top_sign_src : std_logic;
--   signal r_top_mag_src  : std_logic_vector(7 downto 0);
--   signal r_bottom_sign_src : std_logic;
--   signal r_bottom_mag_src  : std_logic_vector(7 downto 0);
--   signal r_left_sign : std_logic;
--   signal r_left_mag  : std_logic_vector(7 downto 0);
--   signal r_right_sign : std_logic;
--   signal r_right_mag  : std_logic_vector(7 downto 0);
--   signal r_top_sign : std_logic;
--   signal r_top_mag  : std_logic_vector(7 downto 0);
--   signal r_bottom_sign : std_logic;
--   signal r_bottom_mag  : std_logic_vector(7 downto 0);
-- 
--   signal s_prbs_lt_left   : std_logic;
--   signal s_prbs_st_right  : std_logic;
--   signal s_prbs_lt_top    : std_logic;
--   signal s_prbs_st_bottom : std_logic;
--   signal s_prbs_nequ_zero : std_logic;
-- 


-- 
-- 
-- 
-- 
-- 
--   signal r_left_sign_1 : std_logic;
--   signal r_left_mag_1  : std_logic_vector(7 downto 0);
-- 
--   signal r_left_sign_2 : std_logic;
--   signal r_left_mag_2  : std_logic_vector(7 downto 0);
-- 
--   signal r_left_mask : std_logic;



--   signal s_left_sig  : std_logic;
--   signal s_left_mag  : std_logic_vector(7 downto 0);
--   signal s_left_mask : std_logic_vector(7 downto 0);
-- 
--   signal s_right_sig  : std_logic;
--   signal s_right_mag  : std_logic_vector(7 downto 0);
--   signal s_right_mask : std_logic_vector(7 downto 0);
-- 
--   signal s_top_sig  : std_logic;
--   signal s_top_mag  : std_logic_vector(7 downto 0);
--   signal s_top_mask : std_logic_vector(7 downto 0);
-- 
--   signal s_bottom_sig  : std_logic;
--   signal s_bottom_mag  : std_logic_vector(7 downto 0);
--   signal s_bottom_mask : std_logic_vector(7 downto 0);
-- 
--   signal r_prbs_sig_1 : std_logic;
--   signal r_prbs_mag_1 : std_logic_vector(7 downto 0);
-- 
--   signal r_prbs_sig_2 : std_logic;
--   signal r_prbs_mag_2 : std_logic_vector(7 downto 0);
-- 
--   signal r_prbs_mag_left   : std_logic_vector(7 downto 0);
--   signal r_prbs_mag_right  : std_logic_vector(7 downto 0);
--   signal r_prbs_mag_top    : std_logic_vector(7 downto 0);
--   signal r_prbs_mag_bottom : std_logic_vector(7 downto 0);
-- 
--   signal r_prbs_sig : std_logic;
--   --signal r_prbs_mag : std_logic_vector(7 downto 0);
--   signal s_prbs_sig : std_logic;

  signal r_left   : std_logic_vector(7 downto 0);
  signal r_right  : std_logic_vector(7 downto 0);
  signal r_top    : std_logic_vector(7 downto 0);
  signal r_bottom : std_logic_vector(7 downto 0);
  signal r_done   : std_logic;

  signal s_left_sig  : std_logic;
  signal s_left_mag  : std_logic_vector(7 downto 0);

  signal s_right_sig  : std_logic;
  signal s_right_mag  : std_logic_vector(7 downto 0);

  signal s_top_sig  : std_logic;
  signal s_top_mag  : std_logic_vector(7 downto 0);

  signal s_bottom_sig  : std_logic;
  signal s_bottom_mag  : std_logic_vector(7 downto 0);

  signal r_width  : std_logic_vector(8 downto 0);
  signal r_height : std_logic_vector(8 downto 0);

  signal s_width_mask  : std_logic_vector(8 downto 0);
  signal s_height_mask : std_logic_vector(8 downto 0);

  signal s_prbs_src : std_logic_vector(15 downto 0);

  signal s_prbs_width_src  : std_logic_vector(8 downto 0);
  signal s_prbs_height_src : std_logic_vector(8 downto 0);

  signal s_prbs_width_valid  : std_logic;
  signal s_prbs_height_valid : std_logic;

  signal r_prbs_width_valid  : std_logic;
  signal r_prbs_height_valid : std_logic;

  signal r_prbs_x : std_logic_vector(8 downto 0);
  signal r_prbs_y : std_logic_vector(8 downto 0);

  signal s_prbs_x_nzero : std_logic;
  signal s_prbs_y_nzero : std_logic;

  signal r_save    : std_logic;
  signal r_restore : std_logic;

  signal r_note_x : std_logic_vector(31 downto 0);
  signal r_note_y : std_logic_vector(31 downto 0);
  signal r_note_t : std_logic_vector(7 downto 0);
  signal r_note_v : std_logic;

  signal r_note_ready : std_logic;

  signal r_send : std_logic;

  signal ri_note_x : std_logic_vector(7 downto 0);
  signal ri_note_y : std_logic_vector(7 downto 0);


  signal r_scan     : std_logic_vector(17 downto 0);
  signal r_scan_clr : std_logic;
  signal r_scan_inc : std_logic;
  signal r_scaned_x : std_logic_vector(7 downto 0);
  signal r_scaned_y : std_logic_vector(7 downto 0);
  signal r_scaned_t : std_logic_vector(7 downto 0);
  signal s_scan_inc : std_logic;


begin

  -- get magnitude -----------------------------------------------------------

  process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Rst = '1') then
        r_left <= (others => '0');
        r_right <= (others => '0');
        r_top <= (others => '0');
        r_bottom <= (others => '0');
      elsif ((c_seq = TSEQ_WAIT) and (Done = '1')) then
        r_left <= M_left;
        r_right <= M_right + "00000001";
        r_top   <= M_top;
        r_bottom <= M_bottom + "00000001";
      end if;
      r_done <= Done;
    end if;
  end process;

  i_mask_left: make_mask
    generic map (
      DATA_WIDTH => 8
    )
    port map (
      Clk  => Clk,
      Rst  => Rst,

      Lim  => r_left,

      Sig  => s_left_sig,
      Mag  => s_left_mag,
      Mask => open
    );

  i_mask_right: make_mask
    generic map (
      DATA_WIDTH => 8
    )
    port map (
      Clk  => Clk,
      Rst  => Rst,

      Lim  => r_right,

      Sig  => s_right_sig,
      Mag  => s_right_mag,
      Mask => open
    );

  i_mask_top: make_mask
    generic map (
      DATA_WIDTH => 8
    )
    port map (
      Clk  => Clk,
      Rst  => Rst,

      Lim  => r_top,

      Sig  => s_top_sig,
      Mag  => s_top_mag,
      Mask => open
    );

  i_mask_bottom: make_mask
    generic map (
      DATA_WIDTH => 8
    )
    port map (
      Clk  => Clk,
      Rst  => Rst,

      Lim  => r_bottom,

      Sig  => s_bottom_sig,
      Mag  => s_bottom_mag,
      Mask => open
    );


  -- make width and height ---------------------------------------------------

  process(Clk)
  begin
    if (rising_edge(Clk)) then
      r_width  <= ('0' & s_left_mag) + ('0' & s_right_mag);
      r_height <= ('0' & s_top_mag)  + ('0' & s_bottom_mag);
    end if;
  end process;

  i_mask_width: make_mask
    generic map (
      DATA_WIDTH => 9
    )
    port map (
      Clk  => Clk,
      Rst  => Rst,

      Lim  => r_width,

      Sig  => open,
      Mag  => open,
      Mask => s_width_mask
    );

  i_mask_height: make_mask
    generic map (
      DATA_WIDTH => 9
    )
    port map (
      Clk  => Clk,
      Rst  => Rst,

      Lim  => r_height,

      Sig  => open,
      Mag  => open,
      Mask => s_height_mask
    );


  -- get PRBS, mask and compare ----------------------------------------------

  i_prbs: mish_prbs15p16
    port map (
      RESET => Rst,
      CLK   => Clk,

      CLR   => '0',
      ENA   => '1',

      DOUT  => s_prbs_src,
      VOUT  => open
    );

  s_prbs_width_src(8 downto 0)  <= s_prbs_src(8 downto 0) and s_width_mask(8 downto 0);
  s_prbs_height_src(8 downto 0) <= s_prbs_src(8 downto 0) and s_height_mask(8 downto 0);

--  s_prbs_width_valid  <= '1' when (s_prbs_width_src(7 downto 0) <= r_width(7 downto 0))
--                    else '0';
--  s_prbs_height_valid <= '1' when (s_prbs_height_src(7 downto 0) <= r_height(7 downto 0))
--                    else '0';

  process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (s_prbs_width_src(7 downto 0) <= r_width(7 downto 0)) then
        r_prbs_width_valid <= '1';
      else
        r_prbs_width_valid <= '0';
      end if;
      if (s_prbs_height_src(7 downto 0) <= r_height(7 downto 0)) then
        r_prbs_height_valid <= '1';
      else
        r_prbs_height_valid <= '0';
      end if;

      r_prbs_x(8 downto 0) <= s_prbs_width_src(8 downto 0); -- - ('0' & s_left_mag);
      r_prbs_y(8 downto 0) <= s_prbs_height_src(8 downto 0); -- - ('0' & s_top_mag);
    end if;
  end process;

  s_prbs_x_nzero <= '1' when (r_prbs_x(7 downto 0) /= X"00")
               else '0';
  s_prbs_y_nzero <= '1' when (r_prbs_y(7 downto 0) /= X"00")
               else '0';


  -- simple scanner ----------------------------------------------------------

  process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (c_seq = TSEQ_WAIT) then -- (r_scan_clr = '1') then
        r_scan <= (others => '0');
      else
        if (r_scan_inc = '1') then
          if (r_scan(1 downto 0) = "10") then
            if (r_scan(9 downto 2) > (r_width(7 downto 0) - X"01")) then
              r_scan(17 downto 10) <= r_scan(17 downto 10) + 1;
              r_scan(9 downto 2) <= X"00";
            else
              r_scan(9 downto 2) <= r_scan(9 downto 2) + 1;
            end if;
            r_scan(1 downto 0) <= "00";
          else
            r_scan(1 downto 0) <= r_scan(1 downto 0) + 1;
          end if;
        end if;
      end if;

      r_scaned_x <= r_scan(9 downto 2); --  - s_left_mag;
      r_scaned_y <= r_scan(17 downto 10); --  - s_top_mag;
      case r_scan(1 downto 0) is
        when "10"   => r_scaned_t <= X"0" & NOTE_BSLASH;
        when "01"   => r_scaned_t <= X"0" & NOTE_SLASH;
        when others => r_scaned_t <= X"0" & NOTE_PLUS;
      end case;


    end if;
  end process;

  ----------------------------------------------------------------------------

  cnt_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if ((Rst = '1') or (Dash_T = '1')) then
        c_seq <= TSEQ_WAIT;
        r_scan_clr <= '0';
        r_scan_inc <= '0';
      else
        case c_seq is
          when TSEQ_SEND_NOTE =>
            c_seq <= TSEQ_WAIT;

          when TSEQ_WAIT_RESTORE_DONE =>
            if (c_wait = X"F") then
              if (Mem_ready = "111") then
                c_seq <= TSEQ_TRY_PUT;
              end if;
            else
              c_wait <= c_wait + 1;
            end if;

          when TSEQ_DO_RESTORE =>
            c_seq <= TSEQ_WAIT_RESTORE_DONE;
            c_wait <= (others => '0');
            r_scan_inc <= '0';

          when TSEQ_WAIT_PUT =>
            if (r_done = '1') then
              if (Errors = "0000") then
                c_seq <= TSEQ_SEND_NOTE;
              else
                c_seq <= TSEQ_DO_RESTORE;
                r_scan_inc <= '1';
              end if;
            end if;

          when TSEQ_TRY_PUT =>
            c_seq <= TSEQ_WAIT_PUT;

          when TSEQ_WAIT_SAVE_DONE =>
            if (c_wait = X"F") then
              if ((Mem_ready = "111") and (r_note_ready = '1')) then
                c_seq <= TSEQ_TRY_PUT;
              end if;
            else
              c_wait <= c_wait + 1;
            end if;

          when TSEQ_DO_SAVE =>
            c_seq <= TSEQ_WAIT_SAVE_DONE;
            c_wait <= (others => '0');

            r_scan_clr <= '0';

          when TSEQ_WAIT =>
            if (r_done = '1') then
              c_seq <= TSEQ_DO_SAVE;
              r_scan_clr <= '1';
            end if;

          when others =>
            c_seq <= TSEQ_WAIT;
            r_scan_clr <= '0';
            r_scan_inc <= '0';

        end case;
      end if;
    end if;
  end process;


  gen_note_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if ((Rst = '1') or (Dash_T = '1')) then
        c_note_seq <= TSEQ_NG_WAIT;
      else
        case c_note_seq is
          when TSEQ_NG_T_LD =>
            if (USE_PRBS) then
              case s_prbs_src(1 downto 0) is
                when "10"   => r_note_t <= X"0" & NOTE_BSLASH;
                when "01"   => r_note_t <= X"0" & NOTE_SLASH;
                when others => r_note_t <= X"0" & NOTE_PLUS;
              end case;
            else
              r_note_t <= r_scaned_t;
            end if;
            c_note_seq <= TSEQ_NG_WAIT;
            r_note_ready <= '1';

          when TSEQ_NG_Y_LD =>
            if (USE_PRBS) then
              if ((r_prbs_height_valid = '1') and (s_prbs_y_nzero = '1')) then
                ri_note_y <= r_prbs_y(7 downto 0);
                c_note_seq <= TSEQ_NG_T_LD;
              end if;
            else
              ri_note_y <= r_scaned_y;
              c_note_seq <= TSEQ_NG_T_LD;
            end if;

          when TSEQ_NG_X_LD =>
            if (USE_PRBS) then
              if ((r_prbs_width_valid = '1') and (s_prbs_x_nzero = '1')) then
                ri_note_x <= r_prbs_x(7 downto 0);
                c_note_seq <= TSEQ_NG_Y_LD;
              end if;
            else
              ri_note_x <= r_scaned_x;
              c_note_seq <= TSEQ_NG_Y_LD;
            end if;

          when TSEQ_NG_WAIT =>
            if (Done = '1') then
              c_note_seq <= TSEQ_NG_X_LD;
              r_note_ready <= '0';
            end if;

          when others =>
            c_note_seq <= TSEQ_NG_WAIT;
        end case;
      end if;
    end if;
  end process;


  signals_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (c_seq = TSEQ_DO_SAVE) then
        r_save <= '1';
      else
        r_save <= '0';
      end if;
      if (c_seq = TSEQ_DO_RESTORE) then
        r_restore <= '1';
      else
        r_restore <= '0';
      end if;
      r_note_x <= X"000000" & ri_note_x;
      r_note_y <= X"000000" & ri_note_y;
      if (c_seq = TSEQ_TRY_PUT) then
        r_note_v <= '1';
      else
        r_note_v <= '0';
      end if;
      if (Rst = '1') then
        r_send <= '0';
      elsif (c_seq = TSEQ_SEND_NOTE) then
        r_send <= '1';
      else
        r_send <= '0';
      end if;
    end if;
  end process;

  Save <= r_save;
  Restore <= r_restore;

  Note_x <= r_note_x;
  Note_y <= r_note_y;
  Note_t <= r_note_t;
  Note_v <= r_note_v;

  Send <= r_send;

end rtl;

------------------------------------------------------------------------------

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity sim_rnd_note_gen is
end sim_rnd_note_gen;

architecture sim of sim_rnd_note_gen is

  constant CLK_CYCLE : time := 5 ns;

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

  signal clk       : std_logic;
  signal rst       : std_logic;
  signal dash_t    : std_logic;
  signal save      : std_logic;
  signal restore   : std_logic;
  signal mem_ready : std_logic_vector(2 downto 0);
  signal m_left    : std_logic_vector(7 downto 0);
  signal m_right   : std_logic_vector(7 downto 0);
  signal m_top     : std_logic_vector(7 downto 0);
  signal m_bottom  : std_logic_vector(7 downto 0);
  signal done      : std_logic;
  signal errors    : std_logic_vector(3 downto 0);
  signal note_x    : std_logic_vector(31 downto 0);
  signal note_y    : std_logic_vector(31 downto 0);
  signal note_t    : std_logic_vector(7 downto 0);
  signal note_v    : std_logic;
  signal send      : std_logic;

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

  uut: rnd_note_gen
    port map (
      Clk => clk,
      Rst => rst,

      Dash_T => dash_t,

      Save   => save,
      Restore => restore,
      Mem_ready => mem_ready,

      M_left    => m_left,
      M_right   => m_right,
      M_top     => m_top,
      M_bottom  => m_bottom,

      Done      => done,
      Errors    => errors,

      Note_x    => note_x,
      Note_y    => note_y,
      Note_t    => note_t,
      Note_v    => note_v,

      Send      => send
    );

--  M_left   <= conv_std_logic_vector(-10, 8);
--  M_right  <= conv_std_logic_vector(16, 8);
--  M_top    <= conv_std_logic_vector(-8, 8);
--  M_bottom <= conv_std_logic_vector(12, 8);


  process
  begin
    M_left   <= X"FF";
    M_right  <= X"00";
    M_top    <= X"FF";
    M_bottom <= X"00";

    dash_t <= '0';
    mem_ready <= "000";
    done <= '0';
    errors <= "0000";

    wait for CLK_CYCLE * 10;

    dash_t <= '1';
    wait for CLK_CYCLE;
    dash_t <= '0';

    wait for CLK_CYCLE * 10;

    done <= '1';
    wait for CLK_CYCLE;
    done <= '0';

    -- save drived

    wait for CLK_CYCLE * 30;

    mem_ready <= "111";

    -- note_v drived

    wait for CLK_CYCLE * 30;

    errors <= "0001";
    wait for CLK_CYCLE;

    done <= '1';
    wait for CLK_CYCLE;
    done <= '0';

    wait until (restore = '1');

    wait for CLK_CYCLE * 3;

    mem_ready <= "000";

    wait for CLK_CYCLE * 100;

    mem_ready <= "111";

    -- note_v drived

    wait for CLK_CYCLE * 100;

    errors <= "0000";
    wait for CLK_CYCLE;

    done <= '1';
    wait for CLK_CYCLE;
    done <= '0';


    wait for CLK_CYCLE * 100;

    done <= '1';
    wait for CLK_CYCLE;
    done <= '0';



    wait;
  end process;


end sim;

-- synthesis translate_on

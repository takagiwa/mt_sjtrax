library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity traxif_rx is
  port (
    Clk        : in std_logic;
    Rst        : in std_logic;

    Din        : in std_logic_vector(7 downto 0);
    Din_valid  : in std_logic;

    Dash_T     : out std_logic;
    Dash_W     : out std_logic;
    Dash_B     : out std_logic;
    Dash_Error : out std_logic;

    Note_x     : out std_logic_vector(31 downto 0); -- X
    Note_y     : out std_logic_vector(31 downto 0); -- Y
    Note_t     : out std_logic_vector(7 downto 0);  -- Type
    Note_v     : out std_logic                      -- Valid
  );
end traxif_rx;

architecture rtl of traxif_rx is

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

  type T_SEQ is (
    TSEQ_WAIT_FOR_FIRST_CHAR,
    TSEQ_WAIT_FOR_CTRL_CHAR,
    TSEQ_WAIT_FOR_CTRL_LF,
    TSEQ_WAIT_FOR_NOTE_STR,
    TSEQ_CTRL_END,
    TSEQ_WAIT_FOR_NOTE_LF,
    TSEQ_NOTE_END
  );
  signal c_seq : T_SEQ;

  signal r_din       : std_logic_vector(7 downto 0);
  signal r_din_valid : std_logic;

  signal r_dash_t     : std_logic;
  signal r_dash_w     : std_logic;
  signal r_dash_b     : std_logic;
  signal r_dash_error : std_logic;

  signal r_dash_dat : std_logic_vector(2 downto 0);


  signal r_note_x     : integer;
  signal r_note_y     : integer;
  signal r_note_t     : std_logic_vector(7 downto 0);
  signal r_note_valid : std_logic;

begin

input_proc: process(Clk)
begin
  if (rising_edge(Clk)) then
    if (Din_valid = '1') then
      r_din <= Din;
    end if;
    r_din_valid <= Din_valid;
  end if;
end process;

seq_proc: process(Clk)
begin
  if (rising_edge(Clk)) then
    if (Rst = '1') then
      c_seq <= TSEQ_WAIT_FOR_FIRST_CHAR;

      r_dash_t <= '0';
      r_dash_w <= '0';
      r_dash_b <= '0';
      r_dash_error <= '0';

      r_dash_dat <= "000";

      r_note_x <= 0;
      r_note_y <= 0;
      r_note_t <= (others => '0');
      r_note_valid <= '0';
    else
      case c_seq is
        when TSEQ_NOTE_END =>
          r_note_valid <= '0';
          c_seq <= TSEQ_WAIT_FOR_FIRST_CHAR;

        when TSEQ_WAIT_FOR_NOTE_STR =>
          if (r_din_valid = '1') then
            if ((r_din >= ASCII_A) and (r_din <= ASCII_Z)) then
              r_note_x <= (r_note_x * 26) + conv_integer(r_din) - conv_integer(ASCII_A) + 1;
            elsif ((r_din >= ASCII_0) and (r_din <= ASCII_9)) then
              r_note_y <= (r_note_y * 10) + conv_integer(r_din) - conv_integer(ASCII_0);
            elsif (r_din = ASCII_PLUS) then
              r_note_t <= X"0" & NOTE_PLUS;
            elsif (r_din = ASCII_SLASH) then
              r_note_t <= X"0" & NOTE_SLASH;
            elsif (r_din = ASCII_BSLASH) then
              r_note_t <= X"0" & NOTE_BSLASH;
            elsif (r_din = ASCII_LF) then
              r_note_valid <= '1';
              c_seq <= TSEQ_NOTE_END;
--            else
--              r_note_valid <= '0';
            end if;
          end if;

        when TSEQ_WAIT_FOR_CTRL_LF =>
          --r_dash_t <= '0';
          --r_dash_w <= '0';
          --r_dash_b <= '0';
          --r_dash_error <= '0';
          if (r_din_valid = '1') then
            if (r_din = ASCII_LF) then
              c_seq <= TSEQ_WAIT_FOR_FIRST_CHAR;

              case r_dash_dat is
                when "011" =>
                  r_dash_b <= '1';
                when "010" =>
                  r_dash_w <= '1';
                when "001" =>
                  r_dash_t <= '1';
                when others =>
                  r_dash_error <= '1';
              end case;

            else
              r_dash_t <= '0';
              r_dash_w <= '0';
              r_dash_b <= '0';
              r_dash_error <= '0';
            end if;
          else
            r_dash_t <= '0';
            r_dash_w <= '0';
            r_dash_b <= '0';
            r_dash_error <= '0';
          end if;

        when TSEQ_WAIT_FOR_CTRL_CHAR =>
          if (r_din_valid = '1') then
            case r_din is
              when ASCII_B =>
                --r_dash_b <= '1';
                r_dash_dat <= "011";
              when ASCII_W =>
                --r_dash_w <= '1';
                r_dash_dat <= "010";
              when ASCII_T =>
                --r_dash_t <= '1';
                r_dash_dat <= "001";
              when others =>
                --r_dash_t <= '0';
                --r_dash_w <= '0';
                --r_dash_b <= '0';
                --r_dash_error <= '1';
                r_dash_dat <= "100";
            end case;
            c_seq <= TSEQ_WAIT_FOR_CTRL_LF;
          end if;

        when TSEQ_WAIT_FOR_FIRST_CHAR =>
          if (r_din_valid = '1') then
            if (r_din = ASCII_DASH) then
              c_seq <= TSEQ_WAIT_FOR_CTRL_CHAR;
            elsif ((r_din >= ASCII_A) and (r_din <= ASCII_Z)) then
              c_seq <= TSEQ_WAIT_FOR_NOTE_STR;
              r_note_x <= conv_integer(r_din) - conv_integer(ASCII_A) + 1; -- first data
            elsif (r_din = ASCII_AT) then
              c_seq <= TSEQ_WAIT_FOR_NOTE_STR;
              r_note_x <= 0; -- first data
            end if;
          end if;

          r_dash_t <= '0';
          r_dash_w <= '0';
          r_dash_b <= '0';
          r_dash_error <= '0';
          r_dash_dat <= "000";

          r_note_y <= 0;
          r_note_valid <= '0';

        when others =>
          c_seq <= TSEQ_WAIT_FOR_FIRST_CHAR;
          r_dash_t <= '0';
          r_dash_w <= '0';
          r_dash_b <= '0';
          r_dash_error <= '0';
          r_dash_dat <= "000";
          r_note_x <= 0;
          r_note_y <= 0;
          r_note_t <= (others => '0');
          r_note_valid <= '0';

      end case;
    end if;
  end if;
end process;

Dash_T     <= r_dash_t;
Dash_W     <= r_dash_w;
Dash_B     <= r_dash_b;
Dash_Error <= r_dash_error;

Note_x <= conv_std_logic_vector(r_note_x, 32);
Note_y <= conv_std_logic_vector(r_note_y, 32);
Note_t <= r_note_t;
Note_v <= r_note_valid;

end rtl;

--------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity traxif_tx is
  port (
    Clk        : in std_logic;
    Rst        : in std_logic;

    Dout       : out std_logic_vector(7 downto 0);
    Dout_valid : out std_logic;

    Pid        : in std_logic_vector(15 downto 0); -- Player ID
    Pid_v      : in std_logic;

    Note_x     : in std_logic_vector(31 downto 0);
    Note_y     : in std_logic_vector(31 downto 0);
    Note_t     : in std_logic_vector(7 downto 0);
    Note_v     : in std_logic
  );
end traxif_tx;

architecture rtl of traxif_tx is

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

  component mish_div
    port (
      Reset      : in std_logic;
      Clock      : in std_logic;

      Dividend   : in std_logic_vector(31 downto 0);
      Divisor    : in std_logic_vector(31 downto 0);
      Din_valid  : in std_logic;

      Quotient   : out std_logic_vector(31 downto 0);
      Remainder  : out std_logic_vector(31 downto 0);
      Dout_valid : out std_logic
    );
  end component;

  signal r_pid   : std_logic_vector(15 downto 0);
  signal r_pid_v : std_logic;

  signal s_note_x_quo : std_logic_vector(31 downto 0);
  signal s_note_x_rem : std_logic_vector(31 downto 0);
  signal s_note_x_v   : std_logic;

  signal s_note_y_quo : std_logic_vector(31 downto 0);
  signal s_note_y_rem : std_logic_vector(31 downto 0);
  signal s_note_y_v   : std_logic;

  signal r_note_x_quo : std_logic_vector(31 downto 0);
  signal r_note_x_rem : std_logic_vector(31 downto 0);
  signal r_note_x_v   : std_logic;

  signal r_note_y_quo : std_logic_vector(31 downto 0);
  signal r_note_y_rem : std_logic_vector(31 downto 0);
  signal r_note_y_v   : std_logic;

  signal r_note_t : std_logic_vector(7 downto 0);

  type T_SEQ is (
    TSEQ_WAIT,

    TSEQ_PID_REQ,
    TSEQ_PID_SEND_U,
    TSEQ_PID_WAIT_U,
    TSEQ_PID_SEND_L,
    TSEQ_PID_WAIT_L,
    TSEQ_PID_SEND_LF,
    TSEQ_PID_WAIT_LF,

    TSEQ_NOTE_REQ,
    TSEQ_NOTE_READY,
    TSEQ_NOTE_X_SEND_U,
    TSEQ_NOTE_X_SEND_L,
    TSEQ_NOTE_Y_SEND_U,
    TSEQ_NOTE_Y_SEND_L,
    TSEQ_NOTE_T_SEND,
    TSEQ_NOTE_SEND_LF,
    TSEQ_NOTE_WAIT_LF
  );
  signal c_seq : T_SEQ;

  signal r_dout       : std_logic_vector(7 downto 0);
  signal r_dout_valid : std_logic;

begin

  pid_in_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Pid_v = '1') then
        r_pid <= Pid;
      end if;
      r_pid_v <= Pid_v;
    end if;
  end process;

  note_x_div: mish_div
    port map (
      Reset      => Rst,
      Clock      => Clk,

      Dividend   => Note_x,
      Divisor    => conv_std_logic_vector(27, 32),
      Din_valid  => Note_v,

      Quotient   => s_note_x_quo,
      Remainder  => s_note_x_rem,
      Dout_valid => s_note_x_v
    );

  note_y_div: mish_div
    port map (
      Reset      => Rst,
      Clock      => Clk,

      Dividend   => Note_y,
      Divisor    => conv_std_logic_vector(10, 32),
      Din_valid  => Note_v,

      Quotient   => s_note_y_quo,
      Remainder  => s_note_y_rem,
      Dout_valid => s_note_y_v
    );

  note_reg_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (s_note_x_v = '1') then
        r_note_x_quo <= s_note_x_quo;
        r_note_x_rem <= s_note_x_rem;
      end if;
      r_note_x_v <= s_note_x_v;
      if (s_note_y_v = '1') then
        r_note_y_quo <= s_note_y_quo;
        r_note_y_rem <= s_note_y_rem;
      end if;
      r_note_y_v <= s_note_y_v;

      if (Note_v = '1') then
        r_note_t <= Note_t;
      end if;
    end if;
  end process;


  transmit_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Rst = '1') then
        c_seq <= TSEQ_WAIT;
        r_dout_valid <= '0';
      else
        case c_seq is

          when TSEQ_NOTE_WAIT_LF =>
            c_seq <= TSEQ_WAIT;
            r_dout <= (others => '0');
            r_dout_valid <= '0';

          when TSEQ_NOTE_SEND_LF =>
            c_seq <= TSEQ_PID_WAIT_LF;
            r_dout <= ASCII_LF;
            r_dout_valid <= '1';

          when TSEQ_NOTE_T_SEND =>
            case r_note_t is
              when NOTE_BSLASH =>
                r_dout <= ASCII_BSLASH;
              when NOTE_SLASH =>
                r_dout <= ASCII_SLASH;
              when NOTE_PLUS =>
                r_dout <= ASCII_PLUS;
              when others =>
                r_dout <= (others => '0');
            end case;
            r_dout_valid <= '1';
            c_seq <= TSEQ_NOTE_SEND_LF;

          when TSEQ_NOTE_Y_SEND_L =>
            r_dout <= ASCII_0 + r_note_y_rem(7 downto 0);
            r_dout_valid <= '1';
            c_seq <= TSEQ_NOTE_T_SEND;

          when TSEQ_NOTE_Y_SEND_U =>
            if (r_note_y_quo /= conv_std_logic_vector(0, 32)) then
              r_dout <= ASCII_0 + r_note_y_quo(7 downto 0);
              r_dout_valid <= '1';
            else
              r_dout_valid <= '0';
            end if;
            c_seq <= TSEQ_NOTE_Y_SEND_L;

          when TSEQ_NOTE_X_SEND_L =>
            if (r_note_x_quo = conv_std_logic_vector(0, 32)) then
              if (r_note_x_rem = conv_std_logic_vector(0, 32)) then
                r_dout <= ASCII_AT;
              else
                r_dout <= ASCII_A + r_note_x_rem(7 downto 0) - 1;
              end if;
            else
              r_dout <= ASCII_A + r_note_x_rem(7 downto 0);
            end if;
            r_dout_valid <= '1';
            c_seq <= TSEQ_NOTE_Y_SEND_U;

          when TSEQ_NOTE_X_SEND_U =>
            if (r_note_x_quo /= conv_std_logic_vector(0, 32)) then
              r_dout <= ASCII_A + r_note_x_quo(7 downto 0) - 1;
              r_dout_valid <= '1';
            else
              r_dout_valid <= '0';
            end if;
            c_seq <= TSEQ_NOTE_X_SEND_L;

          when TSEQ_NOTE_READY =>
            c_seq <= TSEQ_NOTE_X_SEND_U;
            r_dout <= (others => '0');
            r_dout_valid <= '0';

          when TSEQ_NOTE_REQ =>
            -- waiting for both divider
            if ((r_note_x_v = '1') or (r_note_y_v = '1')) then
              c_seq <= TSEQ_NOTE_READY;
            end if;
            r_dout <= (others => '0');
            r_dout_valid <= '0';

          -- PID - Player ID -------------------------------------------------

          when TSEQ_PID_WAIT_LF =>
            c_seq <= TSEQ_WAIT;
            r_dout <= (others => '0');
            r_dout_valid <= '0';

          when TSEQ_PID_SEND_LF =>
            c_seq <= TSEQ_PID_WAIT_LF;
            r_dout <= ASCII_LF;
            r_dout_valid <= '1';

          when TSEQ_PID_WAIT_L =>
            c_seq <= TSEQ_PID_SEND_LF;
            r_dout <= (others => '0');
            r_dout_valid <= '0';

          when TSEQ_PID_SEND_L =>
            c_seq <= TSEQ_PID_WAIT_L;
            r_dout <= r_pid(7 downto 0);
            r_dout_valid <= '1';

          when TSEQ_PID_WAIT_U =>
            c_seq <= TSEQ_PID_SEND_L;
            r_dout <= (others => '0');
            r_dout_valid <= '0';

          when TSEQ_PID_SEND_U =>
            c_seq <= TSEQ_PID_WAIT_U;
            r_dout <= r_pid(15 downto 8);
            r_dout_valid <= '1';

          when TSEQ_PID_REQ =>
            c_seq <= TSEQ_PID_SEND_U;
            r_dout_valid <= '0';

          --------------------------------------------------------------------

          when TSEQ_WAIT =>
            if (r_pid_v = '1') then
              c_seq <= TSEQ_PID_REQ;
            elsif ((r_note_x_v = '1') and (r_note_y_v = '1')) then
              c_seq <= TSEQ_NOTE_READY;
            elsif ((r_note_x_v = '1') or (r_note_y_v = '1')) then
              c_seq <= TSEQ_NOTE_REQ;
            end if;
            r_dout_valid <= '0';
          when others =>
            c_seq <= TSEQ_WAIT;
            r_dout_valid <= '0';
        end case;
      end if;
    end if;
  end process;

  Dout <= r_dout;
  Dout_valid <= r_dout_valid;


end rtl;

------------------------------------------------------------------------------

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sim_traxif_rx is
end sim_traxif_rx;

architecture sim of sim_traxif_rx is

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

  component traxif_rx
    port (
      Clk        : in std_logic;
      Rst        : in std_logic;

      Din        : in std_logic_vector(7 downto 0);
      Din_valid  : in std_logic;

      Dash_T     : out std_logic;
      Dash_W     : out std_logic;
      Dash_B     : out std_logic;
      Dash_Error : out std_logic;

      Note_x     : out std_logic_vector(31 downto 0); -- X
      Note_y     : out std_logic_vector(31 downto 0); -- Y
      Note_t     : out std_logic_vector(7 downto 0);  -- Type
      Note_v     : out std_logic                      -- Valid
    );
  end component;

  signal clk : std_logic;
  signal rst : std_logic;

  signal din : std_logic_vector(7 downto 0);
  signal din_valid : std_logic;

  signal dash_t : std_logic;
  signal dash_w : std_logic;
  signal dash_b : std_logic;
  signal dash_error : std_logic;

  signal note_x : std_logic_vector(31 downto 0);
  signal note_y : std_logic_vector(31 downto 0);
  signal note_t : std_logic_vector(7 downto 0);
  signal note_v : std_logic;

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

  uut: traxif_rx
    port map (
      Clk        => clk,
      Rst        => rst,

      Din        => din,
      Din_valid  => din_valid,

      Dash_T     => dash_t,
      Dash_W     => dash_w,
      Dash_B     => dash_b,
      Dash_Error => dash_error,

      Note_x     => note_x,
      Note_y     => note_y,
      Note_t     => note_t,
      Note_v     => note_v
    );

  test_proc: process
  begin
    din <= (others => '0');
    din_valid <= '0';

    wait for CLK_CYCLE*10;

    -- dash T

    din <= ASCII_DASH;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_T;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    -- dash W

    din <= ASCII_DASH;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_W;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    -- dash B

    din <= ASCII_DASH;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_B;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    -- @0+

    din <= ASCII_AT;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_0;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_PLUS;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    -- @0/

    din <= ASCII_AT;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_0;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_SLASH;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    -- @0\

    din <= ASCII_AT;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_0;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_BSLASH;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    -- A1+

    din <= ASCII_A;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_0 + X"01";
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_PLUS;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    -- Z9+

    din <= ASCII_Z;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_0 + X"09";
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_PLUS;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    -- AA10+

    din <= ASCII_A;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_A;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_0 + X"01";
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_0 + X"00";
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_PLUS;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;







    wait;
  end process;

end sim;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sim_traxif_tx is
end sim_traxif_tx;

architecture sim of sim_traxif_tx is

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

  component traxif_tx
    port (
      Clk        : in std_logic;
      Rst        : in std_logic;

      Dout       : out std_logic_vector(7 downto 0);
      Dout_valid : out std_logic;

      Pid        : in std_logic_vector(15 downto 0); -- Player ID
      Pid_v      : in std_logic;

      Note_x     : in std_logic_vector(31 downto 0);
      Note_y     : in std_logic_vector(31 downto 0);
      Note_t     : in std_logic_vector(7 downto 0);
      Note_v     : in std_logic
    );
  end component;

  signal clk : std_logic;
  signal rst : std_logic;

  signal dout : std_logic_vector(7 downto 0);
  signal dout_valid : std_logic;

  signal pid : std_logic_vector(15 downto 0);
  signal pid_v : std_logic;

  signal note_x : std_logic_vector(31 downto 0);
  signal note_y : std_logic_vector(31 downto 0);
  signal note_t : std_logic_vector(7 downto 0);
  signal note_v : std_logic;

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

  uut: traxif_tx
    port map (
      Clk => clk,
      Rst => rst,

      Dout => dout,
      Dout_valid => dout_valid,

      Pid => pid,
      Pid_v => pid_v,

      Note_x => note_x,
      Note_y => note_y,
      Note_t => note_t,
      Note_v => note_v
    );

  pid <= X"4D54";

  process
  begin
    pid_v <= '0';
    note_x <= conv_std_logic_vector(0, 32);
    note_y <= conv_std_logic_vector(0, 32);
    note_t <= X"00";
    note_v <= '0';

    wait for CLK_CYCLE*10;

    -- PID

    pid_v <= '1';
    wait for CLK_CYCLE;
    pid_v <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;
    note_x <= conv_std_logic_vector(0, 32);
    note_y <= conv_std_logic_vector(0, 32);
    note_t <= X"00";
    note_v <= '1';

    wait for CLK_CYCLE;
    note_x <= conv_std_logic_vector(0, 32);
    note_y <= conv_std_logic_vector(0, 32);
    note_t <= X"00";
    note_v <= '0';







    wait;
  end process;

end sim;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sim_traxif is
end sim_traxif;

architecture sim of sim_traxif is

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

  component traxif_rx
    port (
      Clk        : in std_logic;
      Rst        : in std_logic;

      Din        : in std_logic_vector(7 downto 0);
      Din_valid  : in std_logic;

      Dash_T     : out std_logic;
      Dash_W     : out std_logic;
      Dash_B     : out std_logic;
      Dash_Error : out std_logic;

      Note_x     : out std_logic_vector(31 downto 0); -- X
      Note_y     : out std_logic_vector(31 downto 0); -- Y
      Note_t     : out std_logic_vector(7 downto 0);  -- Type
      Note_v     : out std_logic                      -- Valid
    );
  end component;

  component traxif_tx
    port (
      Clk        : in std_logic;
      Rst        : in std_logic;

      Dout       : out std_logic_vector(7 downto 0);
      Dout_valid : out std_logic;

      Pid        : in std_logic_vector(15 downto 0); -- Player ID
      Pid_v      : in std_logic;

      Note_x     : in std_logic_vector(31 downto 0);
      Note_y     : in std_logic_vector(31 downto 0);
      Note_t     : in std_logic_vector(7 downto 0);
      Note_v     : in std_logic
    );
  end component;

  signal clk : std_logic;
  signal rst : std_logic;

  signal din : std_logic_vector(7 downto 0);
  signal din_valid : std_logic;

  signal dash_t : std_logic;
  signal dash_w : std_logic;
  signal dash_b : std_logic;
  signal dash_error : std_logic;

  signal note_x : std_logic_vector(31 downto 0);
  signal note_y : std_logic_vector(31 downto 0);
  signal note_t : std_logic_vector(7 downto 0);
  signal note_v : std_logic;


  signal dout : std_logic_vector(7 downto 0);
  signal dout_valid : std_logic;

  signal pid : std_logic_vector(15 downto 0);
  signal pid_v : std_logic;

  signal note_x_t : std_logic_vector(31 downto 0);
  signal note_y_t : std_logic_vector(31 downto 0);
  signal note_t_t : std_logic_vector(7 downto 0);
  signal note_v_t : std_logic;

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

  uut_rx: traxif_rx
    port map (
      Clk        => clk,
      Rst        => rst,

      Din        => din,
      Din_valid  => din_valid,

      Dash_T     => dash_t,
      Dash_W     => dash_w,
      Dash_B     => dash_b,
      Dash_Error => dash_error,

      Note_x     => note_x,
      Note_y     => note_y,
      Note_t     => note_t,
      Note_v     => note_v
    );

  test_proc: process
  begin
    din <= (others => '0');
    din_valid <= '0';

    wait for CLK_CYCLE*10;

    -- dash T

    din <= ASCII_DASH;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_T;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    -- dash W

    din <= ASCII_DASH;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_W;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    -- dash B

    din <= ASCII_DASH;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_B;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    -- @0+

    din <= ASCII_AT;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_0;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_PLUS;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*40;

    -- @0/

    din <= ASCII_AT;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_0;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_SLASH;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*40;

    -- @0\

    din <= ASCII_AT;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_0;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_BSLASH;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*40;

    -- A1+

    din <= ASCII_A;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_0 + X"01";
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_PLUS;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*40;

    -- Z9+

    din <= ASCII_Z;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_0 + X"09";
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_PLUS;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*40;

    -- AA10+

    din <= ASCII_A;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_A;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_0 + X"01";
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_0 + X"00";
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_PLUS;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*10;

    din <= ASCII_LF;
    din_valid <= '1';
    wait for CLK_CYCLE;
    din <= (others => '0');
    din_valid <= '0';
    wait for CLK_CYCLE;

    wait for CLK_CYCLE*40;







    wait;
  end process;

  uut_tx: traxif_tx
    port map (
      Clk        => clk,
      Rst        => rst,

      Dout       => dout,
      Dout_valid => dout_valid,

      Pid        => pid,
      Pid_v      => pid_v,

      Note_x     => note_x,
      Note_y     => note_y,
      Note_t     => note_t,
      Note_v     => note_v
    );

  pid <= X"4D54";

  process
  begin
    pid_v <= '0';
    --note_x <= conv_std_logic_vector(0, 32);
    --note_y <= conv_std_logic_vector(0, 32);
    --note_t <= X"00";
    --note_v <= '0';

    wait for CLK_CYCLE*10;

    -- PID

    pid_v <= '1';
    wait for CLK_CYCLE;
    pid_v <= '0';
    wait for CLK_CYCLE;








    wait;
  end process;

end sim;


-- synthesis translate_on

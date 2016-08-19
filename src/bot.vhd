library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity bot is
  port (
    Clk        : in std_logic;
    Rst        : in std_logic;

    Init_done  : in std_logic;
    Im_first   : in std_logic;

    Din        : in std_logic_vector(7 downto 0);
    Din_valid  : in std_logic;

    Dout       : out std_logic_vector(7 downto 0);
    Dout_valid : out std_logic
  );
end bot;

architecture rtl of bot is

  constant ASCII_AT : std_logic_vector(7 downto 0) := X"40"; -- @
  constant ASCII_0  : std_logic_vector(7 downto 0) := X"30";
  constant ASCII_9  : std_logic_vector(7 downto 0) := X"39";
  constant ASCII_A  : std_logic_vector(7 downto 0) := X"41";
  constant ASCII_Z  : std_logic_vector(7 downto 0) := X"5A";
  constant ASCII_LF : std_logic_vector(7 downto 0) := X"0A";
  constant ASCII_PS : std_logic_vector(7 downto 0) := X"2B"; -- +
  constant ASCII_SL : std_logic_vector(7 downto 0) := X"2F"; -- /
  constant AScII_BS : std_logic_vector(7 downto 0) := X"5C"; -- \

  signal r_data_0  : std_logic_vector(7 downto 0);
  signal r_valid_0 : std_logic;

  signal r_received_x        : integer;
  signal r_received_y        : integer;
  signal r_received_tile     : std_logic_vector(7 downto 0);
  signal r_received_xy_valid : std_logic;

  signal r_x : std_logic_vector(31 downto 0);
  signal r_y : std_logic_vector(31 downto 0);
  signal r_t : std_logic_vector(7 downto 0);
  signal r_v : std_logic;


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

  signal s_prbs_d       : std_logic_vector(15 downto 0);
  signal s_prbs_d_valid : std_logic;

  signal c_random_out     : std_logic_vector(2 downto 0);
  signal r_random_d       : std_logic_vector(7 downto 0);
  signal r_random_d_valid : std_logic;






  COMPONENT vio_receivedata
    PORT (
      clk : IN STD_LOGIC;
      probe_in0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      probe_in1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      probe_in2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
  END COMPONENT;

  COMPONENT vio_botctrl
    PORT (
      clk : IN STD_LOGIC;
      probe_in0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      probe_out0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
  END COMPONENT;

  signal s_vio_botctrl_trigger : std_logic_vector(0 downto 0);
  signal s_vio_botctrl_turn    : std_logic_vector(7 downto 0);

  signal c_turn : std_logic_vector(7 downto 0);
  signal r_manual_trigger : std_logic_vector(2 downto 0);

begin

  input_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      r_valid_0 <= Din_valid;
      if (Din_valid = '1') then
        r_data_0 <= Din;
      end if;
    end if;
  end process;


  -- NEED initial output here


  xy_receive_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if ((Rst = '1') or (Init_done = '0')) then
        r_received_x <= 0;
        r_received_y <= 0;
        r_received_xy_valid <= '0';

        r_x <= (others => '0');
        r_y <= (others => '0');
      else
        if (r_valid_0 = '1') then
          if (r_data_0 = ASCII_LF) then
            r_received_xy_valid <= '1';
          elsif (r_data_0 = ASCII_AT) then
            r_received_x <= 0;
            r_received_xy_valid <= '0';
          elsif ((r_data_0 >= ASCII_A) and (r_data_0 <= ASCII_Z)) then
            r_received_x <= (r_received_x * 26) + conv_integer(r_data_0) - conv_integer(ASCII_A) + 1;
            r_received_xy_valid <= '0';
          elsif ((r_data_0 >= ASCII_0) and (r_data_0 <= ASCII_9)) then
            r_received_y <= (r_received_y * 10) + conv_integer(r_data_0) - conv_integer(ASCII_0);
            r_received_xy_valid <= '0';
          elsif ((r_data_0 = ASCII_PS) or (r_data_0 = ASCII_SL) or (r_data_0 = AScII_BS)) then
            r_received_tile <= r_data_0;
            r_received_xy_valid <= '0';
          else
            r_received_xy_valid <= '0';
          end if;
        else
          r_received_xy_valid <= '0';
        end if;

        if (r_received_xy_valid = '1') then
          r_x <= conv_std_logic_vector(r_received_x, 32);
          r_y <= conv_std_logic_vector(r_received_y, 32);
          r_t <= r_received_tile;
        end if;
        r_v <= r_received_xy_valid;
      end if;
    end if;
  end process;

  i_vio_receivedata : vio_receivedata
    PORT MAP (
      clk       => Clk,
      probe_in0 => r_x,
      probe_in1 => r_y,
      probe_in2 => r_t
    );


  -- generate random number
  i_prbs: mish_prbs15p16
    port map (
      RESET => Rst,
      CLK   => Clk,

      CLR   => '0',
      ENA   => '1',

      DOUT  => s_prbs_d,
      VOUT  => s_prbs_d_valid
    );

  random_seq_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Init_done = '0') then
        c_random_out <= "000";
      elsif ((r_v = '1') or (r_manual_trigger(2) = '1')) then
        c_random_out <= "001";
      else
        case c_random_out is
          when "101" =>
            r_random_d <= ASCII_LF;
            r_random_d_valid <= '1';
            c_random_out <= "110";
          when "100" =>
            r_random_d <= (others => '0');
            r_random_d_valid <= '0';
            c_random_out <= "101";
          when "011" =>
            if (s_prbs_d_valid = '1') then
              case s_prbs_d(1 downto 0) is
                when "00" =>
                  r_random_d <= ASCII_PS;
                when "01" =>
                  r_random_d <= ASCII_SL;
                when others =>
                  r_random_d <= AScII_BS;
              end case;
              r_random_d_valid <= '1';
              c_random_out <= "100";
            else
              r_random_d_valid <= '0';
            end if;
          when "010" =>
            if (s_prbs_d_valid = '1') then
              r_random_d <= ("00000" & s_prbs_d(2 downto 0)) + ASCII_0;
              r_random_d_valid <= '1';
              c_random_out <= "011";
            else
              r_random_d_valid <= '0';
            end if;
          when "001" =>
            if (s_prbs_d_valid = '1') then
              r_random_d <= ("0000" & s_prbs_d(3 downto 0)) + ASCII_A;
              r_random_d_valid <= '1';
              c_random_out <= "010";
            else
              r_random_d_valid <= '0';
            end if;
          when others =>
            r_random_d <= (others => '0');
            r_random_d_valid <= '0';
        end case;
      end if;


    end if;
  end process;


  turn_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      if (Init_done = '0') then
        c_turn <= (others => '0');
      elsif ((r_v = '1') or ((c_random_out = "101") and (r_random_d_valid = '1'))) then
        c_turn <= c_turn + 1;
      end if;
    end if;
  end process;

  s_vio_botctrl_turn <= c_turn;

  i_vio_botctrl : vio_botctrl
    PORT MAP (
      clk        => Clk,
      probe_in0  => s_vio_botctrl_turn,
      probe_out0 => s_vio_botctrl_trigger
    );

  manual_trigger_proc: process(Clk)
  begin
    if (rising_edge(Clk)) then
      r_manual_trigger(1 downto 0) <= r_manual_trigger(0) & s_vio_botctrl_trigger(0);
      r_manual_trigger(2) <= (not r_manual_trigger(1)) and r_manual_trigger(0);
    end if;
  end process;





  Dout <= r_random_d;
  Dout_valid <= r_random_d_valid;















end rtl;

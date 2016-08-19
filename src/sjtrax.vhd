--
--
--
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
Library UNISIM;
use UNISIM.vcomponents.all;

entity sjtrax is
  port (
    CPU_RESET : in std_logic;

    SYSCLK_P : in std_logic;
    SYSCLK_N : in std_logic;

    USB_UART_RX : in std_logic;
    USB_UART_RTS : out std_logic;
    USB_UART_TX : out std_logic;
    USB_UART_CTS : in std_logic;

    GPIO_LED_0_LS : out std_logic;
    GPIO_LED_1_LS : out std_logic;
    GPIO_LED_2_LS : out std_logic;
    GPIO_LED_3_LS : out std_logic;
    GPIO_LED_4_LS : out std_logic;
    GPIO_LED_7_LS : out std_logic
  );
end sjtrax;

architecture rtl of sjtrax is

  constant USE_UART_MONITOR  : boolean := false;
  constant USE_VIO           : boolean := false;
  constant USE_NOTES_MONITOR : boolean := true;

  signal s_sysclk_tmp : std_logic;
  signal s_sysclk : std_logic;

  component uart_semi_abaud
    port (
      RESET     : in std_logic;
      CLK       : in std_logic;

      UART_RXD  : in std_logic; -- require already synchronized signal

      LEN       : out std_logic_vector(31 downto 0);
      LEN_VALID : out std_logic
    );
  end component;

  component uart_tx
    port (
      RESET      : in std_logic;
      CLK        : in std_logic;

      LEN        : in std_logic_vector(31 downto 0);
      LEN_VALID  : in std_logic;

      FIFO_RD_EN : out std_logic;
      FIFO_DOUT  : in std_logic_vector(7 downto 0);
      FIFO_EMPTY : in std_logic;
      FIFO_VALID : in std_logic;

      UART_CTS   : in std_logic;  -- clear to send
      UART_TXD   : out std_logic
    );
  end component;

  component uart_rx
    port (
      RESET     : in std_logic;
      CLK       : in std_logic;

      RXD2ABAUD : out std_logic;

      LEN       : in std_logic_vector(31 downto 0);
      LEN_VALID : in std_logic;

      -- connect to FIFO
      FIFO_DIN   : out std_logic_vector(7 downto 0);
      FIFO_WR_EN : out std_logic;
      FIFO_FULL  : in std_logic;

      UART_RTS  : out std_logic; -- ready to send
      UART_RXD  : in std_logic;

      MON       : out std_logic_vector(7 downto 0)
    );
  end component;

  COMPONENT uart_tx_fifo
    PORT (
      clk : IN STD_LOGIC;
      rst : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      full : OUT STD_LOGIC;
      empty : OUT STD_LOGIC;
      valid : OUT STD_LOGIC
    );
  END COMPONENT;

  signal s_uart_rxd2abaud : std_logic;

  signal s_uart_len       : std_logic_vector(31 downto 0);
  signal s_uart_len_valid : std_logic;

  signal s_uart_rx_d       : std_logic_vector(7 downto 0);
  signal s_uart_rx_d_valid : std_logic;

  signal s_uart_tx_fifo_rd_en : std_logic;
  signal s_uart_tx_fifo_d     : std_logic_vector(7 downto 0);
  signal s_uart_tx_fifo_full  : std_logic;
  signal s_uart_tx_fifo_empty : std_logic;
  signal s_uart_tx_fifo_valid : std_logic;

  signal s_uart_tx_d       : std_logic_vector(7 downto 0);
  signal s_uart_tx_d_valid : std_logic;

  signal s_uart_tx_d_vio       : std_logic_vector(7 downto 0);
  signal s_uart_tx_d_valid_vio : std_logic;

  signal s_uart_rts : std_logic;
  signal s_uart_tx  : std_logic;

  signal s_init_got_init  : std_logic;
  signal s_init_im_first  : std_logic;
  signal s_init_init_done : std_logic;

  signal s_bot_d       : std_logic_vector(7 downto 0);
  signal s_bot_d_valid : std_logic;

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

  signal s_dash_t : std_logic;
  signal s_dash_w : std_logic;
  signal s_dash_b : std_logic;
  signal s_dash_e : std_logic;

  signal s_note_rx_x : std_logic_vector(31 downto 0);
  signal s_note_rx_y : std_logic_vector(31 downto 0);
  signal s_note_rx_t : std_logic_vector(7 downto 0);
  signal s_note_rx_v : std_logic;

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

  signal s_pid   : std_logic_vector(15 downto 0);
  signal s_pid_v : std_logic;

  signal s_note_tx_x : std_logic_vector(31 downto 0);
  signal s_note_tx_y : std_logic_vector(31 downto 0);
  signal s_note_tx_t : std_logic_vector(7 downto 0);
  signal s_note_tx_v : std_logic;

  component bot2
    generic (
      PLAYER_ID : std_logic_vector(15 downto 0) := X"5247" -- RG
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
  end component;










  component tx_led
    generic (
      LIT_CYCLES : integer := 50000000
    );
    port (
      Clk : in std_logic;
      Rst : in std_logic;

      Src : in std_logic;
      Led : out std_logic
    );
  end component;

  signal s_tx_led : std_logic;
  signal s_rx_led : std_logic;



  COMPONENT vio_uart
    PORT (
      clk : IN STD_LOGIC;
      probe_in0 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
      probe_in1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      probe_out0 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
    );
  END COMPONENT;

  signal s_vio_uart_probe_in0  : std_logic_vector(8 downto 0);
  signal s_vio_uart_probe_out0 : std_logic_vector(8 downto 0);

  signal r_uart_tx_valid       : std_logic_vector(2 downto 0);

  signal s_init_mon : std_logic_vector(7 downto 0);



  component uartmon
    port (
      Clk      : in std_logic;
      Rst      : in std_logic;

      Rx_din   : in std_logic_vector(7 downto 0);
      Rx_din_v : in std_logic;

      Tx_din   : in std_logic_vector(7 downto 0);
      Tx_din_v : in std_logic;

      Other_data : in std_logic_vector(55 downto 0)
    );
  end component;

  signal s_uartmon_others : std_logic_vector(55 downto 0);



  COMPONENT ila_notes
    PORT (
      clk : IN STD_LOGIC;
      trig_in : IN STD_LOGIC;
      trig_in_ack : OUT STD_LOGIC;
      probe0 : IN STD_LOGIC_VECTOR(49 DOWNTO 0)
    );
  END COMPONENT  ;

  signal s_notesmon_trig   : std_logic;
  signal s_notesmon_probe0 : std_logic_vector(49 downto 0);



  signal s_trying : std_logic;
  signal s_trying_led : std_logic;

begin ------------------------------------------------------------------------

i_sysclk_bufds: IBUFDS
  port map (
    I => SYSCLK_P,
    IB => SYSCLK_N,
    O => s_sysclk_tmp
  );

i_sysclk_bufg: BUFG
  port map (
    I => s_sysclk_tmp,
    O => s_sysclk
  );

s_uart_len <= conv_std_logic_vector(10407, 32); -- 19200 baud
--s_uart_len <= conv_std_logic_vector(8199, 32); -- 19200 baud
s_uart_len_valid <= '1';

i_uart_rx: uart_rx
  port map (
    RESET      => CPU_RESET,
    CLK        => s_sysclk,

    RXD2ABAUD  => s_uart_rxd2abaud,

    LEN        => s_uart_len,
    LEN_VALID  => s_uart_len_valid,

    FIFO_DIN   => s_uart_rx_d,
    FIFO_WR_EN => s_uart_rx_d_valid,
    FIFO_FULL  => '0',

    UART_RTS   => s_uart_rts,
    UART_RXD   => USB_UART_RX,

    MON        => open
  );

USB_UART_RTS <= s_uart_rts;

i_uart_tx: uart_tx
  port map (
    RESET      => CPU_RESET,
    CLK        => s_sysclk,

    LEN        => s_uart_len,
    LEN_VALID  => s_uart_len_valid,

    FIFO_RD_EN => s_uart_tx_fifo_rd_en,
    FIFO_DOUT  => s_uart_tx_fifo_d,
    FIFO_EMPTY => s_uart_tx_fifo_empty,
    FIFO_VALID => s_uart_tx_fifo_valid,

    UART_CTS   => '1',
    UART_TXD   => s_uart_tx
  );

i_uart_tx_fifo: uart_tx_fifo
  port map (
    clk   => s_sysclk,
    rst   => CPU_RESET,
    din   => s_uart_tx_d,
    wr_en => s_uart_tx_d_valid,
    rd_en => s_uart_tx_fifo_rd_en,
    dout  => s_uart_tx_fifo_d,
    full  => s_uart_tx_fifo_full,
    empty => s_uart_tx_fifo_empty,
    valid => s_uart_tx_fifo_valid
  );


USB_UART_TX <= s_uart_tx;


s_uart_tx_d       <= s_uart_tx_d_vio or s_bot_d;
s_uart_tx_d_valid <= s_uart_tx_d_valid_vio or s_bot_d_valid;


uartmon_gen: if (USE_UART_MONITOR = true) generate

  i_uartmon: uartmon
    port map (
      Clk => s_sysclk,
      Rst => CPU_RESET,

      Rx_din => s_uart_rx_d,
      Rx_din_v => s_uart_rx_d_valid,

      Tx_din => s_uart_tx_d,
      Tx_din_v => s_uart_tx_d_valid,

      Other_data => s_uartmon_others
    );

  s_uartmon_others <= s_note_rx_v & s_note_rx_t(3 downto 0) & s_note_rx_y(7 downto 0) & s_note_rx_x(7 downto 0)
                    & s_note_tx_v & s_note_tx_t(3 downto 0) & s_note_tx_y(7 downto 0) & s_note_tx_x(7 downto 0)
                    & X"00" & "00" & s_dash_e & s_dash_b & s_dash_w & s_dash_t;

end generate;





i_traxif_rx: traxif_rx
  port map (
    Clk        => s_sysclk,
    Rst        => CPU_RESET,

    Din        => s_uart_rx_d,
    Din_valid  => s_uart_rx_d_valid,

    Dash_T     => s_dash_t,
    Dash_W     => s_dash_w,
    Dash_B     => s_dash_b,
    Dash_Error => s_dash_e,

    Note_x     => s_note_rx_x,
    Note_y     => s_note_rx_y,
    Note_t     => s_note_rx_t,
    Note_v     => s_note_rx_v
  );

i_traxif_tx: traxif_tx
  port map (
    Clk        => s_sysclk,
    Rst        => CPU_RESET,

    Dout       => s_bot_d,
    Dout_valid => s_bot_d_valid,

    Pid        => s_pid,
    Pid_v      => s_pid_v,

    Note_x     => s_note_tx_x,
    Note_y     => s_note_tx_y,
    Note_t     => s_note_tx_t,
    Note_v     => s_note_tx_v
  );

i_bot: bot2
  generic map (
    PLAYER_ID => X"5247" -- RG
  )
  port map (
    Clk        => s_sysclk,
    Rst        => CPU_RESET,

    Dash_T     => s_dash_t,
    Dash_W     => s_dash_w,
    Dash_B     => s_dash_b,
    Dash_Error => s_dash_e,

    Pid        => s_pid,
    Pid_v      => s_pid_v,

    Note_rx_x  => s_note_rx_x,
    Note_rx_y  => s_note_rx_y,
    Note_rx_t  => s_note_rx_t,
    Note_rx_v  => s_note_rx_v,

    Note_tx_x  => s_note_tx_x,
    Note_tx_y  => s_note_tx_y,
    Note_tx_t  => s_note_tx_t,
    Note_tx_v  => s_note_tx_v,

    Got_init   => s_init_got_init,
    Im_first   => s_init_im_first,
    Init_done  => s_init_init_done,

    Trying     => s_trying
  );














i_tx_led: tx_led
  generic map (
    LIT_CYCLES => 50000000
  )
  port map (
    Clk => s_sysclk,
    Rst => CPU_RESET,

    Src => s_bot_d_valid,
    Led => s_tx_led
  );

i_rx_led: tx_led
    generic map (
      LIT_CYCLES => 50000000
    )
    port map (
      Clk => s_sysclk,
      Rst => CPU_RESET,

      Src => s_uart_rx_d_valid,
      Led => s_rx_led
    );

i_try_led: tx_led
  generic map (
    LIT_CYCLES => 50000000
  )
  port map (
    Clk => s_sysclk,
    Rst => CPU_RESET,

    Src => s_trying,
    Led => s_trying_led
  );




GPIO_LED_0_LS <= s_init_got_init; -- s_uart_rx_d_valid;
GPIO_LED_1_LS <= s_init_im_first; -- CPU_RESET;
GPIO_LED_2_LS <= s_init_init_done;
GPIO_LED_3_LS <= s_tx_led;
GPIO_LED_4_LS <= s_rx_led;
GPIO_LED_7_LS <= s_trying_led;




-------- VIO --------

viogen: if (USE_VIO = true) generate

  s_vio_uart_probe_in0 <= s_uart_rx_d_valid & s_uart_rx_d;
  s_uart_tx_d_vio      <= s_vio_uart_probe_out0(7 downto 0);

  process(s_sysclk)
  begin
      if (rising_edge(s_sysclk)) then
          r_uart_tx_valid(1 downto 0) <= r_uart_tx_valid(0) & s_vio_uart_probe_out0(8);
          r_uart_tx_valid(2)          <= (not r_uart_tx_valid(1)) and r_uart_tx_valid(0);
      end if;
  end process;

  s_uart_tx_d_valid_vio <= r_uart_tx_valid(2);

  s_init_mon <= (others => '0');

  i_vio_uart : vio_uart
    PORT MAP (
      clk        => s_sysclk,
      probe_in0  => s_vio_uart_probe_in0,
      probe_in1  => s_init_mon,
      probe_out0 => s_vio_uart_probe_out0
    );

end generate;
----------------



notesmongen: if (USE_NOTES_MONITOR = true) generate

  i_notes_mon_ila: ila_notes
    port map (
      clk         => s_sysclk,
      trig_in     => s_notesmon_trig,
      trig_in_ack => open,
      probe0      => s_notesmon_probe0
    );

  s_notesmon_trig   <= s_note_rx_v or s_note_tx_v;
  s_notesmon_probe0 <= s_note_tx_v & s_note_tx_t & s_note_tx_y(7 downto 0) & s_note_tx_x(7 downto 0)
                     & s_note_rx_v & s_note_rx_t & s_note_rx_y(7 downto 0) & s_note_rx_x(7 downto 0);

end generate;

end rtl;

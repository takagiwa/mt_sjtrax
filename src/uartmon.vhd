library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity uartmon is
  port (
    Clk      : in std_logic;
    Rst      : in std_logic;

    Rx_din   : in std_logic_vector(7 downto 0);
    Rx_din_v : in std_logic;

    Tx_din   : in std_logic_vector(7 downto 0);
    Tx_din_v : in std_logic;

    Other_data : in std_logic_vector(55 downto 0)
  );
end uartmon;

architecture rtl of uartmon is

  COMPONENT uartmon_fifo
    PORT (
      clk : IN STD_LOGIC;
      rst : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(73 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(73 DOWNTO 0);
      full : OUT STD_LOGIC;
      empty : OUT STD_LOGIC;
      valid : OUT STD_LOGIC
    );
  END COMPONENT;

  signal r_mon_data   : std_logic_vector(73 downto 0);
  signal s_trigger    : std_logic;
  signal s_mon_rd_en  : std_logic;
  signal s_mon_data   : std_logic_vector(73 downto 0);
  signal s_mon_full   : std_logic;
  signal s_mon_empty  : std_logic;
  signal s_mon_data_v : std_logic;

  COMPONENT vio_uartmon_ctrl
    PORT (
      clk : IN STD_LOGIC;
      probe_in0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe_in1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe_out0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
  END COMPONENT;

  signal s_vio_probe_in0  : std_logic_vector(0 downto 0);
  signal s_vio_probe_in1  : std_logic_vector(0 downto 0);
  signal s_vio_probe_out0 : std_logic_vector(0 downto 0);

  COMPONENT ila_uartmon
  PORT (
  	clk : IN STD_LOGIC;
  	trig_in : IN STD_LOGIC;
  	trig_in_ack : OUT STD_LOGIC;
  	probe0 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
  	probe1 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
  	probe2 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
  	probe3 : IN STD_LOGIC_VECTOR(20 DOWNTO 0);
  	probe4 : IN STD_LOGIC_VECTOR(20 DOWNTO 0)
  );
  END COMPONENT  ;


begin

process(Clk)
begin
  if (rising_edge(Clk)) then
    r_mon_data <= Other_data(55 downto 45)
                & Other_data(44 downto 24)
                & Other_data(23 downto 0)
                & Tx_din_v & Tx_din & Rx_din_v & Rx_din;
  end if;
end process;

s_trigger <= '1' when (r_mon_data(73) = '1')
        else '1' when (r_mon_data(52) = '1')
        else '1' when (r_mon_data(31 downto 18) /= "0000000000000")
        else '1' when (r_mon_data(17) = '1')
        else '1' when (r_mon_data(8) = '1')
        else '0';

i_fifo: uartmon_fifo
  PORT MAP (
    clk   => Clk,
    rst   => Rst,
    din   => r_mon_data,
    wr_en => s_trigger,
    rd_en => s_mon_rd_en,
    dout  => s_mon_data,
    full  => s_mon_full,
    empty => s_mon_empty,
    valid => s_mon_data_v
  );


i_vio: vio_uartmon_ctrl
  port map (
    clk        => Clk,
    probe_in0  => s_vio_probe_in0,
    probe_in1  => s_vio_probe_in1,
    probe_out0 => s_vio_probe_out0
  );

s_vio_probe_in0(0) <= s_mon_empty;
s_vio_probe_in1(0) <= s_mon_full;
s_mon_rd_en <= s_vio_probe_out0(0);

i_ila: ila_uartmon
  port map (
    clk         => Clk,
    trig_in     => s_mon_data_v,
    trig_in_ack => open,
    probe0      => s_mon_data(8 downto 0),
    probe1      => s_mon_data(17 downto 9),
    probe2      => s_mon_data(31 downto 18),
    probe3      => s_mon_data(52 downto 32),
    probe4      => s_mon_data(73 downto 53)
  );


end rtl;

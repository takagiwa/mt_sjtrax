library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity initialcom is
  generic (
    PLAYERID   : in std_logic_vector(15 downto 0) := X"4D54" -- MT
  );
  port (
    Clk        : in std_logic;
    Rst        : in std_logic;

    Din        : in std_logic_vector(7 downto 0);
    Din_valid  : in std_logic;

    Dout       : out std_logic_vector(7 downto 0);
    Dout_valid : out std_logic;

    Got_init   : out std_logic;
    Im_first   : out std_logic;
    Init_done  : out std_logic;

    Mon        : out std_logic_vector(7 downto 0)
  );
end initialcom;

architecture rtl of initialcom is

type T_INITSEQ is (
                TI_WAIT_FOR_DASH_1,
                TI_WAIT_FOR_T,
                TI_WAIT_FOR_SEND_PID,
                TI_WAIT_FOR_DASH_2,
                TI_WAIT_FOR_ORDER,
                TI_DONE
            );
signal c_initseq : T_INITSEQ;


signal r_data_0  : std_logic_vector(7 downto 0);
signal r_valid_0 : std_logic;

signal r_got_init  : std_logic;
signal r_im_first  : std_logic;
signal r_init_done : std_logic;

signal r_dout       : std_logic_vector(7 downto 0);
signal r_dout_valid : std_logic;
signal c_dout       : std_logic_vector(1 downto 0);

signal r_mon : std_logic_vector(7 downto 0);

begin

input_proc: process(Clk)
begin
  if (rising_edge(Clk)) then
    --r_data_0 <= Din;
    r_valid_0 <= Din_valid;
    if (Din_valid = '1') then
      r_data_0 <= Din;
    end if;
  end if;
end process;

seq_proc: process(Clk)
begin
  if (rising_edge(Clk)) then
    if (Rst = '1') then
      c_initseq         <= TI_WAIT_FOR_DASH_1;
      r_im_first        <= '0';
      r_got_init        <= '0';
      r_init_done       <= '0';
      r_mon(3 downto 0) <= "0001";
    else
--      if (r_valid_0 = '1') then
        case c_initseq is
          when TI_DONE =>
            r_init_done <= '1';
            r_mon(3 downto 0) <= "0110";
          when TI_WAIT_FOR_ORDER =>
            if ((r_valid_0 = '1') and (r_data_0 = X"57")) then -- receive "W"
              r_im_first <= '1';
              c_initseq <= TI_DONE;
            elsif ((r_valid_0 = '1') and (r_data_0 = X"42")) then -- receive "B"
              r_im_first <= '0';
              c_initseq <= TI_DONE;
            end if;
            r_mon(3 downto 0) <= "0101";
          when TI_WAIT_FOR_DASH_2 =>
            if ((r_valid_0 = '1') and (r_data_0 = X"2D")) then -- receive dash
              c_initseq <= TI_WAIT_FOR_ORDER;
            end if;
            r_mon(3 downto 0) <= "0100";
          when TI_WAIT_FOR_SEND_PID =>
            if (c_dout = "11") then
              c_initseq <= TI_WAIT_FOR_DASH_2;
            end if;
            r_mon(3 downto 0) <= "0011";
          when TI_WAIT_FOR_T =>
            if ((r_valid_0 = '1') and (r_data_0 = X"54")) then -- receive "T"
              c_initseq <= TI_WAIT_FOR_SEND_PID;
            end if;
            r_mon(3 downto 0) <= "0010";
          when TI_WAIT_FOR_DASH_1 =>
            if ((r_valid_0 = '1') and (r_data_0 = X"2D")) then -- receive dash
              c_initseq         <= TI_WAIT_FOR_T;
              r_got_init        <= '1';
            end if;
            r_mon(3 downto 0) <= "0001";
          when others =>
            c_initseq         <= c_initseq;
            r_mon(3 downto 0) <= "0000";
        end case;
--      else
--      end if;
    end if;
  end if;
end process;

pid_send_proc: process(Clk)
begin
  if (rising_edge(Clk)) then
    if (Rst = '1') then
      r_dout <= (others => '0');
      r_dout_valid <= '0';
      c_dout <= (others => '0');
    else
      if (c_initseq = TI_WAIT_FOR_SEND_PID) then
        if (c_dout = "10") then
          r_dout <= X"0A";
          r_dout_valid <= '1';
          c_dout <= "11";
        elsif (c_dout = "01") then
          r_dout <= PLAYERID(7 downto 0);
          r_dout_valid <= '1';
          c_dout <= "10";
        elsif (c_dout = "00") then
          r_dout <= PLAYERID(15 downto 8);
          r_dout_valid <= '1';
          c_dout <= "01";
        else
          r_dout <= (others => '0');
          r_dout_valid <= '0';
        end if;
      else
        r_dout <= (others => '0');
        r_dout_valid <= '0';
        --c_dout <= "00";
      end if;
    end if;
  end if;
end process;

r_mon(7 downto 4) <= "00" & c_dout;

Dout       <= r_dout;
Dout_valid <= r_dout_valid;

Got_init   <= r_got_init;
Im_first   <= r_im_first;
Init_done  <= r_init_done;

Mon        <= r_mon;

end rtl;

library ieee;
use ieee.std_logic_1164.all;

entity opposite_color is
  port (
    c : in std_logic_vector(3 downto 0);
    o : out std_logic_vector(3 downto 0)
  );
end opposite_color;

architecture rtl of opposite_color is

  constant NOTE_PLUS   : std_logic_vector(3 downto 0) := X"1";
  constant NOTE_SLASH  : std_logic_vector(3 downto 0) := X"2";
  constant NOTE_BSLASH : std_logic_vector(3 downto 0) := X"3";

begin

  o <= X"3" when (c = X"2")
  else X"1" when (c = X"1")
  else X"2" when (c = X"3")
  else X"0";

end rtl;

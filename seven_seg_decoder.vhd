library	ieee;
use ieee.std_logic_1164.all;

entity seven_seg_decoder is
  port(din: in  std_logic_vector(3 downto 0);
       dout: out std_logic_vector(7 downto 0));
end seven_seg_decoder;

architecture rtl of seven_seg_decoder is
begin
  process(din)
  begin
    case din is
      when "0000" => dout <= "11111100";
      when "0001" => dout <= "01100000";
      when "0010" => dout <= "11011010";
      when "0011" => dout <= "11110010";
      when "0100" => dout <= "01100110";
      when "0101" => dout <= "10110110";
      when "0110" => dout <= "10111110";
      when "0111" => dout <= "11100000";
      when "1000" => dout <= "11111110";
      when "1001" => dout <= "11110110";
      when "1010" => dout <= "11101110";
      when "1011" => dout <= "00111110";
      when "1100" => dout <= "10011100";
      when "1101" => dout <= "01111010";
      when "1110" => dout <= "10011110";
      when "1111" => dout <= "10001110";
      when others => dout <= "00000000";
    end case;
  end process;
end rtl;

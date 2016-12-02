library ieee;  
use ieee.std_logic_1164.all;  
use ieee.std_logic_unsigned.all;

entity rx is
  generic(N: integer := 32; -- �J�E���^�̃r�b�g��
          K: integer := 4;  -- �������� 1���[�h�̃r�b�g��
          W: integer := 3); -- �������̃��[�h��
  port(
    sysclk, sysrst: in std_logic;
    gio0: in std_logic; -- start bit
    gio1, gio2, gio3, gio4: in std_logic; -- data bits
    gio5: out std_logic; -- ready bit
    led0, led1, led2, led3, led4, led5, led6, led7: out std_logic; -- for debug
    seg_a, seg_b, seg_c, seg_d, seg_e, seg_f, seg_g, seg_h: out std_logic_vector (7 downto 0) -- for debug
  );
end rx;

architecture rtl of rx is
  signal clk, xrst: std_logic;
  signal enable: std_logic;
  signal clk_tx: std_logic;
  signal start: std_logic;
  signal ready: std_logic;
  signal cnt1: std_logic_vector (31 downto 0);
  signal we: std_logic;
  signal wadr, radr: std_logic_vector (2 downto 0);
  signal din, dout: std_logic_vector (3 downto 0);
  type state_type is (s0, s1, s2, s3);
  signal state: state_type;
  signal output: std_logic;
  signal count_clk: std_logic_vector(9 downto 0);
  signal count_clk_half: std_logic_vector(9 downto 0);
  signal count_clk2: std_logic_vector(9 downto 0);
  signal number_a, number_b, number_c, number_d, number_e, number_f, number_g, number_h: std_logic_vector(3 downto 0); 
  -- ���M�p�N���b�N������H
  component clock_gen
    generic(N: integer);
    port(clk, xrst: in std_logic;
         enable: in std_logic;
         cnt_max: in std_logic_vector (N-1 downto 0);
         clk_tx: out std_logic);
  end component;
  -- K�r�b�g�EW���[�h�� RAM
  component ram_WxK
    generic(K: integer;
            W: integer);
    port(clk: in std_logic;
         din: in std_logic_vector (K-1 downto 0);
         wadr: in std_logic_vector (W-1 downto 0);
         radr: in std_logic_vector (W-1 downto 0);
         we: in std_logic;
         dout: out std_logic_vector (K-1 downto 0));
  end component;
  -- 7�Z�O�����g�f�R�[�_
  component seven_seg_decoder is
  port(din: in  std_logic_vector(3 downto 0);
       dout: out std_logic_vector(7 downto 0));
  end component;
begin
  clk <= sysclk;
  xrst <= sysrst;
  start <= gio0;
  din <= gio4 & gio3 & gio2 & gio1;
	
  ssd1: seven_seg_decoder port map(din => number_a, dout => seg_a);
  ssd2: seven_seg_decoder port map(din => number_b, dout => seg_b);
  ssd3: seven_seg_decoder port map(din => number_c, dout => seg_c);
  ssd4: seven_seg_decoder port map(din => number_d, dout => seg_d);
  ssd5: seven_seg_decoder port map(din => number_e, dout => seg_e);
  ssd6: seven_seg_decoder port map(din => number_f, dout => seg_f);
  ssd7: seven_seg_decoder port map(din => number_g, dout => seg_g);
  ssd8: seven_seg_decoder port map(din => number_h, dout => seg_h);
  cg1: clock_gen generic map(N => N) port map(clk => clk, xrst => xrst, enable => enable, cnt_max => cnt1, clk_tx => clk_tx);
  ram1: ram_WxK generic map(K => K, W => W) port map(clk => clk, din => din, wadr => wadr, radr => radr, we => we, dout => dout);
  
-- �L�q�J�n
  process(clk, xrst, start, din)
    begin
    gio5 <= output;
	 
    if(xrst = '0') then
		state <= s0;
    elsif(clk'event and clk = '1') then
		case state is 
			when s0 =>
			   output <= '1';
				if(start = '1') then
					output <= '0';
					state <= s1;
				end if;
				
			when s1 =>
				count_clk <= count_clk + 1;
				if(start = '0') then
					count_clk_half <= SHR(count_clk,"0000000001");
					count_clk2 <= "0000000000";
					wadr <= "000";
					radr <= "000";
					state <= s2;
				end if;
				
			when s2 =>
				count_clk2 <= count_clk2 + 1;
				if(count_clk2 = count_clk_half) then
					we <= '1';
					wadr <= wadr + 1;
				elsif(count_clk2 = count_clk) then
					we <= '0';
					count_clk2 <= "0000000000";
					if(wadr = "000") then
						state <= s3;
					end if;
				end if;
				
				when s3 =>
					number_a <= dout;
					radr <= radr + 1;
					number_b <= dout;
					radr <= radr + 1;
					number_c <= dout;
					radr <= radr + 1;
					number_d <= dout;
					radr <= radr + 1;
					number_e <= dout;
					radr <= radr + 1;
					number_f <= dout;
					radr <= radr + 1;
					number_g <= dout;
					radr <= radr + 1;
					number_h <= dout;
					output <= '1';
					state <= s0;
			when others =>
				state <= state;
		end case;
	end if;
  end process;
-- �L�q�I��
end rtl;

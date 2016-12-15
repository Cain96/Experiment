library ieee;  
use ieee.std_logic_1164.all;  
use ieee.std_logic_unsigned.all;

entity rx is
  generic(N: integer := 32; -- カウンタのビット幅
          K: integer := 4;  -- メモリの 1ワードのビット幅
          W: integer := 3); -- メモリのワード数
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
  signal wadr, radr, radr2: std_logic_vector (2 downto 0);
  signal din, dout: std_logic_vector (3 downto 0);
  type state_type is (s0, s1, s2, s3);
  signal state: state_type;
  signal output: std_logic;
  signal flag: std_logic;
  signal count_clk, count_clk2, count_clk_half: std_logic_vector(9 downto 0);
  signal number_a, number_b, number_c, number_d, number_e, number_f, number_g, number_h: std_logic_vector(3 downto 0); 
  -- 送信用クロック生成回路
  component clock_gen
    generic(N: integer);
    port(clk, xrst: in std_logic;
         enable: in std_logic;
         cnt_max: in std_logic_vector (N-1 downto 0);
         clk_tx: out std_logic);
  end component;
  -- Kビット・Wワードの RAM
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
  -- 7セグメントデコーダ
  component seven_seg_decoder is
  port(din: in  std_logic_vector(3 downto 0);
       dout: out std_logic_vector(7 downto 0));
  end component;
begin
  clk <= sysclk;
  xrst <= sysrst;
  start <= gio0;
  din <= gio4 & gio3 & gio2 & gio1;
  led0 <= gio1;
  gio5 <= output;
	
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
  
-- 記述開始
  process(clk, xrst, start, din)
    begin
	 
    if(xrst = '0') then
		state <= s0;
		number_a <= "0000";
		number_b <= "0000";
		number_c <= "0000";
		number_d <= "0000";
		number_e <= "0000";
		number_f <= "0000";
		number_g <= "0000";
		number_h <= "0000";
    elsif(clk'event and clk = '1') then
		case state is 
			when s0 =>
			   output <= '1';
				if(start = '1') then
					state <= s1;
					count_clk <= "0000000000";
				end if;
				
			when s1 =>
				led1 <= '1';
				output <= '0';
				count_clk <= count_clk + 1;
				if(start = '0') then
					count_clk_half <= SHR(count_clk,"0000000001");
					count_clk2 <= "0000000000";
					wadr <= "000";
					radr <= "000";
					flag <= '0';
					state <= s2;
				end if;
				
			when s2 =>
				led2 <= '1';
				count_clk2 <= count_clk2 + 1;
				if(count_clk2 = count_clk_half) then
					we <= '1';
					flag <= '1';
				elsif(count_clk2 = count_clk - 1) then
					wadr <= wadr + 1;
					count_clk2 <= "0000000000";
					if(wadr = "111") then
						radr <= "000";
						state <= s3;
					end if;
				elsif(flag = '1') then
					we <= '0';
					flag <= '0';
				end if;
				
			when s3 =>
				led3 <= '1';
				radr <= radr + 1;
				radr2 <= radr;
				if(radr2 = "000") then
					number_a <= dout;
				elsif(radr2 = "001") then
					number_b <= dout;
				elsif(radr2 = "010") then
					number_c <= dout;
				elsif(radr2 = "011") then
					number_d <= dout;
				elsif(radr2 = "100") then
					number_e <= dout;
				elsif(radr2 = "101") then
					number_f <= dout;
				elsif(radr2 = "110") then
					number_g <= dout;
				elsif(radr2 = "111") then
					number_h <= dout;
					state <= s0;
					led1 <= '0';
					led2 <= '0';
					led3 <= '0';
				end if;
				
			when others =>
				state <= state;
		end case;
	end if;
  end process;
-- 記述終了
end rtl;
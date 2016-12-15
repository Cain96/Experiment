library ieee;  
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tx is
  generic(N: integer := 32; -- カウンタのビット幅
          K: integer := 4;  -- メモリの 1ワードのビット幅
          W: integer := 3); -- メモリのワード数
  port(
    sysclk, sysrst: in std_logic;
    psw_a0: in std_logic; -- start button
    dip_a: in std_logic_vector (7 downto 0); -- wadr (2 downto 0)
    dip_b: in std_logic_vector (7 downto 0); -- din (3 downto 0), we (7)
    gio5: in std_logic; -- ready bit
    gio0: out std_logic; -- start bit
    gio1, gio2, gio3, gio4: out std_logic; -- data bits
    led0, led1, led2, led3, led4, led5, led6, led7: out std_logic; -- for debug
    seg_a, seg_b, seg_c, seg_d, seg_e, seg_f, seg_g, seg_h: out std_logic_vector (7 downto 0) -- for debug
  );
end tx;

architecture rtl of tx is
  constant cnt_max: std_logic_vector(31 downto 0):= X"0000003F";
  type state_type is (s0, s1, s2, s3);
  signal state: state_type;
  signal clk, xrst: std_logic;
  signal enable: std_logic;
  signal clk_tx: std_logic;
  signal start: std_logic;
  signal ready: std_logic;
  signal we: std_logic;
  signal number_a, number_b, number_c, number_d, number_e, number_f, number_g, number_h : std_logic_vector (3 downto 0);
  signal wadr, radr ,counter: std_logic_vector (2 downto 0);
  signal din, dout: std_logic_vector (3 downto 0);
  signal button: std_logic;
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
  wadr <= dip_a(2 downto 0);
  din <= dip_b(3 downto 0);
  we <= dip_b(7);
  ready <= gio5;
  button <= psw_a0;
  led0 <= gio5; 

  ssd1: seven_seg_decoder port map(din => number_a, dout => seg_a);
  ssd2: seven_seg_decoder port map(din => number_b, dout => seg_b);
  ssd3: seven_seg_decoder port map(din => number_c, dout => seg_c);
  ssd4: seven_seg_decoder port map(din => number_d, dout => seg_d);
  ssd5: seven_seg_decoder port map(din => number_e, dout => seg_e);
  ssd6: seven_seg_decoder port map(din => number_f, dout => seg_f);
  ssd7: seven_seg_decoder port map(din => number_g, dout => seg_g);
  ssd8: seven_seg_decoder port map(din => number_h, dout => seg_h);
  
  cg1: clock_gen generic map(N => N) port map(clk => clk, xrst => xrst, enable => enable, cnt_max => cnt_max, clk_tx => clk_tx);
  ram1: ram_WxK generic map(K => K, W => W) port map(clk => clk, din => din, wadr => wadr, radr => radr, we => we, dout => dout);
process(clk,xrst,counter,radr,ready,enable)
 begin

 if(xrst = '0') then
	state <= s0;
 
 elsif(clk'event and clk ='1') then
	case state is
		when s0 =>
			if(we = '1') then
				radr <= wadr;
				if(radr = "000") then
					number_a <= dout;
				elsif(radr = "001") then
					number_b <= dout;
				elsif(radr = "010") then
					number_c <= dout;
				elsif(radr = "011") then
					number_d <= dout;
				elsif(radr = "100") then
					number_e <= dout;
				elsif(radr = "101") then
					number_f <= dout;
				elsif(radr = "110") then
					number_g <= dout;
				elsif(radr = "111") then
					number_h <= dout;
				end if;
				enable <= '1';
			end if;
			
			if(button = '0' and enable = '1' and ready = '1') then
				state <= s1;
			end if;
			
		when s1 =>
			led1 <= '1';
			if(clk_tx = '1') then
				gio0 <= '1';
				state <= s2;
			end if;
			
		when s2 =>
			led2 <= '1';
			if(clk_tx = '1') then
				gio0 <= '0';
				state <= s3;
				radr <= "000";
			end if;
			
		when s3 =>
			led3 <= '1';
			gio1 <= dout(0);
			gio2 <= dout(1);
			gio3 <= dout(2);
			gio4 <= dout(3);
			if(clk_tx = '1') then
				if(radr < "111") then
					radr <= radr + 1;
				elsif(radr = "111") then
					radr <= radr + 1;
				else
					radr <= "000";
				end if;
				counter <= counter + 1;
				if(counter = "111") then
					counter <= "000";
					led1 <= '0';
					led2 <= '0';
					led3 <= '0';
					state <= s0;
				end if;
			end if;	
		
		when others =>
		 state <= state;
	end case;
 end if;
end process;

end rtl;
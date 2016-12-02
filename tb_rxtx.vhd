library ieee;  
library modelsim_lib;
use ieee.std_logic_1164.all;
use modelsim_lib.util.all;

entity tb_txrx is  
  generic(K: integer := 4;
          W: integer := 3);
end tb_txrx;

architecture testbench of tb_txrx is
  type mem is array(0 to (2**W)-1) of std_logic_vector(K-1 downto 0);
  type test_vec_t is record
    dip_a: std_logic_vector (7 downto 0);
    dip_b: std_logic_vector (7 downto 0);
  end record;
  type test_vec_array_t is array(natural range <>) of test_vec_t;
  constant input_table: test_vec_array_t :=
    ((X"00", X"81"),
     (X"01", X"8A"),
     (X"02", X"82"),
     (X"03", X"8B"),
     (X"04", X"83"),
     (X"05", X"8C"),
     (X"06", X"84"));
  constant period1: time := 10 ns;
  constant period2: time := 33 ns;
  signal clk1, clk2: std_logic := '0';
  signal xrst1, xrst2: std_logic;
  signal psw_a0: std_logic;
  signal dip_a, dip_b: std_logic_vector (7 downto 0);
  signal gio0, gio1, gio2, gio3, gio4, gio5: std_logic;
  signal adr: std_logic_vector(2 downto 0);
  signal din: std_logic_vector(3 downto 0);
  signal we: std_logic;
  signal ready: std_logic;
  signal tx_ram, rx_ram: mem;
  component tx is
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
  end component;
  component rx
    port(
      sysclk, sysrst: in std_logic;
      gio0: in std_logic; -- start bit
      gio1, gio2, gio3, gio4: in std_logic; -- data bits
      gio5: out std_logic; -- ready bit
      led0, led1, led2, led3, led4, led5, led6, led7: out std_logic; -- for debug
      seg_a, seg_b, seg_c, seg_d, seg_e, seg_f, seg_g, seg_h: out std_logic_vector (7 downto 0) -- for debug
      );
  end component;
begin
  adr <= dip_a(2 downto 0);
  din <= dip_b(3 downto 0);
  we <= dip_b(7);
  ready <= gio5;
  
  clock1: process
  begin
    wait for period1/2;
    clk1 <= not clk1;
  end process;

  clock2: process
  begin
    wait for period2/2;
    clk2 <= not clk2;
  end process;

  stim1: process
  begin
    xrst1 <= '1';
    psw_a0 <= '1';
    dip_a <= (others => '0');
    dip_b <= (others => '0');
    wait for period1/2;
    wait for period1*2;
    xrst1 <= '0';
    wait for period1;
    xrst1 <= '1';
    wait for period1*5;
    for i in input_table'range loop
      dip_a <= input_table(i).dip_a;
      dip_b <= input_table(i).dip_b;
      wait for period1;
    end loop;
    dip_a <= (others => '0');
    dip_b <= (others => '0');
    wait for period1*10;
    psw_a0 <= '0';
    wait for period1;
    psw_a0 <= '1';
    wait for period1*10;
    psw_a0 <= '0';
    wait for period1;
    psw_a0 <= '1';
    wait for period1*30;
    psw_a0 <= '0';
    wait for period1;
    psw_a0 <= '1';
    wait;
  end process;

  stim2: process
  begin
    xrst2 <= '1';
    wait for period2/2;
    wait for period2*7;
    xrst2 <= '0';
    wait for period2;
    xrst2 <= '1';
    wait;
  end process;
    
  check: process
  begin
    init_signal_spy("tb_txrx/tx1/ram1/ram_block","/tx_ram",1);
    init_signal_spy("tb_txrx/rx1/ram1/ram_block","/rx_ram",1);
    wait until psw_a0 = '0' and ready = '1';
    wait until gio5 = '0';
    wait until gio5 = '1';
    assert (tx_ram = rx_ram) report "Received data is different from transferred data!" severity failure;          
    wait for period2*10;
    assert (false) report "Simulation successfully completed!" severity failure;      
  end process;

  tx1: tx port map(sysclk => clk1,
                   sysrst => xrst1,
                   psw_a0 => psw_a0,
                   dip_a => dip_a,
                   dip_b => dip_b,
                   gio0 => gio0,
                   gio1 => gio1, gio2 => gio2, gio3 => gio3, gio4 => gio4,
                   gio5 => gio5);

  rx1: rx port map(sysclk => clk2,
                   sysrst => xrst2,
                   gio0 => gio0,
                   gio1 => gio1, gio2 => gio2, gio3 => gio3, gio4 => gio4,
                   gio5 => gio5);
end testbench;


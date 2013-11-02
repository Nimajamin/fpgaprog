library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
--	use ieee.numeric_std.all;
library unisim;
	use unisim.vcomponents.all;
 
entity bscan_tb is
end bscan_tb;
 
ARCHITECTURE behavior OF bscan_tb IS 
	signal SRAM_D    : std_logic_vector(15 downto 0) := (others=>'0');
	signal SRAM_A    : std_logic_vector(18 downto 0);
	signal SRAM_nCS  : std_logic;
	signal SRAM_nOE  : std_logic;
	signal SRAM_nWE  : std_logic;
	signal SRAM_nBLE : std_logic;
	signal SRAM_nBHE : std_logic;

	signal JTDO      : std_logic;
	signal JTDI      : std_logic := '0';
	signal JTCK      : std_logic := '0';
	signal JTMS      : std_logic := '0';

	signal tdi_val   : std_logic_vector(31 downto 0) := (others=>'0');
	signal tdo_val   : std_logic_vector(15 downto 0) := (others=>'0');
	signal ir_val    : std_logic_vector( 7 downto 0) := (others=>'0');

	signal clock     : std_logic := '0';

	constant clock_period : time := 200 ns; -- 5MHZ
	type  array_512x16 is array (0 to 511) of std_logic_vector(15 downto 0);
	signal ram			: array_512x16 := (others => (others => '0'));

begin
	BS_TB : JTAG_SIM_SPARTAN6 generic map ( PART_NAME => "LX9" )
	port map (
		TDO => JTDO, -- changes state on falling_edge(TCK)
		TDI => JTDI, -- sampled on rising_edge(TCK)
		TCK => JTCK,
		TMS => JTMS
	);

	uut: entity work.bscan_sram
	port map (
		SRAM_A    => SRAM_A,
		SRAM_D    => SRAM_D,
		SRAM_nCS  => SRAM_nCS,
		SRAM_nOE  => SRAM_nOE,
		SRAM_nWE  => SRAM_nWE,
		SRAM_nBLE => SRAM_nBLE,
		SRAM_nBHE => SRAM_nBHE
	);

	clock_process :process
	begin
		clock <= '0';
		wait for clock_period/2;
		clock <= '1';
		wait for clock_period/2;
	end process;

	-- fake a RAM
	process(SRAM_A, SRAM_nCS, SRAM_nOE, SRAM_nWE)
	begin
		if SRAM_nCS='0' then
			if SRAM_nWE='0' then
				ram(conv_integer(SRAM_A(8 downto 0))) <= SRAM_D;
			else
				if SRAM_nOE='0' then
					SRAM_D <= ram(conv_integer(SRAM_A(8 downto 0)));
--					SRAM_D <= (others=>'Z');
				else
					SRAM_D <= (others=>'Z');
				end if;
			end if;
		end if;
	end process;

	stim_proc: process
	begin		
		wait for clock_period*8;

		-- move to test logic reset
		JTMS <= '1'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTMS <= '1'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTMS <= '1'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTMS <= '1'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTMS <= '1'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;

		-- move to shift ir
		JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTMS <= '1'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTMS <= '1'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;

		-- enter "user1" instruction ("000010") into IR
		JTDI <= '0'; JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTDI <= '1'; JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTDI <= '0'; JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTDI <= '0'; JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTDI <= '0'; JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;

		-- exit shift ir
		JTDI <= '0'; JTMS <= '1'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTMS <= '1'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;

		-- enter shift dr
		JTMS <= '1'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;



		-- shift dr value
		tdi_val <= x"59A60001"; -- enter write mode
		for i in integer range 0 to 31 loop
			JTDI <= tdi_val(31-i);
			JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		end loop;

		-- shift dr value (empty sectors)
		for i in integer range 0 to (1*512*16)-1 loop
			JTDI <= tdi_val(15-(i mod 16));
			if (i mod 16) = 0 then tdi_val <= tdi_val + 1; end if;
			JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		end loop;



		-- shift dr value
		tdi_val <= x"59A50001"; -- enter read mode
		for i in integer range 0 to 31 loop
			JTDI <= tdi_val(31-i);
			JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		end loop;

		-- shift dr value (empty sectors)
		JTDI <= '0';
		for i in integer range 0 to (1*512*16)-1 loop
			JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		end loop;

		-- clock out two more words
		for i in integer range 0 to 31 loop
			JTMS <= '0'; JTCK <= '0'; wait for clock_period/2; JTCK <= '1'; wait for clock_period/2;
		end loop;

		wait;
	end process;

end;

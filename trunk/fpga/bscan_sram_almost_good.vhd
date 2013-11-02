library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;
library unisim;
	use unisim.vcomponents.all;

entity bscan_sram is
	port (
		SRAM_A		:	out   std_logic_vector(18 downto 0);
		SRAM_D		:	inout std_logic_vector(15 downto 0);
		SRAM_nCS		:	out   std_logic;
		SRAM_nOE		:	out   std_logic;
		SRAM_nWE		:	out   std_logic;
		SRAM_nBLE	:	out   std_logic;
		SRAM_nBHE	:	out   std_logic;

		O_LED			:	out   std_logic_vector( 3 downto 0));
end bscan_sram;

architecture Behavioral of bscan_sram is

	type	STATE_TYPE is ( STATE_WAIT, STATE_WRITE, STATE_READ );
	signal state				: STATE_TYPE := STATE_WAIT;
	signal reset				: std_logic := '0';
	signal repeat_count		: std_logic_vector(24 downto 0) := (others => '0');
	signal bit_count			: std_logic_vector( 3 downto 0) := (others => '0');
	signal A_int				: std_logic_vector(18 downto 0) := (others => '0');

	signal user_CAPTURE		: std_logic;
	signal user_DRCK			: std_logic;
	signal user_RESET			: std_logic;
	signal user_SEL			: std_logic;
	signal user_SHIFT			: std_logic;
	signal user_TDI			: std_logic;
	signal user_TDO			: std_logic;
	signal user_UPDATE		: std_logic;

	signal tdi_mem				: std_logic_vector(31 downto 0) := (others => '0');
	signal tdo_mem				: std_logic_vector(15 downto 0) := (others => '0');
	signal tdo_shift			: std_logic_vector(15 downto 0);

begin

	BS : BSCAN_SPARTAN6
	port map (
		CAPTURE	=> user_CAPTURE,
		DRCK		=> user_DRCK,
		RESET		=> user_RESET,
		SEL		=> user_SEL,
		SHIFT		=> user_SHIFT,
		TDI		=> user_TDI,
		TDO		=> user_TDO,
		UPDATE	=> user_UPDATE
	);

	SRAM_A		<= A_int;
	SRAM_nCS		<= '0';
	SRAM_nBLE	<= '0';
	SRAM_nBHE	<= '0';

	SRAM_nOE		<= '0' when (state=STATE_READ) else '1';
	SRAM_nWE		<= '0' when (state=STATE_WRITE) and ((bit_count(3) xor bit_count(2)) ='1') else '1';

	user_TDO <= tdo_shift(tdo_mem'high);
	reset <= user_CAPTURE or user_RESET or user_UPDATE or not user_SEL;

	process (reset,user_DRCK)
	begin
		if (reset='1') then
			state		<= STATE_WAIT;
			tdo_mem	<= (others => '0');
			SRAM_D	<= (others => 'Z');
			O_LED		<= (others=>'0');
		elsif (falling_edge(user_DRCK)) then
			case state is
			when STATE_WAIT =>
				O_LED		<= x"1";
				-- start write : 59A6 xxxx (xxxx = # of 512 Byte pages)
				if (tdi_mem(tdi_mem'high downto tdi_mem'high-15)=x"59A6") then
					repeat_count(24 downto 9)	<= tdi_mem(15 downto 0);
					repeat_count( 8 downto 0)	<= (others=>'0');
					bit_count						<= (others=>'1');
					A_int								<= (others=>'1');
					state								<= STATE_WRITE;
				-- start read : 59A5 xxxx (xxxx = # of 512 Byte pages)
				elsif (tdi_mem(tdi_mem'high downto tdi_mem'high-15)=x"59A5") then
					repeat_count(24 downto 9)	<= tdi_mem(15 downto 0);
					repeat_count( 8 downto 0)	<= (others=>'0');
					bit_count						<= (others=>'1');
					A_int								<= (others=>'0');
					state								<= STATE_READ;
				end if;

			when STATE_WRITE =>
				O_LED		<= x"2";
				if bit_count>0 then
					bit_count		<= bit_count - 1;
				else
					A_int				<= A_int + 1;
					SRAM_D			<= tdi_mem(15 downto 0);
					bit_count		<= (others=>'1');
					if repeat_count>0 then
						repeat_count<= repeat_count - 1;
					else
						SRAM_D		<= (others=>'Z');
						state			<= STATE_WAIT;
					end if;
				end if;

			when STATE_READ =>
				O_LED		<= x"4";
				if bit_count>0 then
					bit_count <= bit_count - 1;
				else
					tdo_mem <= SRAM_D;
					A_int <= A_int + 1;
					bit_count <= (others=>'1');
					if repeat_count>0 then
						repeat_count<= repeat_count - 1;
					else
						state <= STATE_WAIT;
					end if;
				end if;

			when others =>
				state <= STATE_WAIT;
			end case;
		end if;
	end process;

	process (reset,user_DRCK)
	begin
		if (reset='1') then
			tdi_mem   <= (others => '0');
			tdo_shift <= (others => '0');
		elsif rising_edge(user_DRCK) then
			tdi_mem(tdi_mem'high downto 0) <= tdi_mem((tdi_mem'high-1) downto 0) & user_TDI;
			if bit_count=0 then
				tdo_shift <= tdo_mem;
			else
				tdo_shift(tdo_mem'high downto 0) <= tdo_shift((tdo_mem'high-1) downto 0) & '0';
			end if;
		end if;
	end process;

end Behavioral;
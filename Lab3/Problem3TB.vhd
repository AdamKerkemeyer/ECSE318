library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_arith.ALL;
use ieee.std_logic_unsigned.ALL;

entity Problem3TB is
end entity Problem3TB;

architecture sim of Problem3TB is
    constant ClockFrequency : integer := 100e6; -- 100 MHz clock frequency
    constant ClockPeriod : time := 1000 ms / ClockFrequency; -- Can set period using frequency
    signal Clk : std_logic := '1';
    signal clear : std_logic := '0'; -- reset
    signal addend : std_logic_vector(7 downto 0);
    signal augand : std_logic_vector(7 downto 0);
    signal cin : std_logic;
    signal sum : std_logic_vector(7 downto 0);
    signal cout : std_logic;
begin
    -- Instantiate the Unit Under Test (UUT)
    i_Problem3 : entity work.Problem3
    port map(
        Clk => Clk,
        clear => clear,
        addend => addend,
        augand => augand,
        cin => cin,
        sum => sum,
        cout => cout
    );

    -- Clock generation process
    Clk <= not Clk after ClockPeriod / 2;

    process
    begin        clear <= '1';
        wait for ClockPeriod;
        clear <= '0';
        wait for ClockPeriod;
        wait for ClockPeriod;

        -- Loop through all possible 8-bit combinations
        for i in 0 to 255 loop
            for j in 0 to 255 loop
                addend <= std_logic_vector(to_unsigned(i, 8));
                augand <= std_logic_vector(to_unsigned(j, 8));
                cin <= '0';
                wait for ClockPeriod;
            end loop;
        end loop;

        wait;
    end process;
end architecture sim;
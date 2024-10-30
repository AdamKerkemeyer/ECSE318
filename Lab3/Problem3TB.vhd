library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Problem3TB is
end entity

architecture sim of Problem3TB is
    constant ClockFrequency : integer := 100e6; --100 MHz
    constant ClockPeriod : time := 1000 ms / ClockFrequency; --Can set period using frequency
    signal Clk : std_logic := '1';
    signal clear : std_logic := '0'; --reset
    signal addend : std_logic;
    signal augand : std_logic;
    signal cin : std_logic;
    signal cout : std_logic;
begin
    i_Problem3 : entity work.Problem3(rtl)
    port map(
        Clk => Clk,
        clear => clear,
        addend => addend,
        cin => cin,
        cout => cout);

    Clk <= not Clk after ClockPeriod / 2; --Process for generating the clock


    --Testbench Sequence here
    process is
    begin --UUT inputs here
        --Because things happen in zero time (delta delay)
        --If an input changes at the same time as the Clk
        --The computed output will be whatever the old input was
        wait until rising_edge(Clk); --Let the program initialize
        wait;
    end process;
end architecture;
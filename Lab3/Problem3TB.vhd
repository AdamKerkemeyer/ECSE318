library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Problem3TB is
end entity

architecture sim of Problem3TB is
    constant ClockFrequency : integer := 100e6; --100 MHz
    constant ClockPeriod : time := 1000 ms / ClockFrequency; --Can set period using frequency

    signal Clk : std_logic := '1';
begin
    --Process for generating the clock
    Clk <= not Clk after ClockPeriod / 2;
    
end architecture;
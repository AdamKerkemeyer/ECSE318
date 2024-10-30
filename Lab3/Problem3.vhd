library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Problem3 is
port(
    Clk : in std_logic;
    clear : in std_logic; --negative reset
    addend : in std_logic;
    augand : in std_logic;
    cin : in std_logic;
    cout : out std_logic;
    output : out stt_logic; --need to make 
)
end entity

architecture rtl of Problem3 is

begin
    process(Clk) is --Runs whenever CLK changes
        if rising_edge(Clk) then --Only run on rising edge
            if clear = '1' then
                Output <= (others => '0');
            else
                --Do logic here

            end if;
        end if;
    end process;
end architecture;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Problem1TB is
end Problem1TB;

architecture sim of Problem1TB is
    -- Component declaration for the unit under test (UUT)
    component problem1
        Port ( x : in  STD_LOGIC_VECTOR (7 downto 0);
               y : in  STD_LOGIC_VECTOR (7 downto 0);
               cin : in  STD_LOGIC;
               cout : out  STD_LOGIC;
               correctSum : out  STD_LOGIC_VECTOR (7 downto 0));
    end component;

    -- Signals to connect to the UUT
    signal x : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal y : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal cin : STD_LOGIC := '0';
    signal cout : STD_LOGIC;
    signal correctSum : STD_LOGIC_VECTOR (7 downto 0);

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: problem1 Port map (
        x => x,
        y => y,
        cin => cin,
        cout => cout,
        correctSum => correctSum
    );

    -- Stimulus process
    stim_proc: process
    begin
        -- Test vector 1
        x <= "00000001"; y <= "00000001"; cin <= '0';
        wait for 10 ns;
        
        -- Test vector 2
        x <= "00001111"; y <= "00001111"; cin <= '1';
        wait for 10 ns;
        
        -- Test vector 3
        x <= "10101010"; y <= "01010101"; cin <= '0';
        wait for 10 ns;
        
        -- Test vector 4
        x <= "11111111"; y <= "00000001"; cin <= '1';
        wait for 10 ns;
        
        -- Test vector 5
        x <= "11110000"; y <= "00001111"; cin <= '0';
        wait for 10 ns;
        
        -- Add more test vectors as needed
        -- ...

        -- End simulation
        wait;
    end process;

end Behavioral;

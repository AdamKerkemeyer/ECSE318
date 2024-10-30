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
    -- Loop through all possible combinations of x and y
        for i in 0 to 255 loop
            for j in 0 to 255 loop
                x <= std_logic_vector(to_unsigned(i, 8));
                y <= std_logic_vector(to_unsigned(j, 8));
                cin <= '0';  -- You can also loop through cin if needed
                wait for 10 ns;
            end loop;
        end loop;
        -- End simulation
        wait;
    end process;

end Behavioral;

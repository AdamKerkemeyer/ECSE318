library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

entity Problem1TB is
end Problem1TB;

architecture sim of Problem1TB is
    -- Component declaration for the unit under test (UUT)
    component Problem1
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
    signal expectedSum : STD_LOGIC_VECTOR (7 downto 0);

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: Problem1 Port map (
        x => x,
        y => y,
        cin => cin,
        cout => cout,
        correctSum => correctSum
    );

    -- Stimulus process
    stim_proc: process
        variable i, j : integer;
        variable l : line;
        variable expectedSum_str, correctSum_str : string(1 to 8);
    begin
        -- Loop through all possible combinations of x and y
        for i in 0 to 255 loop
            for j in 0 to 255 loop
                x <= std_logic_vector(to_unsigned(i, 8));
                y <= std_logic_vector(to_unsigned(j, 8));
                cin <= '0';  -- You can also loop through cin if needed
                wait for 10 ns;
                -- Calculate expected sum
                expectedSum <= std_logic_vector(to_unsigned(i + j, 8));
                -- Convert std_logic_vector to string
                write(l, expectedSum);
                expectedSum_str := l.all;
                write(l, correctSum);
                correctSum_str := l.all;
                -- Check if correctSum matches expectedSum
                if correctSum /= expectedSum then
                    report "Mismatch: x=" & integer'image(i) &
                           ", y=" & integer'image(j) &
                           ", expectedSum=" & expectedSum_str &
                           ", correctSum=" & correctSum_str severity error;
                end if;
            end loop;
        end loop;
        -- End simulation
        wait;
    end process;
end sim;

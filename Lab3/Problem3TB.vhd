library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all; --for to_unsigned command

entity Problem3TB is
end entity Problem3TB;

architecture sim of Problem3TB is

    constant ClockFrequency : integer := 100e6; -- 100 MHz clock frequency
    constant ClockPeriod : time := 1000 ms / ClockFrequency; -- Can set period using frequency
    signal Clk : std_logic := '0';
    signal clear : std_logic := '0'; -- reset
    signal addend : std_logic;
    signal augand : std_logic;
    signal cin : std_logic := '0';
    signal sum : std_logic;
    signal cout : std_logic;
    
    --Signals for simulation:
    signal addend_tb : std_logic_vector(7 downto 0) := (others => '0');
    signal augand_tb : std_logic_vector(7 downto 0) := (others => '0');
    signal sum_tb : std_logic_vector(7 downto 0) := (others => '0');
    signal cout_tb : std_logic := '0';

    --Make a component
    component Problem3
        port (       
            Clk : in std_logic;
            clear : in std_logic; -- positive reset
            addend : in std_logic; --There are 8 bits total but the TB must feed them in
            augand : in std_logic; -- One bit at a time as this only adds two bits together at once
            cin : in std_logic;
            sum : out std_logic;
            cout : out std_logic);
    end component;
begin
    -- Instantiate the Unit Under Test (UUT)
    SerialAdder : entity work.Problem3
    port map(
        Clk => Clk,
        clear => clear,
        addend => addend,
        augand => augand,
        cin => cin,
        sum => sum,
        cout => cout);

    Clk <= not Clk after ClockPeriod / 2; --This is technically a process but we can write it without that formatting

    stimming : process
    begin   
        --First explicitly test 7 + 3 and 6 + 4
        clear <= '1'; --At beginning of simulation clear out signals
        wait for ClockPeriod;
        clear <= '0';
        wait for ClockPeriod;

        -- Test case for adding 7 and 3
        addend_tb <= std_logic_vector(to_unsigned(7, 8));
        augand_tb <= std_logic_vector(to_unsigned(3, 8));
        cin <= '0';
        cout_tb <= '0';
        sum_tb <= (others => '0');  
        clear <= '1';
        wait for ClockPeriod;
        clear <= '0';
        wait for ClockPeriod;
        for index in 0 to 7 loop
            addend <= addend_tb(index);
            augand <= augand_tb(index);
            cin <= cout_tb;
            wait for ClockPeriod;
            sum_tb(index) <= sum;
            cout_tb <= cout;
        end loop;
        wait for ClockPeriod;
        report "Addend: 7 + Augand: 3 = Sum: " & integer'image(to_integer(unsigned(sum_tb))) & 
               " with Carry-out: " & std_logic'image(cout_tb);
        wait for ClockPeriod;

        -- Test case for adding 6 and 4
        addend_tb <= std_logic_vector(to_unsigned(6, 8));
        augand_tb <= std_logic_vector(to_unsigned(4, 8));
        cin <= '0';
        cout_tb <= '0';
        sum_tb <= (others => '0');
        -- Clear and allow the adder to process new values
        clear <= '1';
        wait for ClockPeriod;
        clear <= '0';
        wait for ClockPeriod;
        -- Perform bitwise addition for 6 + 4
        for index in 0 to 7 loop
            addend <= addend_tb(index);
            augand <= augand_tb(index);
            cin <= cout_tb;
            wait for ClockPeriod;
            sum_tb(index) <= sum;
            cout_tb <= cout;
        end loop;
        wait for ClockPeriod;
        report "Addend: 6 + Augand: 4 = Sum: " & integer'image(to_integer(unsigned(sum_tb))) & 
               " with Carry-out: " & std_logic'image(cout_tb);
        wait for ClockPeriod;

        clear <= '1'; --At begining of simulation clear out signals
        wait for ClockPeriod;
        clear <= '0';
        wait for ClockPeriod;

        -- Loop through all possible 8-bit combinations now
        for i in 0 to 255 loop
            for j in 0 to 255 loop
                -- Set the 8-bit values for addend_tb and augand_tb
                addend_tb <= std_logic_vector(to_unsigned(i, 8));
                augand_tb <= std_logic_vector(to_unsigned(j, 8));
                
                -- Reset variables for each addition
                cin <= '0';
                cout_tb <= '0';
                sum_tb <= (others => '0'); --this will keep the outputs at zero when we are doing the calculations

                -- Clear and allow the adder to process new values
                clear <= '1';
                wait for ClockPeriod;
                clear <= '0';
                wait for ClockPeriod;

                -- Loop through each bit (LSB to MSB) for serial addition
                for index in 0 to 7 loop
                    addend <= addend_tb(index);
                    augand <= augand_tb(index);
                    cin <= cout_tb;
                    wait for ClockPeriod;
                    -- Capture the result of this bit addition
                    -- Since we update one bit at a time it will look wrong until the final tick on the waveform
                    sum_tb(index) <= sum;
                    cout_tb <= cout;
                end loop;
                --Here is where we display the output (only for one clock pulse)
                wait for ClockPeriod;
                --Figured out display statements so now we can see the sum exactly when it is finished
                --Without needing to decipher the waveform
                report "Addend: " & integer'image(to_integer(unsigned(addend_tb))) &
                       " + Augand: " & integer'image(to_integer(unsigned(augand_tb))) &
                       " = Sum: " & integer'image(to_integer(unsigned(sum_tb))) &
                       " with Carry-out: " & std_logic'image(cout_tb);
                wait for ClockPeriod;
            end loop;
        end loop;
        wait; --Stop simulation
    end process;
end architecture sim;
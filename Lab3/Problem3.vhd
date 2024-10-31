library ieee;
use ieee.std_logic_1164.ALL;

entity Problem3 is
    port(
        Clk : in std_logic;
        clear : in std_logic; -- positive reset
        addend : in std_logic; -- There are 8 bits total but the TB must feed them in
        augand : in std_logic; -- One bit at a time as this only adds two bits together at once
        cin : in std_logic;
        sum : out std_logic;
        cout : out std_logic
    );
end entity Problem3;

architecture rtl of Problem3 is
    signal carry, flag : std_logic := '0';
begin
    process(Clk, clear) --run on every clock pulse or every clear
        variable carry : std_logic := '0';
    begin
        if clear = '1' then --check first to see if clear is high, if it is, reset everything.
            flag <= '0';
            sum <= '0';
            cout <= carry; --We run clear when we are done with the addition
            --This way when we tell it to reset we pass out the most recent calculated carry as cout
        elsif rising_edge(Clk) then 
            if flag = '0' then
                carry := cin; --initialize carry with cin on the first iteration
                flag <= '1'; -- set flag so cin is only used once
            end if;
            sum <= addend xor augand xor carry;
            carry := (addend and carry) or (augand and carry) or (addend and augand);
            cout <= carry; -- output the carry for the current operation
        end if;
    end process;
end architecture rtl;

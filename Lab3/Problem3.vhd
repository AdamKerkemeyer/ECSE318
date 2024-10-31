library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_arith.ALL;
use ieee.std_logic_unsigned.ALL;

entity Problem3 is
    port(
        Clk : in std_logic;
        clear : in std_logic; -- positive reset
        addend : in std_logic_vector(7 downto 0);
        augand : in std_logic_vector(7 downto 0);
        cin : in std_logic;
        sum : out std_logic_vector(7 downto 0);
        cout : out std_logic);
end entity Problem3;

architecture rtl of Problem3 is
    signal carry : std_logic;
    signal temp_sum : std_logic_vector(7 downto 0);
    signal bit_index : integer range 0 to 7 := 0;
begin
    process(Clk, clear) --run on every clock pulse or every clear
    begin
        if clear = '1' then --check first to see if clear is high, if it is, reset everything.
            carry <= '0'; --Don't need to check when it is the rising edge, whenever clear is 1 wipe everything
            temp_sum <= (others => '0'); --way to set everything in a vector to 0 without knowing the length
            bit_index <= 0;
            sum <= (others => '0');
            cout <= '0';
        elsif rising_edge(Clk) then 
            if bit_index <= 7 then
                temp_sum(bit_index) <= (addend(bit_index) xor augand(bit_index)) xor carry;
                carry <= (addend(bit_index) and augand(bit_index)) or (carry and (addend(bit_index) xor augand(bit_index)));
                if bit_index < 7 then
                    bit_index <= bit_index + 1;
                end if;
            else
                sum <= temp_sum;
                cout <= carry;
            end if;
        end if;
    end process;
end architecture rtl; --or just end architecture works
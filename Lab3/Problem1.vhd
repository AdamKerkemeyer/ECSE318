library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity Problem1 is

end entity

architecture rtl of Problem1 is
begin

end architecture Problem1;

--Generic Multiplexer
entity Mux is
generic(DataWidth : integer); --Minus 1 as it is inclusive of MSB and LSB
port(
    --Inputs
    signal Sig1 : in unsigned(DataWidth-1 downto 0);
    signal Sig2 : in unsigned(DataWidth-1 downto 0);
    signal Sig3 : in unsigned(DataWidth-1 downto 0);
    signal Sig4 : in unsigned(DataWidth-1 downto 0);

    signal Sel : in unsigned(1 downto 0);
    --Outputs
    signal Output : out unsigned(DataWidth-1 downto 0));
end entity

architecture rtl of Mux is
begin --register transfer level
    --MUS using case statement
    process(Sel, Sig1, Sig2, Sig3, Sig4) is
    begin
        case Sel is
            when "00" => 
                Output <= Sig1;
            when "01" => 
                Output <= Sig2;
            when "10" => 
                Output <= Sig3;
            when "11" => 
                Output <= Sig4;
            when others => -- 'U' 'X' 
                Output1 <= (others => 'X');
        end case;
    end process;
end architecture rtl;
-- 12 numbers are stored in memory location 0 to 11. Write a program to reverse the list of
-- numbers by storing the content of memory 11 in memory 0, content of memory 10 in memory 1 ...
-- and content of memory 0 in memory 11.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL; --Need this package to do arithmatick for evaluate

entity problem5 is 
    --Create memory for input/output (inout) that is initialized to 0
    port (memory : inout STD_LOGIC(95 downto 0) := (others => '0'));
end problem5;

architecture rtl of problem5 is
    --create a new type that splits up 96 bits into 12 distinct bytes.
    type memoryArray12 is array (0 to 11) of STD_LOGIC(7 downto 0);
    signal mem : memoryArray12;
    signal temp : STD_LOGIC(7 downto 0);
begin
    process(memory) --reun when memory updates
    begin
        --load memory into mem
        for i in 0 to 11 loop 
            mem(i) <= memory((i+1)*8-1 downto i*8);
        end loop;

        --reverse array
        for i in 0 to 5 loop
            temp <= mem(i);
            mem(i) <= mem(11-i);
            mem(11-i) <= temp;
        end loop;

        --write back to the memory
        for i in 0 to 11 loop
            memory((i+1)*8-1 downto i*8) <= mem(i);
        end loop;
    end process;
end rtl;
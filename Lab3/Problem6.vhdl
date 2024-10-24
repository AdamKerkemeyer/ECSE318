--VHDL
--Evaluate C = A*(B+2)
--A,B,C stored in  memory locations 0, 1, and 2 respectively
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; --Need this package for definition of std_logic type
use IEEE.STD_LOGIC_ARITH.ALL; --Need this package to do arithmatick for evaluate
--use IEEE.STD_LOGIC_UNSIGNED.ALL --Need this package to allow vectors to be evaluated as unsigned integers

entity problem6 is 
    --Declare as 8 bit inputs and outputs. 
    port (A, B : in STD_LOGIC (7 downto 0); C : out STD_LOGIC (7 downto 0)); 
end problem6;

architecture rtl of problem6 is
    signal Cgate : STD_LOGIC (7 downto 0); --what is difference if use vector
begin
    --process() --Since unclocked can do without process
    --Evaluate
    Cgate <= A * B( + "00000010"); --add 2 in 8 bit notation
    --write the value to memory
    C <= Cgate;
    --end process;
end rtl;
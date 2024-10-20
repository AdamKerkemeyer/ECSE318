--VHDL
--Evaluate C = A*(B+2)
--A,B,C stored in  memory locations 0, 1, and 2 respectively
library IEEE; --Not sure if this is needed

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
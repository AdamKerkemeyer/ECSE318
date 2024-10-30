library ieee; use ieee.std_logic_1164.all;
entity FA is
    port( 
        i_a, i_b, i_cin : in std_logic;
        o_s, o_cout : out std_logic);
end FA;

architecture spec of FA is
    begin
    process (i_a, i_b, i_cin) is
    begin
        o_s <= i_a xor i_b xor i_cin;
        o_cout <= (i_a and i_b) or (i_a and i_cin) or (i_b and i_cin);
    end process;
end spec;
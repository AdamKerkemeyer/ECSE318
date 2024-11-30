library ieee; use ieee.std_logic_1164.all;

entity testFA is
end testFA;

architecture test of testFA is
    signal A, B, CIN, S, COUT : std_logic;
    
    component FA is
        port( 
        i_a, i_b, i_cin : in std_logic;
        o_s, o_cout : out std_logic
    );
    end component;

begin
    uut: FA
        port map(
            i_a => A,
            i_b => B,
            i_cin => CIN,
            o_s => S,
            o_cout => COUT
        );

    stim : process is
    begin
        A <= '0'; B <= '0'; CIN <= '0';
        wait for 10 ns;
        A <= '0'; B <= '0'; CIN <= '1';
        wait for 10 ns;
        A <= '0'; B <= '1'; CIN <= '1';
        wait for 10 ns;
        A <= '1'; B <= '1'; CIN <= '1';
        wait for 10 ns;
        report "all tests finished";
    end process stim;
end architecture test;
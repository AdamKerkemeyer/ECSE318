library ieee; use ieee.std_logic_1164.all;

entity testCAS is
end testCAS;

architecture test of testCAS is
    signal M, D, C, iQ, oQ, S: std_logic;
    
    component CAS is
        port (
        i_m, i_d, i_c, i_q: in std_logic;
        o_q, o_s : out std_logic
    );
    end component;

begin
    uut: CAS port map(M,D,C,iQ,oQ,S);

    stim : process is
    begin
        M <= '0'; D <= '0'; C <= '0'; iQ <= '0';
        wait for 10ns;
        M <= '1'; D <= '0'; C <= '0'; iQ <= '0';
        wait for 10ns;
        M <= '0'; D <= '0'; C <= '1'; iQ <= '0';
        wait for 10ns;
        M <= '1'; D <= '0'; C <= '1'; iQ <= '0';
        wait for 10ns;
        M <= '0'; D <= '1'; C <= '0'; iQ <= '0';
        wait for 10ns;
        M <= '0'; D <= '1'; C <= '0'; iQ <= '1';
        wait for 10ns;
        report "all tests finished";
    end process stim;
end architecture test;
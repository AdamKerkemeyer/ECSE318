library ieee; use ieee.std_logic_1164.all;

entity TestDivider is
end TestDivider;

architecture test of TestDivider is
    signal M, D, Q, R : std_logic_vector(3 downto 0);
    
    component Divider is
        port (
        i_M, i_D : in std_logic_vector (3 downto 0);
        o_Q, o_R : out std_logic_vector (3 downto 0)
    );
    end component;

begin
    uut: Divider
        port map(
            i_M => M,
            i_D => D,
            o_Q => Q,
            o_R => R
        );

    stim : process is
    begin
        D <= "0111"; M <= "0010";
        wait for 10ns;
        D <= "0110"; M <= "0010";
        wait for 10ns;
        D <= "1001"; M <= "0100";
        wait for 10ns;
        M <= "1011"; D <= "0100";
        wait for 10ns;
        M <= "1111"; D <= "0100";
        wait for 10ns;
        M <= "1010"; D <= "0100";
        wait for 10ns;
        M <= "1010"; D <= "0110";
        wait for 10ns;
        M <= "0000"; D <= "0000";
        wait for 10ns;
        M <= "0000"; D <= "0001";
        wait for 10ns;
        M <= "0001"; D <= "0000";
        wait for 10ns;
        M <= "0001"; D <= "0001";
        wait for 10ns;
        M <= "0010"; D <= "0001";
        wait for 10ns;
        M <= "0010"; D <= "0010";
        wait for 10ns;
        M <= "0101"; D <= "1100";
        wait for 10ns;
        report "all tests finished";
    end process stim;
end architecture test;
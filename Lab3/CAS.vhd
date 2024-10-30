library ieee; use ieee.std_logic_1164.all;

--see "CAS key.png" in the folder for what these variables all mean
entity CAS is
    port (
        i_m, i_d, i_c, i_q: in std_logic;
        o_q, o_s : out std_logic
    );
end CAS;

architecture spec of CAS is

    signal w : std_logic;

    component FA is
        port( 
        i_a, i_b, i_cin : in std_logic;
        o_s, o_cout : out std_logic
    );
    end component;

begin
        w <= i_m xor i_c;

        u1 : FA
            port map(
                i_a => w,
                i_b => i_d,
                i_cin => i_q,
                o_s => o_s,
                o_cout => o_q
            );
end spec;
    
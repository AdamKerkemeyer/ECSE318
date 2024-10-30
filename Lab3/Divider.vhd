library ieee; use ieee.std_logic_1164.all;

--D/M=Q w/ remainder R
entity Divider is
    port (
        i_M, i_D : in std_logic_vector (3 downto 0);
        o_Q, o_R : out std_logic_vector (3 downto 0)
    );
end Divider;

architecture spec of Divider is
    type std_logic_double_vector is array (4 downto 0) of std_logic_vector(4 downto 0);
    -- qout passes the carry out variables between CAS's
    --runtotal holds the D variable between CAS's
    signal qout, runtotal : std_logic_double_vector;
    --Rcout Holds the outputs of the cout of the full adders in the remainder recovery
    signal Rcout : std_logic_vector (4 downto 0);
    --Rand Holds the outputs of the and in the remainder recovery
    signal Rand : std_logic_vector (3 downto 0);

    component CAS is
        port (
        i_m, i_d, i_c, i_q: in std_logic;
        o_q, o_s : out std_logic
    );
    end component;

    component FA is
        port( 
        i_a, i_b, i_cin : in std_logic;
        o_s, o_cout : out std_logic
    );
    end component;
begin
    --initial value setup
    runtotal(4)(4 downto 1) <= "0000";--Fill intial parts of run total with 0s
    Rcout(0) <= '0';--//Initalize LSB of Rcout
    qout(4)(4) <= '1';--//Set up the intial carry bit

    --single cycle var assignments
    gen_single : for k in 3 downto 0 generate
        runtotal(k+1)(0) <= i_D(k); --dripfeed D into runtotal
        qout(k)(0) <= qout(k+1)(4); --loop the q bits back down to the next layer
        o_Q(k) <= qout(k)(4); --get the Q out of the qouts
        Rand(k) <= runtotal(0)(4) and i_M(k); --setup the Rand
        
        FAu0 : FA
            port map(
                    i_a => runtotal(0)(k+1),
                    i_b => Rand(k),
                    i_cin => Rcout(k),
                    o_s => o_R(k),
                    o_cout => Rcout(k+1)
                );
    end generate gen_single;

    --two cycle car assignments
    gen_double_row : for i in 3 downto 0 generate
        gen_double_collumn : for j in 3 downto 0 generate
            CASu0 : CAS
                port map(
                    i_m => i_M(j),
                    i_d => runtotal(i+1)(j),
                    i_c => qout(i+1)(4),
                    i_q => qout(i)(j),
                    o_q => qout(i)(j+1),
                    o_s => runtotal(i)(j+1)
                );
        end generate gen_double_collumn;
    end generate gen_double_row;
end spec;

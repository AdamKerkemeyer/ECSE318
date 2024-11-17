--Problem3TB
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_Problem3 is
end tb_Problem3;

architecture behavior of tb_Problem3 is
    component Problem3
    port(
         clk : in STD_LOGIC;
         Sa : in STD_LOGIC;
         Sb : in STD_LOGIC;
         Ga : out STD_LOGIC;
         Ya : out STD_LOGIC;
         Ra : out STD_LOGIC;
         Gb : out STD_LOGIC;
         Yb : out STD_LOGIC;
         Rb : out STD_LOGIC);
    end component;

    signal clk : STD_LOGIC := '0';
    signal Sa : STD_LOGIC := '0';
    signal Sb : STD_LOGIC := '0';

    signal Ga : STD_LOGIC;
    signal Ya : STD_LOGIC;
    signal Ra : STD_LOGIC;
    signal Gb : STD_LOGIC;
    signal Yb : STD_LOGIC;
    signal Rb : STD_LOGIC;

    signal prev_Ga : STD_LOGIC := '0';
    signal prev_Ya : STD_LOGIC := '0';
    signal prev_Ra : STD_LOGIC := '0';
    signal prev_Gb : STD_LOGIC := '0';
    signal prev_Yb : STD_LOGIC := '0';
    signal prev_Rb : STD_LOGIC := '0';

    constant clk_period : time := 10000 ms; --10 Seconds per state

begin
    uut: Problem3 Port map (
          clk => clk,
          Sa => Sa,
          Sb => Sb,
          Ga => Ga,
          Ya => Ya,
          Ra => Ra,
          Gb => Gb,
          Yb => Yb,
          Rb => Rb);

    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin		
        wait for 10000 ms;	

        Sa <= '1';
        wait for 60000 ms; --Wait till S5
        Sb <= '1';
        Sa <= '0';
        wait for 60000 ms; --Wait till S11
        --Should loop to S11 once, then go to next state
        Sb <= '0';
        wait for 20000 ms;
        wait;
        --This completes one entire loop of the light states and satisfies the two repetition requirements
    end process;

    report_process: process(clk)
    begin
        if rising_edge(clk) then
            if (Ra /= prev_Ra) then
                report "Ra: " & std_logic'image(Ra) severity note;
            end if;
            if (Rb /= prev_Rb) then
                report "Rb: " & std_logic'image(Rb) severity note;
            end if;
            if (Ya /= prev_Ya) then
                report "Ya: " & std_logic'image(Ya) severity note;
            end if;
            if (Yb /= prev_Yb) then
                report "Yb: " & std_logic'image(Yb) severity note;
            end if;
            if (Ga /= prev_Ga) then
                report "Ga: " & std_logic'image(Ga) severity note;
            end if;
            if (Gb /= prev_Gb) then
                report "Gb: " & std_logic'image(Gb) severity note;
            end if;

            prev_Ra <= Ra;
            prev_Rb <= Rb;
            prev_Ya <= Ya;
            prev_Yb <= Yb;
            prev_Ga <= Ga;
            prev_Gb <= Gb;
        end if;
    end process;
end behavior;

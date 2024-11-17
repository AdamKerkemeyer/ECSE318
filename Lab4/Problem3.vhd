--Traffic Light Controller
library IEEE;
use IEEE.STD_LOGIC_1164.ALL; --so we can have std_logic variables for the lights
use IEEE.STD_LOGIC_ARITH.ALL; --So we can do arithmetic operations
--might be better to import numberic_std than std_logic_arith but I don't really understand the difference
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Problem3 is
    port(
        clk : in STD_LOGIC; --Clock period should be 10 seconds because state change can occur every 10 seconds
        Sa : in STD_LOGIC; --If Sa = 1 then a veichle is approaching on A street
        Sb : in STD_LOGIC; --If Sb = 1 then a veichle is approaching on B street
        Ga : out STD_LOGIC; 
        Ya : out STD_LOGIC; 
        Ra : out STD_LOGIC; --one output for each color because they each control a different light
        Gb : out STD_LOGIC;
        Yb : out STD_LOGIC;
        Rb : out STD_LOGIC;)
end Problem3; 

architecture rtl of Problem3 is
    --It is useful to use a specific StateType because we need to go through time steps
    --So we either use the defined cases or we create a counter that updates ever clock cycle,
    --But we already have states defined so lets just use that.
    type StateType is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12); --we make our own type  called StateType
    signal LightSetting : StateType; --LightSetting is an enumeration of the StateType type we just made
    begin
        process(clk) begin --Only run every time clock is positive edge
            if rising_edge(clk) then
                case LightSetting is
                    --Apply case states here,
                    --Initial state: If there is no Sb then light for A is green. 
                    when S0 =>
                        Ra <= '0'; --Zero out old state (S12)
                        Yb <= '0'; 
                        Ga <= '1'; --Set new state (S0)
                        Rb <= '1'; 
                        --Don't need to set all outputs because we almost always know the state we are coming from.
                        LightSetting <= S1;
                    when S1 => --Now we do nothing other than wait until S5, this serves ass a 50 sec timer.
                        LightSetting <= S2; 
                    when S2 =>
                        LightSetting <= S3;
                    when S3 =>
                        LightSetting <= S4;
                    when S4 =>
                        LightSetting <= S5;
                    when S5 =>
                        if(Sb = '1') then
                            LightSetting <= S6;
                        else
                            LightSetting <= S5; 
                        end if;
                    when S6 =>
                        --There was a car detected at Sb
                        Ga <= '0'; --Only thing that changes is green A goes to yellow A
                        Ya <= '1'; 
                        LightSetting <= S7;
                    when S7 =>
                        Ya <= '0'; --Set A to red
                        Ra <= '1';
                        Rb <= '0'; --Set B to green
                        Gb <= '1';
                        LightSetting <= S8;
                    when S8 => --Now wait for 50 seconds (shorter than the Sa cycle)
                        LightSetting <= S9;
                    when S9 =>
                        LightSetting <= S10;
                    when S10 =>
                        LightSetting <= S11;
                    when S11 =>
                        if ()
                        LightSetting <= S0;
                    when others =>
                        LightSetting <= S0; --Restart the loop
                end case;
            end if;
        end process;
end rtl;
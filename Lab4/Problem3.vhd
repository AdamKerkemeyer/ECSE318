--Traffic Light Controller
library IEEE;
use IEEE.STD_LOGIC_1164.ALL; --so we can have std_logic variables for the lights

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
        Rb : out STD_LOGIC);
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
                -- Apply case states here,
                -- Initial state: If there is no Sb then light for A is green. 
                when S0 =>
                    Ra <= '0'; -- Zero out old state (S12)
                    Yb <= '0'; 
                    Ga <= '1'; -- Set new state (S0)
                    Rb <= '1'; 
                    Ya <= '0'; -- Define all states because we must initialize all outputs in first state
                    Gb <= '0';
                    report "Current state: S0" severity note;
                    LightSetting <= S1;
                when S1 => -- Now we do nothing other than wait until S5, this serves as a 50 sec timer.
                    report "Current state: S1" severity note;
                    LightSetting <= S2; 
                when S2 =>
                    report "Current state: S2" severity note;
                    LightSetting <= S3;
                when S3 =>
                    report "Current state: S3" severity note;
                    LightSetting <= S4;
                when S4 =>
                    report "Current state: S4" severity note;
                    LightSetting <= S5;
                when S5 =>
                    report "Current state: S5" severity note;
                    if(Sb = '1') then
                        LightSetting <= S6;
                    else
                        LightSetting <= S5; 
                    end if;
                when S6 =>
                    -- There was a car detected at Sb
                    Ga <= '0'; -- Only thing that changes is green A goes to yellow A
                    Ya <= '1'; 
                    report "Current state: S6" severity note;
                    LightSetting <= S7;
                when S7 =>
                    Ya <= '0'; -- Set A to red
                    Ra <= '1';
                    Rb <= '0'; -- Set B to green
                    Gb <= '1';
                    report "Current state: S7" severity note;
                    LightSetting <= S8;
                when S8 => -- Now wait for 50 seconds (shorter than the Sa cycle)
                    report "Current state: S8" severity note;
                    LightSetting <= S9;
                when S9 =>
                    report "Current state: S9" severity note;
                    LightSetting <= S10;
                when S10 =>
                    report "Current state: S10" severity note;
                    LightSetting <= S11;
                when S11 =>
                    report "Current state: S11" severity note;
                    if ((Sa = '0') and (Sb = '1')) then
                        LightSetting <= S11; -- B car approaching, wait 10 more seconds
                    elsif ((Sa = '1') or (Sb = '0')) then
                        LightSetting <= S12;
                    end if; -- These two if statements present a complete K-map
                when S12 =>
                    Gb <= '0'; -- Set B to yellow
                    Yb <= '1';
                    report "Current state: S12" severity note;
                    LightSetting <= S0;
                when others =>
                    report "Current state: others" severity note;
                    LightSetting <= S0;
                end case;
            end if;
        end process;
end rtl;
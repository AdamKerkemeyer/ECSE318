library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.STD_LOGIC_ARITH.all;

entity Problem1 is
    generic(DataWidth : integer := 2); --generic for MUX
    port(
        x, y : in STD_LOGIC_VECTOR(7 downto 0);
        cin : in STD_LOGIC;
        cout : out STD_LOGIC;
        correctSum : out STD_LOGIC_VECTOR(7 downto 0));
end entity; --Does it matter if I say this or end Problem1

architecture rtl of Problem1 is
    function n_bit_mux(
        in0_data : std_logic_vector;
        in0_carry : std_logic;
        in1_data : std_logic_vector;
        in1_carry : std_logic;
        sel : std_logic) return std_logic_vector is
            variable out_data : std_logic_vector(in0_data'range);
            variable out_carry : std_logic;
            variable result : std_logic_vector(in0_data'length downto 0); --1 longer than out_data
    begin
        if sel = '1' then
            out_data <= in1_data;
            out_carry <= in1_carry;
        else
            out_data <= in0_data;
            out_carry <= in0_data;
        end if;
        result := out_carry & out_data;
        return result;
    end function;

    function fullAdder(a, b, cin : in std_logic) return std_logic_vector is
        variable sum, cout : std_logic; --going to combine them together for the output
    begin --Will run in 0 time because it is a function but this is ok because 
        sum <= a xor b xor cin;
        cout <= (a and b) or (a and cin) or (b and cin);
        return (cout & sum);
    end function
    --Signal declaration
    signal carry1, carry0 : std_logic_vector(8 downto 0); --first round of carrys
    signal sum1, sum0 : std_logic_vector(7 downto 0); --first round of sums
    signal muxCarry1, muxCarry0 : std_logic_vector(8 downto 0); --first round of mux selection
    signal muxSum1, muxSum0 : std_logic_vector(7 downto 0); --first round of mux selection
    signal muxCarrySecond1, muxCarrySecond0 : std_logic_vector(8 downto 0);--second round of mux selection
    signal muxSumSecond1, muxSumSecond0 : std_logic_vector(7 downto 0);--second round of mux selection
    signal correctCarry : std_logic_vector(8 downto 0);--store the known correctCarry here, correlates with correctSum

begin
    --it makes the most sense to me to write the full adder and n_bit_mux as functions to me
    --because I can avoid using processes then which seem to be larger while accomplishing the same thing
    --not sure I understand the difference well enough however

    --x0y0 special case
    (corectSum(0), correctCarry(1)) <= full_adder(y(0), x(0), cin); --left item is assigned LSB function output
    --if above does not work I will use two lines:
    --correctSum(0) <= full_adder(y(0), x(0), cin)(0);
    --correctCarry(1) <= full_adder(y(0), x(0), cin)(1);
    generate first row of full adders
    generate_adders : for i in 1 to 7 generate
        (sum0(i), carry0(i+1)) <= full_adder(y(i), x(i), '0');
        (sum1(i), carry1(i+1)) <= full_adder(y(i), x(i), '1');
    end generate;
    --x1y1 special case --in0 data should always come before in1 data
    (correctSum(1), correctCarry(2)) <= n_bit_mux(sum0(1), carry0(2), sum1(1), carry1(2), correctCarry(1));

    --First round of intermediate muxes:
    generate_muxes: for j in 3 to 7 generate
        if j mod 2 = 1 then --because I don't know how to increment the for loop by 2
            (muxSum0(j), muxCarry0(j+1)) <= n_bit_mux(sum0(j), carry0(j+1), sum1(j), carry1(j+1), carry0(j));
            (muxSum1(j), muxCarry1(j+1)) <= n_bit_mux(sum0(j), carry0(j+1), sum1(j), carry1(j+1), carry1(j));
        end if;
    end generate;

    --Sum[3:2] multiplexer special case
    (correctSum(3 downto 2), correctCarry(4)) <= n_bit_mux(muxSum0(3) & sum0(2), carry0(4), (muxSum1(3) & sum1(2)), carry1(4), correctCarry(2));
    --correctSum(3 downto 2) <= n_bit_mux(muxSum0(3 downto 3) & sum0(2 downto 2), carry0(4), muxSum1(3 downto 3) & sum1(2 downto 2), carry1(4), correctCarry(2))(1 downto 0);
    --correctCarry(4) <= n_bit_mux(muxSum0(3 downto 3) & sum0(2 downto 2), carry0(4), muxSum1(3 downto 3) & sum1(2 downto 2), carry1(4), correctCarry(2))(2);
    --last 3 muxes:
    (muxSumSecond0(7 downto 6), muxCarrySecond0) <= n_bit_mux(muxSum0(7 downto 6), muxCarry1(8), muxSum1(7 downto 6), muxCarry0(8), muxCarry0(6));
    (muxSumSecond1(7 downto 6), muxCarrySecond1) <= n_bit_mux(muxSum0(7 downto 6), muxCarry1(8), muxSum1(7 downto 6), muxCarry0(8), muxCarry1(6));

    -- Final mux
    (correctSum(7 downto 4), cout) <= n_bit_mux(muxSumSecond0(7 downto 6) & muxSum0(5 downto 5) & sum0(4 downto 4), 
                    muxCarrySecond1, muxSumSecond1(7 downto 6) & muxSum1(5 downto 5) & sum1(4 downto 4), muxCarrySecond0, correctCarry(4));

end architecture;

--Generic Multiplexer
entity Mux is
generic(DataWidth : integer); --Minus 1 as it is inclusive of MSB and LSB
port(
    --Inputs
    signal Sig1 : in unsigned(DataWidth-1 downto 0);
    signal Sig2 : in unsigned(DataWidth-1 downto 0);
    signal Sig3 : in unsigned(DataWidth-1 downto 0);
    signal Sig4 : in unsigned(DataWidth-1 downto 0);

    signal Sel : in unsigned(1 downto 0);
    --Outputs
    signal Output : out unsigned(DataWidth-1 downto 0));
end entity

architecture rtl of Mux is
begin --register transfer level
    --MUS using case statement
    process(Sel, Sig1, Sig2, Sig3, Sig4) is
    begin
        case Sel is
            when "00" => 
                Output <= Sig1;
            when "01" => 
                Output <= Sig2;
            when "10" => 
                Output <= Sig3;
            when "11" => 
                Output <= Sig4;
            when others => -- 'U' 'X' 
                Output1 <= (others => 'X');
        end case;
    end process;
end architecture rtl;

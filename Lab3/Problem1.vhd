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
            out_data := in1_data; --if you use <= it is a compilation error
            out_carry := in1_carry;
        else
            out_data := in0_data;
            out_carry := in0_carry;
        end if;
        result := out_carry & out_data;
        return result;
    end function;

    function fullAdder(a, b, cin : in std_logic) return std_logic_vector is
        variable sum, cout : std_logic; --going to combine them together for the output
    begin --Will run in 0 time because it is a function but this is ok because 
        sum := a xor b xor cin;
        cout := (a and b) or (a and cin) or (b and cin);
        return (cout & sum);
    end function;
    --Signal declaration
    signal carry1, carry0 : std_logic_vector(8 downto 0); --first round of carrys
    signal sum1, sum0 : std_logic_vector(7 downto 0); --first round of sums
    signal muxCarry1, muxCarry0 : std_logic_vector(8 downto 0); --first round of mux selection
    signal muxSum1, muxSum0 : std_logic_vector(7 downto 0); --first round of mux selection
    signal muxCarrySecond1, muxCarrySecond0 : std_logic;--second round of mux selection
    signal muxSumSecond1, muxSumSecond0 : std_logic_vector(7 downto 0);--second round of mux selection
    signal correctCarry : std_logic_vector(8 downto 0);--store the known correctCarry here, correlates with correctSum

    signal fullAdderResult0, fullAdderResult1 : std_logic_vector(1 downto 0); --For holding intermediate full adder
    signal mux_result : std_logic_vector(1 downto 0);  --For holding 2 bit n_bit_mux return value
    signal mux_result2 : std_logic_vector(2 downto 0); --For holding 3 bit n_bit_mux return values
    signal mux_result3 : std_logic_vector(4 downto 0); --For holding 5 bit n_bit_mux return values
    --I think another way to do this would be to run the function call 2x and just assign 1 bit at a time to the output
    --Technically this might be less computationally intensive at the cost of being less space efficient
begin
    --it makes the most sense to me to write the full adder and n_bit_mux as functions to me
    --because I can avoid using processes then which seem to be larger while accomplishing the same thing
    --not sure I understand the difference well enough however

    --x0y0 special case
    (correctSum(0), correctCarry(1)) <= fullAdder(y(0), x(0), cin); --left item is assigned LSB function output
    --if above does not work I will use two lines:
    --correctSum(0) <= full_adder(y(0), x(0), cin)(0);
    --correctCarry(1) <= full_adder(y(0), x(0), cin)(1);
    --generate first row of fullAdders
    generate_adders : for i in 1 to 7 generate
        --(sum0(i), carry0(i+1)) <= fullAdder(y(i), x(i), '0'); --Why does this not work?
        --(sum1(i), carry1(i+1)) <= fullAdder(y(i), x(i), '1');
	fullAdderResult0 <= fullAdder(y(i), x(i), '0');
        fullAdderResult1 <= fullAdder(y(i), x(i), '1');
        sum0(i) <= fullAdderResult0(0);
        carry0(i+1) <= fullAdderResult0(1);
        sum1(i) <= fullAdderResult1(0);
        carry1(i+1) <= fullAdderResult1(1);
    end generate;
    --x1y1 special case --in0 data should always come before in1 data
    --n_bit_mux expecta std_logic_vector as input, and if I just say sum0(1) this will input an std_logic which it cannot use
    --because VHDL is stringly typed, but if I say 1 downto 1 it will maintain its status as a std_logic_vector and VHDL happy
    -- Assign the output of n_bit_mux to the temporary signal to prevent slice compilation issues
    mux_result <= n_bit_mux(sum0(1 downto 1), carry0(2), sum1(1 downto 1), carry1(2), correctCarry(1));
    -- Assign slices of mux_result to `correctSum` and `correctCarry`
    correctSum(1) <= mux_result(0);
    correctCarry(2) <= mux_result(1);

    --First round of intermediate muxes:
    generate_muxes: for j in 3 to 7 generate
	--Not allowed to place if statement in the generate block because it is in a concurrent statement.
	--Can use an if generate without the for loop to get around this, so only one generate per outer generate loop
        odd_index: if j mod 2 = 1 generate --because I don't know how to increment the for loop by 2
        mux_result <= n_bit_mux(sum0(j downto j), carry0(j+1), sum1(j downto j), carry1(j+1), carry0(j));
        -- Distribute mux_result slices to muxSum0 and muxCarry0
        muxSum0(j) <= mux_result(0);
        muxCarry0(j+1) <= mux_result(1);
        -- Repeat for muxSum1 and muxCarry1
        mux_result <= n_bit_mux(sum0(j downto j), carry0(j+1), sum1(j downto j), carry1(j+1), carry1(j));
        muxSum1(j) <= mux_result2(0);
        muxCarry1(j+1) <= mux_result2(1);
        end generate;
    end generate;

    --Sum[3:2] multiplexer special case, maintain all std_logic_vectors as vectors by using downto
     mux_result2 <= n_bit_mux(muxSum0(3 downto 3) & sum0(2 downto 2), carry0(4), (muxSum1(3 downto 3) & sum1(2 downto 2)), carry1(4), correctCarry(2));
    correctSum(3 downto 2) <= mux_result2(1 downto 0);
    correctCarry(4) <= mux_result2(2);
    --correctSum(3 downto 2) <= n_bit_mux(muxSum0(3 downto 3) & sum0(2 downto 2), carry0(4), muxSum1(3 downto 3) & sum1(2 downto 2), carry1(4), correctCarry(2))(1 downto 0);
    --correctCarry(4) <= n_bit_mux(muxSum0(3 downto 3) & sum0(2 downto 2), carry0(4), muxSum1(3 downto 3) & sum1(2 downto 2), carry1(4), correctCarry(2))(2);
    --last 3 muxes:
    mux_result2 <= n_bit_mux(muxSum0(7 downto 6), muxCarry1(8), muxSum1(7 downto 6), muxCarry0(8), muxCarry0(6));
    muxSumSecond0(7 downto 6) <= mux_result2(1 downto 0);
    muxCarrySecond0 <= mux_result2(2);

    mux_result2 <= n_bit_mux(muxSum0(7 downto 6), muxCarry1(8), muxSum1(7 downto 6), muxCarry0(8), muxCarry1(6));
    muxSumSecond1(7 downto 6) <= mux_result2(1 downto 0);
    muxCarrySecond1 <= mux_result2(2);
    -- Final mux
    mux_result3 <= n_bit_mux((muxSumSecond0(7 downto 6) & muxSum0(5 downto 5) & sum0(4 downto 4)), 
                    muxCarrySecond1, (muxSumSecond1(7 downto 6) & muxSum1(5 downto 5) & sum1(4 downto 4)), muxCarrySecond0, correctCarry(4));
    correctSum(7 downto 4) <= mux_result3(4 downto 1);
    cout <= mux_result3(0);
end architecture;
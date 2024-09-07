
module conditional_sum_adder(x, y, cin, cout, correctSum);
    input [7:0] x, y;
    input cin;
    output cout;
    output [7:0] correctSum;

    wire [8:0] carry1, carry0; //first round of carrys
    wire [7:0] sum0, sum1; // first round of sums
    wire [8:0] muxCarry1, muxCarry0; //first round of mux selections
    wire [7:0] muxSum0, muxSum1; //first round of mux selections
    wire [8:0] correctCarry; //where the correct carrys are stored and pulled from

    wire [1:0] x1y1; //used as wires for x1 and y1 to first mux

    //x0y0 special case
    full_adder faInitial (y[0], x[0], cin, correctSum[0], correctCarry[1]);

    // First row of full adders
    genvar i;
    generate
        //Assign to intermediate sum and carry values as correct is unkown
        for (i = 1; i < 8; i = i + 1) begin : adders
            full_adder fa0 (y[i], x[i], 0, sum0[i], carry0[i+1]);
            full_adder fa1 (y[i], x[i], 1, sum1[i], carry1[i+1]);
        end
    endgenerate

    //x1y1 special case
    mux2x2 muxInitial ({sum1[1], carry1[1]}, {sum0[1], carry0[1]}, correctCarry[1], {correctSum[1], correctCarry[2]});
    
    // First row of multiplexers
    genvar j; //unsure if I can reuse i;
    generate
        //Assign to intermediate sum and carry values as correct is unkown
        for (j = 2; j < 8; j = j + 2) begin : muxes //increase by 2
            mux2x2 mux0 ({sum1[j], carry1[j+1]}, {sum0[j], carry0[j+1]}, carry0[j+1], {muxSum0[j], muxCarry0[j+2]});
            mux2x2 mux1 ({sum1[j], carry1[j+1]}, {sum0[j], carry0[j+1]}, carry1[j+1], {muxSum1[j], muxCarry1[j+2]});
        end
    endgenerate

    //x3y3 x2y2 mux using c2
    mux2x3 secondRowMux ({muxSum1[3], muxSum1[2], muxCarry1[3]}, 
        {muxSum0[3], muxSum0[2], muxCarry0[3]}, correctCarry[2], {correctSum[3], correctSum[2], correctCarry[3]});

//unsure how to wire up last 3 muxes, almost done
    //x7y7 x6y6 x5y5x4y4 using muxCarry0[6] and muxCarry1[6]
    //not doing generate b/c only 1 sequence
    mux2x3 mux2x30 ({muxSum1[3], muxSum1[2], muxCarry1[3]}, 
        {muxSum0[3], muxSum0[2], muxCarry0[3]}, correctCarry[2], {correctSum[3], correctSum[2], correctCarry[3]});
    mux2x3 mux2x31


endmodule

module full_adder(a, b, cin, sum, cout);
    input a, b, cin;
    output sum, cout;

    wire sum_intermediate;
    wire carry_intermediate1, carry_intermediate2;

    //Sum
    xor (sum_intermediate, a, b);
    xor (sum, sum_intermediate, cin);

    //Carry-out
    and (carry_intermediate1, a, b);
    and (carry_intermediate2, sum_intermediate, cin);
    or (cout, carry_intermediate1, carry_intermediate2);
endmodule

//really all we need is the assign statement. Could do this without official MUX. 
module mux2x2(a, b, sel, out);
    input [1:0] a, b;
    input sel;
    output [1:0] out;
    //If sel is 0, output is b, if sel is 1, output is a
    assign out = sel ? a : b;
endmodule

module mux2x3(a, b, sel, out);
    input [2:0] a, b;
    input sel;
    output [2:0] out;
    //If sel is 0, output is b, if sel is 1, output is a
    assign out = sel ? a : b;
endmodule

module ThisIsNotRight (x, y, cin, sum, cout);
    input [7:0] x;
    input [7:0] y;
    input cin;
    output [7:0] sum;
    output cout;

    wire [7:0] sum0, sum1;
    wire cout0, cout1;

    assign {cout0, sum0} = x + y + 0;
    assign {cout1, sum1} = x + y + 1;

    assign sum = cin ? sum1 : sum0;
    assign cout = cin ? cout1 : cout0;
endmodule
